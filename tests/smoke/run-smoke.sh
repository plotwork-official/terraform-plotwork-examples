#!/usr/bin/env bash
# Runs every example against a Plotwork API: init, apply, check the outputs and
# the published links, plan again (expecting no changes), change a value and
# apply (expecting a new diagram behind the same stable link), then destroy.
#
#   tests/smoke/run-smoke.sh preview      # https://api-preview.plotwork.dev
#   tests/smoke/run-smoke.sh production   # https://api.plotwork.dev
#   tests/smoke/run-smoke.sh fake         # tests/fake-api, no key needed
#   tests/smoke/run-smoke.sh custom       # PLOTWORK_API_URL as set
#
# Environment:
#   PLOTWORK_API_KEY               the key (not needed for fake)
#   PLOTWORK_ORG                   also run the organisation example
#   PLOTWORK_PROVIDER_SOURCE_DIR   build the provider from this checkout
#   PLOTWORK_PROVIDER_VERSION      use this exact registry version, such as 0.1.0-beta.1
#   TF_BIN                         terraform (default) or tofu
#
# With neither provider variable set, the registry version the examples
# require (~> 0.1) is used.
# The check_* functions run through "$check" and cleanup through trap, which
# the linter cannot follow.
# (SC2329 in current shellcheck, SC2317 in older releases.)
# shellcheck disable=SC2317,SC2329
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVIRONMENT="${1:-preview}"
TF="${TF_BIN:-terraform}"
export TF

# shellcheck source=tests/lib/assert.sh
source "$ROOT/tests/lib/assert.sh"
# shellcheck source=tests/lib/provider-mirror.sh
source "$ROOT/tests/lib/provider-mirror.sh"

WORK="$(mktemp -d)"
FAKE_PID=""
cleanup() {
  if [[ -n "$FAKE_PID" ]]; then kill "$FAKE_PID" 2>/dev/null || true; fi
  rm -rf "$WORK"
}
trap cleanup EXIT

# The provider reads PLOTWORK_ORG as its default organisation, which would send
# the personal examples to that library. Only the organisation example gets it.
SMOKE_ORG="${PLOTWORK_ORG:-}"
unset PLOTWORK_ORG

# A suffix that keeps this run's stable links apart from any other run's.
RUN_ID="$(printf '%s' "${GITHUB_RUN_ID:-local$(date +%s)}" | tr -cd 'a-z0-9')"

# --- The API --------------------------------------------------------------

case "$ENVIRONMENT" in
  preview) export PLOTWORK_API_URL="https://api-preview.plotwork.dev" ;;
  production) export PLOTWORK_API_URL="https://api.plotwork.dev" ;;
  custom) : "${PLOTWORK_API_URL:?set PLOTWORK_API_URL for custom}" ;;
  fake)
    port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
    export PLOTWORK_API_KEY="pw_fake_smoke"
    python3 "$ROOT/tests/fake-api/fake_api.py" "$port" "$PLOTWORK_API_KEY" 2>"$WORK/fake-api.log" &
    FAKE_PID=$!
    export PLOTWORK_API_URL="http://127.0.0.1:$port"
    for _ in $(seq 50); do curl -s -o /dev/null "$PLOTWORK_API_URL/" && break; sleep 0.1; done
    ;;
  *)
    echo "usage: $0 preview|production|fake|custom" >&2
    exit 2
    ;;
esac
: "${PLOTWORK_API_KEY:?set PLOTWORK_API_KEY}"

# --- The provider ---------------------------------------------------------

if [[ -n "${PLOTWORK_PROVIDER_SOURCE_DIR:-}" ]]; then
  echo "Building the provider from $PLOTWORK_PROVIDER_SOURCE_DIR"
  install_provider_mirror "$PLOTWORK_PROVIDER_SOURCE_DIR" "$WORK/provider"
  PROVIDER_LABEL="source build"
elif [[ -n "${PLOTWORK_PROVIDER_VERSION:-}" ]]; then
  PROVIDER_LABEL="registry $PLOTWORK_PROVIDER_VERSION"
else
  PROVIDER_LABEL="registry ~> 0.1"
fi

# The examples run from a copy, so no state or output lands in the checkout.
mkdir -p "$WORK/repo"
cp -R "$ROOT/examples" "$ROOT/fixtures" "$WORK/repo/"

# --- The checks for each example ------------------------------------------

check_svg_file() {
  assert_not_empty kind "$(output kind)"
  assert_svg_file "$(output diagram_path)"
}

check_personal_link() {
  local url stable
  url="$(output url)"
  stable="$(output stable_url)"
  assert_equal library personal "$(output library)"
  assert_serves_svg "$url"
  assert_serves_svg "$stable"
}

check_live_values() {
  local first_id first_url stable second_id
  first_id="$(output diagram_id)"
  first_url="$(output url)"
  stable="$(output stable_url)"
  assert_serves_svg "$first_url"
  assert_serves_svg "$stable"

  echo "  change replicas and apply again"
  "$TF" apply -auto-approve -input=false -no-color "${VARS[@]}" -var replicas=5 >"$WORK/apply2.log"
  second_id="$(output diagram_id)"
  assert_not_equal diagram_id "$first_id" "$second_id"
  assert_equal stable_url "$stable" "$(output stable_url)"
  assert_serves_svg "$stable"
  # The update deletes the diagram it replaced (see the destroy note below).
  if [[ "$ENVIRONMENT" == "fake" ]]; then assert_gone "$first_url"; fi
  VARS+=(-var replicas=5)
}

check_organisation() {
  assert_not_empty view_url "$(output view_url)"
  assert_not_empty library "$(output library)"
}

# --- Running one example --------------------------------------------------

RESULTS=()
FAILED=0

# run_example DIR CHECK [-var ...]
run_example() {
  local dir="$1" check="$2"
  shift 2
  VARS=("$@")
  local path="$WORK/repo/examples/$dir"
  echo
  echo "== $dir"

  if [[ -n "${PLOTWORK_PROVIDER_VERSION:-}" ]]; then
    # A range never selects a pre-release, so pin the exact version.
    cat >"$path/smoke_override.tf" <<EOF
terraform {
  required_providers {
    plotwork = {
      source  = "plotwork-official/plotwork"
      version = "$PLOTWORK_PROVIDER_VERSION"
    }
  }
}
EOF
  fi

  if (
    set -e
    cd "$path"
    "$TF" init -input=false -no-color >"$WORK/init.log" 2>&1 || { cat "$WORK/init.log" >&2; exit 1; }
    "$TF" apply -auto-approve -input=false -no-color "${VARS[@]}" >"$WORK/apply.log" 2>&1 || { cat "$WORK/apply.log" >&2; exit 1; }
    pass "applied"
    "$check"
    set +e
    "$TF" plan -detailed-exitcode -input=false -no-color "${VARS[@]}" >"$WORK/plan.log" 2>&1
    plan_status=$?
    set -e
    if [[ $plan_status -eq 0 ]]; then
      pass "a second plan has no changes"
    else
      cat "$WORK/plan.log" >&2
      fail "a second plan wants changes (exit $plan_status)"
    fi
    published="$("$TF" output -raw url 2>/dev/null || true)"
    "$TF" destroy -auto-approve -input=false -no-color "${VARS[@]}" >"$WORK/destroy.log" 2>&1 || { cat "$WORK/destroy.log" >&2; exit 1; }
    pass "destroyed"
    # The real CDN may keep serving a deleted picture from its edge cache for
    # up to an hour, so only the fake API is held to an immediate 404.
    if [[ "$ENVIRONMENT" == "fake" && -n "$published" ]]; then assert_gone "$published"; fi
  ); then
    RESULTS+=("| \`$dir\` | pass |")
  else
    RESULTS+=("| \`$dir\` | **FAIL** |")
    FAILED=1
    # Leave nothing behind in Plotwork after a failure.
    (cd "$path" && "$TF" destroy -auto-approve -input=false -no-color "${VARS[@]}" >/dev/null 2>&1) || true
  fi
}

echo "Smoke test: $ENVIRONMENT ($PLOTWORK_API_URL), provider: $PROVIDER_LABEL, CLI: $("$TF" version | head -1)"

run_example getting-started/draw-terraform-to-svg check_svg_file
run_example getting-started/draw-kubernetes-to-svg check_svg_file
run_example publishing/personal-stable-link check_personal_link -var "environment=smoke-$RUN_ID"
run_example publishing/live-values-from-outputs check_live_values -var "environment=smoke-$RUN_ID"
if [[ -n "$SMOKE_ORG" ]]; then
  run_example publishing/organisation-library check_organisation -var "organization=$SMOKE_ORG" -var "folder=Smoke/$RUN_ID"
else
  RESULTS+=("| \`publishing/organisation-library\` | skipped (PLOTWORK_ORG not set) |")
fi

# --- Report ---------------------------------------------------------------

summary="$(printf '%s\n' \
  "### Plotwork smoke test: $ENVIRONMENT" \
  "" \
  "API \`$PLOTWORK_API_URL\`, provider $PROVIDER_LABEL, $("$TF" version | head -1)." \
  "" \
  "| Example | Result |" \
  "|---|---|" \
  "${RESULTS[@]}")"
echo
echo "$summary"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then echo "$summary" >>"$GITHUB_STEP_SUMMARY"; fi
exit "$FAILED"
