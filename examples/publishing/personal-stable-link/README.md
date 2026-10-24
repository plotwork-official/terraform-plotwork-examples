# Publish a diagram with a stable link

Publishes [`diagrams/payments.diagram`](diagrams/payments.diagram) to your own Plotwork library. `stable_url` never changes: embed it in a README, a wiki or an ADR, and every apply that changes the file changes the picture behind it.

| | |
|---|---|
| Blocks | `plotwork_diagram` with `alias` |
| Plan | Every plan (Free keeps 3 stable links) |
| Cloud account | None |

```shell
export PLOTWORK_API_KEY="pw_..."
terraform init
terraform apply
terraform output stable_url
```

```markdown
![Payments](https://cdn.plotwork.dev/l/<token>.svg)
```

A change to the file publishes a new diagram and deletes the old one; `stable_url` moves to the new one. `terraform destroy` deletes the diagram.

If an organisation you belong to requires its library for publishing, the diagram goes there instead and `alias` is refused: use [organisation-library](../organisation-library).
