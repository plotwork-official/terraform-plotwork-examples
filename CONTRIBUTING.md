# Contributing

## Add an example

1. Make a folder under the group it belongs to, in kebab-case: `examples/<group>/<what-it-does>/`.
2. Give it the standard files: `versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `README.md`, `terraform.tfvars.example`. Pin `plotwork-official/plotwork` to `~> 0.1`.
3. Describe every variable and output. Use snake_case names.
4. If it can run without a cloud account, add it to `tests/smoke/run-smoke.sh` with a check of its outputs.
5. Add a row to the table in `README.md`.

Sample infrastructure an example reads goes in `fixtures/`, as text that is never applied.

## Before a pull request

| Command | Checks |
|---|---|
| `make fmt` | Formats every `.tf` file |
| `make validate PROVIDER_DIR=../terraform-provider-plotwork` | `init` and `validate` in every example, with the provider built from a checkout |
| `make lint` | TFLint, with the rules in `.tflint.hcl` |
| `make smoke-fake PROVIDER_DIR=../terraform-provider-plotwork` | Runs every example against the fake API |

CI runs all of them on every pull request.
