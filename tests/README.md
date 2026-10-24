# Tests

| Path | What it is |
|---|---|
| `smoke/run-smoke.sh` | Runs every example against an API (`preview`, `production`, `fake` or `custom`) and checks each step |
| `fake-api/fake_api.py` | An in-memory stand-in for the Plotwork API, standard library only: diagrams, and an organisation's brand, icons and patterns. It checks the examples and the script, not Plotwork |
| `lib/assert.sh` | The assertions the smoke test prints |
| `lib/provider-mirror.sh` | Serves a provider built from source through a filesystem mirror, so `init` works before a release |

What a run checks, for each example:

1. `init` and `apply` succeed.
2. The outputs are set; a written SVG is an SVG; a published link and its stable link answer 200 with `image/svg+xml`.
3. A second `plan` has no changes.
4. For `live-values-from-outputs`: a changed value publishes a new diagram, the stable link stays the same and shows it, and (against the fake API) the replaced diagram is deleted.
5. For `brand-icons-and-patterns` (only with `PLOTWORK_ORG`, and a provider of 0.2 or later): the icon and pattern ids carry the run's prefix, the brand's primary is stored lower case with derived colours, and a primary changed to `#F5A` reads back as `#ff55aa`.
6. `destroy` succeeds; against the fake API the link then answers 404. The real CDN may serve a deleted picture from its edge cache for up to an hour, so that check runs on the fake only.

A failed example is destroyed before the next one runs, so nothing is left in Plotwork.
