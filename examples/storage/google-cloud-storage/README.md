# Write the SVG to Google Cloud Storage

Draws the Terraform in [`fixtures/aws-three-tier`](../../../fixtures/aws-three-tier) and writes the SVG to your own storage. Plotwork stores nothing: the picture lives where your team already keeps its architecture documents, under your access controls.

| | |
|---|---|
| Blocks | `plotwork_import`, `plotwork_render`, and the storage resource |
| Plan | Pro |
| Cloud account | A Google Cloud project and an existing bucket |

```shell
export PLOTWORK_API_KEY="pw_..."
cp terraform.tfvars.example terraform.tfvars   # then edit it
terraform init
terraform apply
```

The smoke test does not run this example, because it needs a cloud account; CI checks it with `terraform validate`.
