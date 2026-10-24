# Draw live values from an apply

A hand-written template filled with values only the apply knows: CIDRs, the load balancer's DNS name, the database endpoint, the task count. The diagram is published with a stable link and follows every change.

| | |
|---|---|
| Blocks | `templatefile()`, `plotwork_diagram` with `alias` |
| Plan | Every plan |
| Cloud account | None: `terraform_data` stands in for the real stack |

```shell
export PLOTWORK_API_KEY="pw_..."
terraform init
terraform apply
terraform apply -var replicas=4   # the picture changes, stable_url does not
```

In your own stack, replace `terraform_data.deployment.output.*` with your resources' attributes or a module's outputs, and edit [`templates/network.diagram.tftpl`](templates/network.diagram.tftpl). The [Plotwork language guide](https://docs.plotwork.dev/writing-diagrams) describes the syntax.
