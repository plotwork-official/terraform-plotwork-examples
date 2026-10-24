# Draw Terraform to an SVG file

Reads the Terraform in [`fixtures/aws-three-tier`](../../../fixtures/aws-three-tier), draws it, and writes `out/aws-three-tier.svg`. Nothing is published or stored by Plotwork.

| | |
|---|---|
| Blocks | `plotwork_import`, `plotwork_render`, `local_file` |
| Plan | Pro (the REST drawing routes) |
| Cloud account | None |

```shell
export PLOTWORK_API_KEY="pw_..."
terraform init
terraform apply
open out/aws-three-tier.svg
```

To draw your own module, point `files` at `path.module`:

```hcl
files = { for f in fileset(path.module, "*.tf") : f => file("${path.module}/${f}") }
```
