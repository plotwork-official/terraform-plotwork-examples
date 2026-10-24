# Plotwork Terraform examples

Working examples for the [Plotwork provider](https://github.com/plotwork-official/terraform-provider-plotwork) for Terraform and OpenTofu, and the smoke test that runs all of them against Plotwork's preview or production API before each release.

Every example runs without a cloud account except those under `storage/`, which write to your own bucket.

## Examples

| Example | Shows | Plan |
|---|---|---|
| [`getting-started/draw-terraform-to-svg`](examples/getting-started/draw-terraform-to-svg) | Draw a Terraform module and write the SVG to a file | Pro |
| [`getting-started/draw-kubernetes-to-svg`](examples/getting-started/draw-kubernetes-to-svg) | Draw Kubernetes manifests the same way | Pro |
| [`publishing/personal-stable-link`](examples/publishing/personal-stable-link) | Publish a `.diagram` file with a link that never changes | Every plan |
| [`publishing/live-values-from-outputs`](examples/publishing/live-values-from-outputs) | Fill a diagram with values only the apply knows | Every plan |
| [`publishing/organisation-library`](examples/publishing/organisation-library) | Publish to an organisation's private library | Pro organisation |
| [`organisation/brand-icons-and-patterns`](examples/organisation/brand-icons-and-patterns) | Keep an organisation's brand, custom icons and approved patterns in code | Enterprise organisation |
| [`storage/aws-s3`](examples/storage/aws-s3) | Write the SVG to S3 | Pro |
| [`storage/azure-blob-storage`](examples/storage/azure-blob-storage) | Write the SVG to Azure Blob Storage | Pro |
| [`storage/google-cloud-storage`](examples/storage/google-cloud-storage) | Write the SVG to Cloud Storage | Pro |
| [`storage/icons-from-buckets-and-cdns`](examples/storage/icons-from-buckets-and-cdns) | Upload organisation icons from S3, Azure Blob Storage or a CDN | Pro organisation |

```shell
export PLOTWORK_API_KEY="pw_..."          # from https://app.plotwork.dev, API keys
cd examples/publishing/personal-stable-link
terraform init && terraform apply
```

## Layout

```text
.
├── examples/                     one root module per example, grouped by use
│   ├── getting-started/
│   ├── publishing/
│   ├── organisation/
│   └── storage/
│       └── <example>/
│           ├── README.md
│           ├── versions.tf       terraform and required_providers
│           ├── providers.tf      provider configuration
│           ├── main.tf           the resources and data sources
│           ├── variables.tf
│           ├── outputs.tf
│           └── terraform.tfvars.example
├── fixtures/                     sample infrastructure the examples draw; read as text, never applied
│   ├── aws-three-tier/
│   ├── azure-web-app/
│   ├── kubernetes-catalogue/
│   └── organisation-design/      an icon and a pattern file for the organisation example
├── tests/
│   ├── smoke/run-smoke.sh        runs every example against an API
│   ├── fake-api/fake_api.py      an in-memory Plotwork API, for runs with no key
│   └── lib/                      assertions, and serving a provider built from source
├── .github/workflows/
│   ├── validate.yml              every pull request: fmt, validate, tflint, shellcheck, fake smoke
│   └── smoke.yml                 preview or production, by hand and daily on preview
├── .tflint.hcl
└── Makefile
```

| Convention | Rule |
|---|---|
| Folders | kebab-case, grouped by what the reader wants to do |
| Files in an example | HashiCorp's standard module structure: `versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `README.md` |
| Terraform names | snake_case; every variable and output has a description (TFLint enforces both) |
| Values | `terraform.tfvars.example` beside each example; real `terraform.tfvars` files are ignored by git |

## The smoke test

For each example it runs `init`, `apply`, checks the outputs and that the published links serve an SVG, runs `plan` again expecting no changes, changes a value and applies (expecting a new diagram behind the same stable link), then runs `destroy`.

```shell
make smoke-fake                                   # no key: the fake API
PLOTWORK_API_KEY=pw_... make smoke-preview        # https://api-preview.plotwork.dev
PLOTWORK_API_KEY=pw_... make smoke-production     # https://api.plotwork.dev
```

| Variable | Effect |
|---|---|
| `PLOTWORK_API_KEY` | The key for that environment |
| `PLOTWORK_ORG` | Also runs `publishing/organisation-library` and `organisation/brand-icons-and-patterns` in that organisation. The second sets and then removes the organisation's brand, so use a test organisation |
| `PLOTWORK_PROVIDER_VERSION` | Use this exact released version, such as `0.1.0-beta.1` |
| `PROVIDER_DIR` (make) or `PLOTWORK_PROVIDER_SOURCE_DIR` | Build the provider from a checkout instead |
| `TF_BIN=tofu` | Run with OpenTofu |

The Free plan's refusals have their own suite: every paid feature must be refused with the code a customer would see.

```shell
make denials-fake
PLOTWORK_API_KEY=pw_free... PLOTWORK_ORG=free-org make denials-preview
```

In GitHub Actions, run **Smoke** with the environment and the version:

```shell
gh workflow run smoke.yml -R plotwork-official/terraform-plotwork-examples \
  -f environment=preview -f provider_version=0.1.0-beta.1
```

The `preview` and `production` environments each hold a secret `PLOTWORK_API_KEY`, and optionally a variable `PLOTWORK_ORG`.

Make those keys from a system identity in the Plotwork admin console (System, then New system identity): a Pro identity, with Daily calls, Hosted diagrams and Stable links bypassed so a run never stops on a limit, then Mint key. For the organisation examples, make it Enterprise and set `PLOTWORK_ORG` to its organisation's slug; its key needs the `design:write` scope for `organisation/brand-icons-and-patterns`. Production allows system identities only when the API var `SYSTEM_IDENTITIES` is `on`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Licence: [MIT](LICENSE).
