# Examples

Each folder is a root module you can copy. Run one with:

```shell
export PLOTWORK_API_KEY="pw_..."
cd <group>/<example>
terraform init
terraform apply
```

| Group | For |
|---|---|
| `getting-started/` | Drawing infrastructure code into an SVG file |
| `publishing/` | Publishing to Plotwork: stable links, live values, organisation libraries |
| `storage/` | Writing the SVG to your own cloud storage |

A pre-release of the provider (`0.2.0-beta.1`) talks to Plotwork's preview API by default. To try one, pin it exactly in `versions.tf`: a range such as `~> 0.1` never selects a pre-release.
