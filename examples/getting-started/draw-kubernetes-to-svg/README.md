# Draw Kubernetes manifests to an SVG file

Reads [`fixtures/kubernetes-catalogue/catalogue.yaml`](../../../fixtures/kubernetes-catalogue/catalogue.yaml), draws the namespace (Ingress, Deployments, Services, ConfigMaps, Secrets), and writes `out/kubernetes-catalogue.svg`.

| | |
|---|---|
| Blocks | `plotwork_import` (format `kubernetes`), `plotwork_render`, `local_file` |
| Plan | Pro |
| Cluster | None: the manifests are read as text |

```shell
export PLOTWORK_API_KEY="pw_..."
terraform init
terraform apply
```

The same pattern reads Helm output, Kustomize, Docker Compose, Bicep, CloudFormation and the other formats in [importing from code and data](https://docs.plotwork.dev/importing-from-code-and-data).
