# shellcheck shell=bash
# The setup every test runner shares: which API it talks to, which provider
# it installs, and the exact version pin a pre-release needs.
#
#   source tests/lib/run-setup.sh
#   use_api "$ENVIRONMENT" "$WORK"     # sets PLOTWORK_API_URL; starts the fake API for fake
#   use_provider "$WORK"               # sets PROVIDER_LABEL; builds from source when asked
#   pin_provider_version "$DIR"        # writes smoke_override.tf when a version is pinned
#
# Expects ROOT (the repository root) to be set, and sources the provider mirror.

# shellcheck source=tests/lib/provider-mirror.sh
source "$ROOT/tests/lib/provider-mirror.sh"

# The keys the fake API answers: one for a paid plan, one for the Free plan.
FAKE_PAID_KEY="pw_fake_smoke"
FAKE_FREE_KEY="pw_fake_free"
FAKE_PID=""

# use_api ENVIRONMENT WORK_DIR: sets PLOTWORK_API_URL for preview, production
# or custom, or starts the fake API and points at it. With fake, the key is
# the paid one unless FAKE_PLAN is free.
use_api() {
  local environment="$1" work="$2" port
  case "$environment" in
    preview) export PLOTWORK_API_URL="https://api-preview.plotwork.dev" ;;
    production) export PLOTWORK_API_URL="https://api.plotwork.dev" ;;
    custom) : "${PLOTWORK_API_URL:?set PLOTWORK_API_URL for custom}" ;;
    fake)
      port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
      if [[ "${FAKE_PLAN:-paid}" == "free" ]]; then export PLOTWORK_API_KEY="$FAKE_FREE_KEY"; else export PLOTWORK_API_KEY="$FAKE_PAID_KEY"; fi
      python3 "$ROOT/tests/fake-api/fake_api.py" "$port" "$FAKE_PAID_KEY" "$FAKE_FREE_KEY" 2>"$work/fake-api.log" &
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
}

# stop_api: stops the fake API when this run started one.
stop_api() {
  if [[ -n "$FAKE_PID" ]]; then kill "$FAKE_PID" 2>/dev/null || true; fi
}

# use_provider WORK_DIR: builds the provider from PLOTWORK_PROVIDER_SOURCE_DIR
# when it is set, and names what is being tested in PROVIDER_LABEL.
use_provider() {
  local work="$1"
  if [[ -n "${PLOTWORK_PROVIDER_SOURCE_DIR:-}" ]]; then
    echo "Building the provider from $PLOTWORK_PROVIDER_SOURCE_DIR"
    install_provider_mirror "$PLOTWORK_PROVIDER_SOURCE_DIR" "$work/provider"
    PROVIDER_LABEL="source build"
  elif [[ -n "${PLOTWORK_PROVIDER_VERSION:-}" ]]; then
    PROVIDER_LABEL="registry $PLOTWORK_PROVIDER_VERSION"
  else
    PROVIDER_LABEL="registry ~> 0.1"
  fi
  export PROVIDER_LABEL
}

# pin_provider_version DIR: a range never selects a pre-release, so a run of
# PLOTWORK_PROVIDER_VERSION pins that exact version in the module at DIR.
pin_provider_version() {
  [[ -z "${PLOTWORK_PROVIDER_VERSION:-}" ]] && return 0
  cat >"$1/smoke_override.tf" <<EOF
terraform {
  required_providers {
    plotwork = {
      source  = "plotwork-official/plotwork"
      version = "$PLOTWORK_PROVIDER_VERSION"
    }
  }
}
EOF
}
