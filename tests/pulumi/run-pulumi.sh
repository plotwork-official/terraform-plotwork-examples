#!/usr/bin/env bash
# Runs the Pulumi example against a Plotwork API with a local state backend:
# install (which generates the bridged SDK), type check, up, preview again
# (expecting no changes), change a value and up (expecting the same stable
# link), then destroy.
#
#   tests/pulumi/run-pulumi.sh fake      # tests/fake-api, no key needed
#   tests/pulumi/run-pulumi.sh preview   # https://api-preview.plotwork.dev, needs PLOTWORK_API_KEY
#
# Needs pulumi (3.147.0 or later), node and npm on PATH. The provider comes
# from the registry at the version Pulumi.yaml pins, never from source.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVIRONMENT="${1:-fake}"
EXAMPLE="$ROOT/examples/pulumi/typescript-stack-diagram"

# shellcheck source=tests/lib/run-setup.sh
source "$ROOT/tests/lib/run-setup.sh"

WORK="$(mktemp -d)"
cleanup() {
  (cd "$EXAMPLE" && pulumi destroy --yes --non-interactive --stack smoke >/dev/null 2>&1) || true
  stop_api
  rm -rf "$WORK"
}
trap cleanup EXIT

use_api "$ENVIRONMENT" "$WORK"
export PULUMI_BACKEND_URL="file://$WORK/state"
export PULUMI_CONFIG_PASSPHRASE="smoke"
export PULUMI_SKIP_UPDATE_CHECK=1
mkdir -p "$WORK/state"
cd "$EXAMPLE"

echo "== pulumi install"
pulumi install
echo "== typecheck"
npm run --silent typecheck

pulumi stack init smoke --non-interactive
pulumi config set environment smoke
echo "== up"
pulumi up --yes --non-interactive
first="$(pulumi stack output link)"
[[ "$first" == */l/network-smoke.svg ]] || { echo "unexpected link: $first" >&2; exit 1; }

echo "== preview, expecting no changes"
pulumi preview --expect-no-changes --non-interactive

echo "== a changed value publishes again behind the same link"
pulumi config set replicas 4
pulumi up --yes --non-interactive
[[ "$(pulumi stack output link)" == "$first" ]] || { echo "the stable link changed" >&2; exit 1; }
curl -fsS -o /dev/null "$first"

echo "== destroy"
pulumi destroy --yes --non-interactive
pulumi stack rm smoke --yes --non-interactive
echo "ok"
