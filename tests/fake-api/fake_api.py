#!/usr/bin/env python3
"""An in-memory stand-in for the Plotwork API, for running the smoke test with no account.

It answers the routes the Terraform provider calls, with the same shapes and status codes
as the real API, and stores diagrams by content the way the real one does. It draws
nothing: every import is the same small flow and every SVG is a placeholder. Use it to
check the examples and the smoke script; use preview or production to check Plotwork.

Usage: fake_api.py <port> <api-key>
Python 3.10 or later, standard library only.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

IMPORTED_SOURCE = 'flow "Imported"\n\nnode a service "A"\nnode b service "B"\na -> b\n'
ALIAS_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


class Store:
    """Diagrams and stable links, shared by every request thread."""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.diagrams: dict[str, dict] = {}  # id -> {library, source, scheme, name, folder}
        self.aliases: dict[str, str] = {}  # alias -> diagram id

    def put(self, library: str, body: dict) -> tuple[dict, bool]:
        """Store a diagram by its content and library; a second publish renames and moves it."""
        scheme = body.get("scheme") or "light"
        digest = hashlib.sha256(f"{library}\0{scheme}\0{body['source']}".encode()).hexdigest()
        diagram_id = f"{digest[:8]}-{digest[8:12]}-4{digest[13:16]}-8{digest[17:20]}-{digest[20:32]}"
        with self.lock:
            created = diagram_id not in self.diagrams
            diagram = self.diagrams.setdefault(diagram_id, {"id": diagram_id, "library": library, "source": body["source"], "scheme": scheme, "name": None})
            if body.get("name"):
                diagram["name"] = body["name"]
            diagram["folder"] = body.get("folder")
            return dict(diagram), created


STORE = Store()


class Handler(BaseHTTPRequestHandler):
    server_version = "plotwork-fake/1"

    # Routing --------------------------------------------------------------

    def do_POST(self) -> None:  # noqa: N802 (the stdlib names it)
        if not self.authorised():
            return
        body = self.read_json()
        path = self.path.split("?")[0]
        if path == "/v1/import":
            return self.import_source(body)
        if path == "/v1/diagrams/render":
            return self.render(body)
        if path == "/v1/diagrams/publish":
            return self.publish("personal", body)
        match = re.fullmatch(r"/orgs/([^/]+)/diagrams", path)
        if match:
            for field in ("alias", "organization", "personal"):
                if field in body:
                    return self.error(400, "validation.failed", f"{field} is not allowed here")
            return self.publish(match.group(1), body)
        self.error(404, "route.not_found", "No such route")

    def do_DELETE(self) -> None:  # noqa: N802
        if not self.authorised():
            return
        path = self.path.split("?")[0]
        personal = re.fullmatch(r"/user/diagrams/([^/]+)", path)
        org = re.fullmatch(r"/orgs/([^/]+)/diagrams/([^/]+)", path)
        if personal:
            return self.delete("personal", personal.group(1))
        if org:
            return self.delete(org.group(1), org.group(2))
        self.error(404, "route.not_found", "No such route")

    def do_GET(self) -> None:  # noqa: N802
        self.serve_file(with_body=True)

    def do_HEAD(self) -> None:  # noqa: N802
        self.serve_file(with_body=False)

    # Routes ---------------------------------------------------------------

    def import_source(self, body: dict) -> None:
        if not body.get("format") or not (body.get("text") or body.get("files")):
            return self.error(400, "validation.failed", "format and text or files are required")
        self.send_json(200, {
            "ok": True, "kind": "flow", "format": body["format"], "source": IMPORTED_SOURCE,
            "diagnostics": [], "partsTotal": 0, "partsPage": 1, "partsPages": 0, "parts": [],
            "outline": ["A", "A -> B"], "outlineTruncated": False,
            "coverage": {"noun": "resources", "total": 2, "drawn": 2, "summarised": 0, "omitted": 0, "complete": True, "line": "Drawn 2 of 2 resources."},
            "validation": {"valid": True, "errors": [], "warnings": [], "summary": "Imported: 2 nodes, 1 connection.", "size": {"width": 320, "height": 200}},
            "stats": {"items": 2, "links": 1, "groups": 0, "dropped": 0},
            "next": "Draw it.",
        })

    def render(self, body: dict) -> None:
        source = body.get("source") or ""
        if not source.strip():
            return self.error(400, "validation.failed", "source is required")
        scheme = body.get("scheme") or "light"
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="320" height="200" data-scheme="{scheme}"><title>fake</title></svg>'
        self.send_json(200, {"svg": svg, "scheme": scheme, "size": {"width": 320, "height": 200}, "warnings": []})

    def publish(self, library: str, body: dict) -> None:
        if not (body.get("source") or "").strip():
            return self.error(400, "validation.failed", "source is required")
        alias = body.get("alias")
        if alias is not None and not ALIAS_PATTERN.match(alias):
            return self.error(400, "validation.failed", "alias must be lower-case words joined by hyphens")
        diagram, created = STORE.put(library, body)
        answer = {
            "id": diagram["id"], "name": diagram["name"], "folder": diagram["folder"], "scheme": diagram["scheme"],
            "bytes": len(diagram["source"]) + 200, "createdAt": 1_760_000_000_000, "publishedAt": 1_760_000_000_000,
            "expiresAt": None, "locked": False, "created": created,
        }
        if library == "personal":
            answer["url"] = f"{self.base_url()}/d/{diagram['id']}.svg"
            if alias:
                with STORE.lock:
                    STORE.aliases[alias] = diagram["id"]
                answer["stableLink"] = {"id": f"sl-{alias}", "alias": alias, "url": f"{self.base_url()}/l/{alias}.svg"}
        else:
            answer["viewUrl"] = f"{self.base_url()}/orgs/{library}/diagrams/{diagram['id']}"
            answer["pending"] = False
        self.send_json(201 if created else 200, answer)

    def delete(self, library: str, diagram_id: str) -> None:
        with STORE.lock:
            diagram = STORE.diagrams.get(diagram_id)
            if diagram is None or diagram["library"] != library:
                return self.error(404, "hosting.not_found", "No such diagram")
            del STORE.diagrams[diagram_id]
        self.send_response(204)
        self.end_headers()

    def serve_file(self, with_body: bool) -> None:
        """The CDN's /d/<id>.svg and /l/<alias>.svg, and an organisation's /svg route."""
        path = self.path.split("?")[0]
        diagram_id = None
        if m := re.fullmatch(r"/d/([^/]+)\.svg", path):
            diagram_id = m.group(1)
        elif m := re.fullmatch(r"/l/([^/]+)\.svg", path):
            with STORE.lock:
                diagram_id = STORE.aliases.get(m.group(1))
        elif m := re.fullmatch(r"/orgs/([^/]+)/diagrams/([^/]+)/svg", path):
            if not self.authorised():
                return
            diagram_id = m.group(2)
        with STORE.lock:
            found = diagram_id is not None and diagram_id in STORE.diagrams
        if not found:
            return self.error(404, "hosting.not_found", "No such diagram", with_body=with_body)
        payload = b'<svg xmlns="http://www.w3.org/2000/svg"/>'
        self.send_response(200)
        self.send_header("Content-Type", "image/svg+xml")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if with_body:
            self.wfile.write(payload)

    # Helpers --------------------------------------------------------------

    def authorised(self) -> bool:
        if self.headers.get("X-API-Key") == self.server.api_key:  # type: ignore[attr-defined]
            return True
        self.error(401, "auth.invalid_credentials", "That API key is not valid")
        return False

    def base_url(self) -> str:
        return f"http://127.0.0.1:{self.server.server_address[1]}"

    def read_json(self) -> dict:
        length = int(self.headers.get("Content-Length") or 0)
        try:
            return json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            return {}

    def send_json(self, status: int, body: dict) -> None:
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def error(self, status: int, code: str, message: str, with_body: bool = True) -> None:
        if not with_body:
            self.send_response(status)
            self.end_headers()
            return
        self.send_json(status, {"error": True, "errorCode": code, "message": message})

    def log_message(self, fmt: str, *args) -> None:  # noqa: A003
        sys.stderr.write("fake-api: " + (fmt % args) + "\n")


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("usage: fake_api.py <port> <api-key>")
    server = ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), Handler)
    server.api_key = sys.argv[2]  # type: ignore[attr-defined]
    print(f"fake-api: listening on http://127.0.0.1:{server.server_address[1]}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
