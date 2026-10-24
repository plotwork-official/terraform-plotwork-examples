# Publish to an organisation's library

Draws the Terraform in [`fixtures/azure-web-app`](../../../fixtures/azure-web-app) and publishes it to your organisation's private library, classified `internal`. Every policy the organisation set applies: folder rules, classification, approval, daily limits.

| | |
|---|---|
| Blocks | `plotwork_import`, `plotwork_diagram` with `organization` |
| Plan | Pro or Enterprise organisation (the import needs Pro) |
| Key | An organisation key from Keys and CI, or a member's key that may publish |

```shell
export PLOTWORK_API_KEY="pw_..."   # the organisation key
terraform init
terraform apply -var organization=acme
terraform output view_url
```

If the organisation holds new diagrams for approval, apply warns and the diagram waits for an approver.
