#!/usr/bin/env bash
# Runs every case under tests/denials/cases with a Free plan key and checks
# that Plotwork refuses it with the right error, as the provider shows it: the
# REST drawing routes need Pro, the brand and custom icons a plan that has
# them, approved patterns Enterprise, and an unknown key is a 401.
#
#   tests/denials/run-denials.sh preview      # https://api-preview.plotwork.dev
#   tests/denials/run-denials.sh production   # https://api.plotwork.dev
#   tests/denials/run-denials.sh fake         # tests/fake-api, playing a Free account
#   tests/denials/run-denials.sh custom       # PLOTWORK_API_URL as set
#
# Environment:
#   PLOTWORK_API_KEY               a key of an account on the Free plan (not needed for fake)
#   PLOTWORK_ORG                   an organisation that account owns on the Free plan; the
#                                  organisation cases are skipped without it
#   PLOTWORK_PROVIDER_SOURCE_DIR   build the provider from this checkout
#   PLOTWORK_PROVIDER_VERSION      use this exact registry version, such as 0.1.0-beta.2
#   TF_BIN                         terraform (default) or tofu
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVIRONMENT="${1:-preview}"
TF="${TF_BIN:-terraform}"
export TF

# shellcheck source=tests/lib/assert.sh
source "$ROOT/tests/lib/assert.sh"
# shellcheck source=tests/lib/run-setup.sh
source "$ROOT/tests/lib/run-setup.sh"

WORK="$(mktemp -d)"
# shellcheck disable=SC2317,SC2329 # run through trap
cleanup() {
  stop_api
  rm -rf "$WORK"
}
trap cleanup EXIT

FREE_ORG="${PLOTWORK_ORG:-}"
unset PLOTWORK_ORG
export FAKE_PLAN=free
use_api "$ENVIRONMENT" "$WORK"
[[ "$ENVIRONMENT" == "fake" ]] && FREE_ORG="${FREE_ORG:-free-org}"
use_provider "$WORK"

# The cases run from a copy, so no state lands in the checkout.
mkdir -p "$WORK/repo/tests"
cp -R "$ROOT/tests/denials" "$WORK/repo/tests/"
cp -R "$ROOT/fixtures" "$WORK/repo/"

RESULTS=()
FAILED=0

# run_case NAME: applies the case, expecting a failure whose output holds the
# text in its expect file, then destroys whatever an unexpected success made.
run_case() {
  local name="$1" path="$WORK/repo/tests/denials/cases/$1" expected status key="$PLOTWORK_API_KEY"
  local vars=()
  expected="$(<"$path/expect")"
  echo
  echo "== $name (expects $expected)"
  if grep -q 'var.organization' "$path/main.tf"; then
    if [[ -z "$FREE_ORG" ]]; then
      RESULTS+=("| \`$name\` | skipped (PLOTWORK_ORG not set) |")
      return 0
    fi
    vars=(-var "organization=$FREE_ORG")
  fi
  # A key Plotwork has never issued, of the right shape.
  [[ "$name" == "unknown-key-is-refused" ]] && key="pw_$(printf '0%.0s' $(seq 64))"
  pin_provider_version "$path"

  if ! (cd "$path" && "$TF" init -input=false -no-color >"$WORK/init.log" 2>&1); then
    cat "$WORK/init.log" >&2
    RESULTS+=("| \`$name\` | **FAIL** (init) |")
    FAILED=1
    return 0
  fi
  set +e
  (cd "$path" && PLOTWORK_API_KEY="$key" "$TF" apply -auto-approve -input=false -no-color "${vars[@]}" >"$WORK/apply.log" 2>&1)
  status=$?
  set -e
  if [[ $status -ne 0 ]] && grep -qF "$expected" "$WORK/apply.log"; then
    pass "refused with $expected"
    RESULTS+=("| \`$name\` | pass |")
  else
    cat "$WORK/apply.log" >&2
    if [[ $status -eq 0 ]]; then printf '    FAIL the apply succeeded\n' >&2; else printf '    FAIL refused, but without %s\n' "$expected" >&2; fi
    RESULTS+=("| \`$name\` | **FAIL** |")
    FAILED=1
  fi
  (cd "$path" && PLOTWORK_API_KEY="$key" "$TF" destroy -auto-approve -input=false -no-color "${vars[@]}" >/dev/null 2>&1) || true
}

echo "Denials: $ENVIRONMENT ($PLOTWORK_API_URL), provider: $PROVIDER_LABEL, CLI: $("$TF" version | head -1)"
for case_dir in "$WORK"/repo/tests/denials/cases/*/; do
  run_case "$(basename "$case_dir")"
done

summary="$(printf '%s\n' \
  "### Plotwork denials (Free plan): $ENVIRONMENT" \
  "" \
  "API \`$PLOTWORK_API_URL\`, provider $PROVIDER_LABEL, $("$TF" version | head -1)." \
  "" \
  "| Case | Result |" \
  "|---|---|" \
  "${RESULTS[@]}")"
echo
echo "$summary"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then echo "$summary" >>"$GITHUB_STEP_SUMMARY"; fi
exit "$FAILED"
