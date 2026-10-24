# shellcheck shell=bash
# Serves a provider built from source to Terraform and OpenTofu, through a
# filesystem mirror. Unlike dev_overrides, `init` then works for a provider the
# registry has not published, and lock files are written as for a release.
#
#   source tests/lib/provider-mirror.sh
#   install_provider_mirror ../terraform-provider-plotwork "$RUNNER_TEMP/plotwork"
#
# It exports TF_CLI_CONFIG_FILE. The build is served as version 0.1.0, which
# the examples' "~> 0.1" accepts.

PROVIDER_MIRROR_VERSION="0.1.0"

# install_provider_mirror SOURCE_DIR WORK_DIR
install_provider_mirror() {
  local source_dir="$1" work_dir="$2" platform host dir
  platform="$(go env GOOS)_$(go env GOARCH)"
  mkdir -p "$work_dir"

  for host in registry.terraform.io registry.opentofu.org; do
    dir="$work_dir/mirror/$host/plotwork-official/plotwork/$PROVIDER_MIRROR_VERSION/$platform"
    mkdir -p "$dir"
    (cd "$source_dir" && go build -o "$dir/terraform-provider-plotwork_v$PROVIDER_MIRROR_VERSION" .)
  done

  cat >"$work_dir/cli.tfrc" <<EOF
provider_installation {
  filesystem_mirror {
    path    = "$work_dir/mirror"
    include = ["registry.terraform.io/plotwork-official/plotwork", "registry.opentofu.org/plotwork-official/plotwork"]
  }
  direct {
    exclude = ["registry.terraform.io/plotwork-official/plotwork", "registry.opentofu.org/plotwork-official/plotwork"]
  }
}
EOF
  export TF_CLI_CONFIG_FILE="$work_dir/cli.tfrc"
}
