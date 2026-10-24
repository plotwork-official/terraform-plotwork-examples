#!/usr/bin/env python3
"""An in-memory stand-in for the Plotwork API, for running the smoke test with no account.

It answers the routes the Terraform provider calls, with the same shapes and status codes
as the real API, and stores diagrams by content the way the real one does. It also keeps
organisations' brands, custom icons and approved patterns, with the real API's checks in
a simple form: a colour must be #rgb or #rrggbb, an icon an SVG of at most 32 KB with no
script, and a pattern needs a title, a summary, templates, and a slot for every {{marker}}. It draws
nothing: every import is the same small flow and every SVG is a placeholder. Use it to
check the examples and the smoke script; use preview or production to check Plotwork.

Usage: fake_api.py <port> <api-key> [<free-plan-key>]
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
COLOUR_PATTERN = re.compile(r"^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$")
SLOT_MARKER = re.compile(r"\{\{([a-z0-9-]+)\}\}")
DERIVED = {"secondary": "#7c3aed", "accent": "#0ea5a5"}
MAX_ICON_BYTES = 32 * 1024


class Store:
    """Diagrams and stable links, shared by every request thread."""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.diagrams: dict[str, dict] = {}  # id -> {library, source, scheme, name, folder}
        self.aliases: dict[str, str] = {}  # alias -> diagram id
        self.brands: dict[str, dict] = {}  # org -> {primary, secondary, accent}, chosen colours only
        self.icons: dict[str, dict[str, dict]] = {}  # org -> name -> icon
        self.patterns: dict[str, dict[str, dict]] = {}  # org -> name -> {name, fields, updatedAt}
        self.clock = 1_760_000_000_000

    def tick(self) -> int:
        """A later updatedAt than any before. The caller holds the lock."""
        self.clock += 1000
        return self.clock

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
        match = re.fullmatch(r"/orgs/([^/]+)/patterns", path)
        if match:
            return self.create_pattern(match.group(1), body)
        match = re.fullmatch(r"/orgs/([^/]+)/diagrams", path)
        if match:
            for field in ("alias", "organization", "personal"):
                if field in body:
                    return self.error(400, "validation.failed", f"{field} is not allowed here")
            return self.publish(match.group(1), body)
        self.error(404, "route.not_found", "No such route")

    def do_PUT(self) -> None:  # noqa: N802
        if not self.authorised():
            return
        body = self.read_json()
        path = self.path.split("?")[0]
        if m := re.fullmatch(r"/orgs/([^/]+)/brand", path):
            return self.save_brand(m.group(1), body)
        if m := re.fullmatch(r"/orgs/([^/]+)/icons/([^/]+)", path):
            return self.save_icon(m.group(1), m.group(2), body)
        if m := re.fullmatch(r"/orgs/([^/]+)/patterns/([^/]+)", path):
            return self.replace_pattern(m.group(1), m.group(2), body)
        self.error(404, "route.not_found", "No such route")

    def do_DELETE(self) -> None:  # noqa: N802
        if not self.authorised():
            return
        path = self.path.split("?")[0]
        if m := re.fullmatch(r"/orgs/([^/]+)/brand", path):
            with STORE.lock:
                STORE.brands.pop(m.group(1), None)
            return self.no_content()
        if m := re.fullmatch(r"/orgs/([^/]+)/icons/([^/]+)", path):
            with STORE.lock:
                STORE.icons.get(m.group(1), {}).pop(m.group(2), None)
            return self.no_content()
        if m := re.fullmatch(r"/orgs/([^/]+)/patterns/([^/]+)", path):
            with STORE.lock:
                if STORE.patterns.get(m.group(1), {}).pop(m.group(2), None) is None:
                    return self.error(404, "pattern.not_found", "No such pattern")
            return self.no_content()
        personal = re.fullmatch(r"/user/diagrams/([^/]+)", path)
        org = re.fullmatch(r"/orgs/([^/]+)/diagrams/([^/]+)", path)
        if personal:
            return self.delete("personal", personal.group(1))
        if org:
            return self.delete(org.group(1), org.group(2))
        self.error(404, "route.not_found", "No such route")

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?")[0]
        if m := re.fullmatch(r"/orgs/([^/]+)/brand", path):
            return self.authorised() and self.get_brand(m.group(1))
        if m := re.fullmatch(r"/orgs/([^/]+)/icons", path):
            return self.authorised() and self.list_icons(m.group(1))
        if m := re.fullmatch(r"/orgs/([^/]+)/patterns/([^/]+)", path):
            return self.authorised() and self.get_pattern(m.group(1), m.group(2))
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

    # An organisation's design ---------------------------------------------

    def brand_answer(self, chosen: dict) -> tuple[dict, list[str]]:
        colours = {"primary": chosen["primary"], **DERIVED}
        roles = ["primary"]
        for role in ("secondary", "accent"):
            if chosen.get(role):
                colours[role] = chosen[role]
                roles.append(role)
        return colours, roles

    def get_brand(self, org: str) -> None:
        with STORE.lock:
            chosen = STORE.brands.get(org)
        if chosen is None:
            return self.send_json(200, {"brand": None, "chosen": [], "active": False, "canEdit": True, "plan": "enterprise"})
        colours, roles = self.brand_answer(chosen)
        self.send_json(200, {"brand": colours, "chosen": roles, "active": True, "canEdit": True, "plan": "enterprise"})

    def save_brand(self, org: str, body: dict) -> None:
        issues, chosen = [], {}
        if not body.get("primary"):
            issues.append({"role": "primary", "severity": "error", "code": "missing-primary", "message": "A brand needs a primary color."})
        for role in ("primary", "secondary", "accent"):
            value = body.get(role)
            if value is None:
                continue
            if not isinstance(value, str) or not COLOUR_PATTERN.match(value):
                issues.append({"role": role, "severity": "error", "code": "not-a-color", "message": f"{value} is not a color."})
                continue
            value = value.lower()
            chosen[role] = value if len(value) == 7 else "#" + "".join(c * 2 for c in value[1:])
        if issues:
            return self.send_json(422, {"error": True, "errorCode": "brand.invalid", "message": "The brand colors are not valid.", "details": issues})
        with STORE.lock:
            STORE.brands[org] = chosen
        colours, roles = self.brand_answer(chosen)
        self.send_json(200, {"brand": colours, "chosen": roles, "check": {"issues": [], "swatches": None}})

    @staticmethod
    def icon_answer(icon: dict) -> dict:
        return {
            "name": icon["name"], "ref": f"org:{icon['name']}", "aliases": icon["aliases"], "mediaType": "image/svg+xml",
            "image": "data:image/svg+xml;base64,", "width": 24, "height": 24, "bytes": len(icon["svg"].encode()), "updatedAt": icon["updatedAt"],
        }

    def list_icons(self, org: str) -> None:
        with STORE.lock:
            icons = [self.icon_answer(i) for _, i in sorted(STORE.icons.get(org, {}).items())]
        self.send_json(200, {"icons": icons, "active": True, "canEdit": True, "plan": "enterprise", "limit": 100})

    def save_icon(self, org: str, name: str, body: dict) -> None:
        issues = []
        if not ALIAS_PATTERN.match(name) or len(name) > 48:
            issues.append({"code": "bad-name", "message": f"{name} is not an icon name.", "hint": "Use lowercase words joined by hyphens."})
        svg = body.get("svg")
        if svg is not None:
            if "<svg" not in svg.lower() or len(svg.encode()) > MAX_ICON_BYTES:
                issues.append({"code": "not-svg", "message": "The file is not an SVG of at most 32 KB.", "hint": "Export it as SVG."})
            elif "<script" in svg.lower():
                issues.append({"code": "unsafe", "message": "The SVG has a script.", "hint": "Export it again without scripts."})
        aliases = list(dict.fromkeys(" ".join(a.split()) for a in body.get("aliases") or []))
        if len(aliases) > 10:
            issues.append({"code": "too-many-aliases", "message": "An icon has at most 10 aliases."})
        with STORE.lock:
            existing = STORE.icons.get(org, {}).get(name)
            if svg is None and existing is None:
                issues.append({"code": "empty", "message": f"There is no icon named {name} yet, so it needs a file.", "hint": "Choose an SVG or PNG file."})
            if issues:
                return self.send_json(422, {"error": True, "errorCode": "icon.invalid", "message": "The icon cannot be saved.", "details": issues})
            icon = dict(existing or {"name": name, "svg": ""})
            if svg is not None:
                icon["svg"] = svg
            icon["aliases"], icon["updatedAt"] = aliases, STORE.tick()
            STORE.icons.setdefault(org, {})[name] = icon
            answer = self.icon_answer(icon)
        removed = ["metadata"] if svg is not None and "<metadata" in svg else []
        self.send_json(200, {"icon": answer, "removed": removed})

    @staticmethod
    def pattern_problems(fields: dict) -> list[dict]:
        problems = []
        for field in ("title", "summary"):
            if not isinstance(fields.get(field), str) or not fields[field].strip():
                problems.append({"field": field, "message": f"A pattern needs a {field}."})
        templates = fields.get("templates")
        if not isinstance(templates, dict) or not templates:
            problems.append({"field": "templates", "message": "A pattern needs at least one template."})
            templates = {}
        slots = {slot.get("id") for slot in fields.get("slots") or [] if isinstance(slot, dict)}
        for flavour, source in templates.items():
            for marker in sorted(set(SLOT_MARKER.findall(source or ""))):
                if marker not in slots:
                    problems.append({"field": f"templates.{flavour}", "message": f"{{{{{marker}}}}} has no slot."})
        return problems

    @staticmethod
    def pattern_answer(pattern: dict) -> dict:
        fields = pattern["fields"]
        templates = fields.get("templates") or {}
        return {
            "id": f"org:{pattern['name']}", "name": pattern["name"], "title": fields.get("title", ""), "summary": fields.get("summary", ""),
            "whenToUse": fields.get("whenToUse", ""), "kind": "flow", "tags": fields.get("tags") or [],
            "flavours": [f for f in ("neutral", "aws", "azure", "gcp") if f in templates], "slotCount": len(fields.get("slots") or []),
            "createdAt": pattern["createdAt"], "updatedAt": pattern["updatedAt"], "updatedBy": None, "pictures": None,
            "templates": templates, "slots": fields.get("slots") or [],
            "notes": {"keep": "", "rename": "", "split": "", **(fields.get("notes") or {})},
        }

    def get_pattern(self, org: str, name: str) -> None:
        with STORE.lock:
            pattern = STORE.patterns.get(org, {}).get(name)
            if pattern is None:
                return self.error(404, "pattern.not_found", "No such pattern")
            answer = self.pattern_answer(pattern)
        self.send_json(200, answer)

    def create_pattern(self, org: str, body: dict) -> None:
        name = body.pop("name", None)
        body.pop("$schema", None)
        problems = self.pattern_problems(body)
        if not isinstance(name, str) or not ALIAS_PATTERN.match(name) or len(name) > 50:
            problems.insert(0, {"field": "slug", "message": "Use lowercase letters, digits and single hyphens, up to 50 characters."})
        if problems:
            return self.pattern_invalid(problems)
        with STORE.lock:
            held = STORE.patterns.setdefault(org, {})
            if name in held:
                return self.error(409, "orgs.pattern_exists", f"The organisation already has a pattern named org:{name}.")
            if len(held) >= 50:
                return self.error(403, "orgs.pattern_limit_reached", "An organisation keeps at most 50 patterns.")
            now = STORE.tick()
            held[name] = {"name": name, "fields": body, "createdAt": now, "updatedAt": now}
            answer = self.pattern_answer(held[name])
        self.send_json(201, answer)

    def replace_pattern(self, org: str, name: str, body: dict) -> None:
        if "name" in body:
            return self.error(400, "validation.failed", "name is not allowed here")
        body.pop("$schema", None)
        problems = self.pattern_problems(body)
        if problems:
            return self.pattern_invalid(problems)
        with STORE.lock:
            pattern = STORE.patterns.get(org, {}).get(name)
            if pattern is None:
                return self.error(404, "pattern.not_found", "No such pattern")
            pattern["fields"], pattern["updatedAt"] = body, STORE.tick()
            answer = self.pattern_answer(pattern)
        self.send_json(200, answer)

    def pattern_invalid(self, problems: list[dict]) -> None:
        count = len(problems)
        self.send_json(422, {
            "error": True, "errorCode": "orgs.pattern_invalid",
            "message": f"The pattern has {count} problem{'' if count == 1 else 's'} to fix before it can be saved.",
            "details": {"problems": problems},
        })

    # Helpers --------------------------------------------------------------

    def no_content(self) -> None:
        self.send_response(204)
        self.end_headers()

    def authorised(self) -> bool:
        """The key is the paid one, or the Free one, whose calls a paid plan would allow are refused as the real API refuses them."""
        key = self.headers.get("X-API-Key")
        if key == self.server.api_key:  # type: ignore[attr-defined]
            return True
        if key is not None and key == self.server.free_key:  # type: ignore[attr-defined]
            return not self.refused_on_free()
        self.error(401, "auth.invalid_credentials", "That API key is not valid")
        return False

    # What the Free plan is refused, by method and path, with the real API's code for each.
    FREE_REFUSALS = (
        ("POST", r"/v1/import", "plan.rest_not_included"),
        ("POST", r"/v1/diagrams/render", "plan.rest_not_included"),
        ("PUT", r"/orgs/[^/]+/brand", "plan.brand_not_included"),
        ("PUT", r"/orgs/[^/]+/icons/[^/]+", "plan.icons_not_included"),
        ("POST", r"/orgs/[^/]+/patterns", "plan.governance_not_included"),
        ("PUT", r"/orgs/[^/]+/patterns/[^/]+", "plan.governance_not_included"),
    )

    def refused_on_free(self) -> bool:
        path = self.path.split("?")[0]
        for method, pattern, code in self.FREE_REFUSALS:
            if self.command == method and re.fullmatch(pattern, path):
                self.error(403, code, "The Free plan does not include this")
                return True
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
    if len(sys.argv) not in (3, 4):
        sys.exit("usage: fake_api.py <port> <api-key> [<free-plan-key>]")
    server = ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), Handler)
    server.api_key = sys.argv[2]  # type: ignore[attr-defined]
    server.free_key = sys.argv[3] if len(sys.argv) == 4 else None  # type: ignore[attr-defined]
    print(f"fake-api: listening on http://127.0.0.1:{server.server_address[1]}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
