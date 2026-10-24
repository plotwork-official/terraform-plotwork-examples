# shellcheck shell=bash
# Assertions for the smoke test. Sourced by run-smoke.sh; each prints what it
# checked and returns non-zero on failure, so `set -e` stops the example.
# Expects TF to name the Terraform or OpenTofu binary.

# output NAME: one Terraform output of the current example, as raw text.
output() {
  "$TF" output -raw "$1"
}

pass() { printf '    ok   %s\n' "$*"; }
fail() {
  printf '    FAIL %s\n' "$*" >&2
  return 1
}

# assert_not_empty NAME VALUE
assert_not_empty() {
  if [[ -n "$2" && "$2" != "null" ]]; then pass "$1 is set"; else fail "$1 is empty"; fi
}

# assert_equal NAME EXPECTED ACTUAL
assert_equal() {
  if [[ "$2" == "$3" ]]; then pass "$1 is $2"; else fail "$1 is '$3', expected '$2'"; fi
}

# assert_not_equal NAME A B
assert_not_equal() {
  if [[ "$2" != "$3" ]]; then pass "$1 changed"; else fail "$1 did not change ($2)"; fi
}

# assert_svg_file PATH: the file exists and holds an SVG.
assert_svg_file() {
  if [[ -s "$1" ]] && grep -q '<svg' "$1"; then
    pass "$(basename "$1") is an SVG ($(wc -c <"$1") bytes)"
  else
    fail "$1 is missing or not an SVG"
  fi
}

# http_status URL: the status a HEAD request gets, with no credentials.
http_status() {
  curl -s -o /dev/null -I -w '%{http_code}' --max-time 30 "$1"
}

# assert_serves_svg URL: the public link answers 200 with an SVG.
assert_serves_svg() {
  local status type
  status="$(http_status "$1")"
  type="$(curl -s -I --max-time 30 "$1" | tr -d '\r' | awk -F': ' 'tolower($1) == "content-type" { print $2 }')"
  if [[ "$status" == "200" && "$type" == image/svg+xml* ]]; then
    pass "$1 serves an SVG"
  else
    fail "$1 answered $status ($type)"
  fi
}

# assert_gone URL: the public link answers 404 or 410.
assert_gone() {
  local status
  status="$(http_status "$1")"
  if [[ "$status" == "404" || "$status" == "410" ]]; then pass "$1 is gone"; else fail "$1 still answers $status"; fi
}
