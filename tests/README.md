# Tests

| Path | What it is |
|---|---|
| `denials/run-denials.sh` | Runs each case in `denials/cases` with a Free plan key and checks Plotwork refuses it with the right code: `plan.rest_not_included` for import and render, `plan.brand_not_included`, `plan.icons_not_included`, `plan.governance_not_included` for patterns, and HTTP 401 for a key Plotwork never issued |
| `denials/cases/` | One small module a case, and an `expect` file holding the text the refusal must contain |
| `smoke/run-smoke.sh` | Runs every example against an API (`preview`, `production`, `fake` or `custom`) and checks each step |
| `fake-api/fake_api.py` | An in-memory stand-in for the Plotwork API, standard library only: diagrams, and an organisation's brand, icons and patterns. It checks the examples and the script, not Plotwork |
| `lib/assert.sh` | The assertions the smoke test prints |
| `lib/run-setup.sh` | What both runners share: the API to use (starting the fake one, which plays a paid account or a Free one), the provider to install, and the exact pin a pre-release needs |
| `lib/provider-mirror.sh` | Serves a provider built from source through a filesystem mirror, so `init` works before a release |

What a run checks, for each example:

1. `init` and `apply` succeed.
2. The outputs are set; a written SVG is an SVG; a published link and its stable link answer 200 with `image/svg+xml`.
3. A second `plan` has no changes.
4. For `live-values-from-outputs`: a changed value publishes a new diagram, the stable link stays the same and shows it, and (against the fake API) the replaced diagram is deleted.
5. For `brand-icons-and-patterns` (only with `PLOTWORK_ORG`): the icon and pattern ids carry the run's prefix, the brand's primary is stored lower case with derived colours, and a primary changed to `#F5A` reads back as `#ff55aa`.
6. `destroy` succeeds; against the fake API the link then answers 404. The real CDN may serve a deleted picture from its edge cache for up to an hour, so that check runs on the fake only.

A failed example is destroyed before the next one runs, so nothing is left in Plotwork.
