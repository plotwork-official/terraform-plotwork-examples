# Brand, icons and patterns for an organisation

Keeps an organisation's design in code: its brand colours, a custom icon for every SVG in [`fixtures/organisation-design/icons`](../../../fixtures/organisation-design/icons), and an approved pattern for every file in [`fixtures/organisation-design/patterns`](../../../fixtures/organisation-design/patterns). A change to a file is a change to the organisation on the next apply, after review like the rest of the configuration.

| | |
|---|---|
| Blocks | `plotwork_organization_brand`, `plotwork_organization_icon`, `plotwork_pattern` |
| Plan | Enterprise organisation (brand and icons need Pro, patterns need Enterprise) |
| Key | The owner's or an admin's key, or an organisation key with the `design:write` scope |

```shell
export PLOTWORK_API_KEY="pw_..."   # an organisation key with design:write
terraform init
terraform apply -var organization=acme
terraform output icon_refs          # { "payments-api.svg" = "org:payments-api" }
```

Diagrams then draw the icon with `icon=org:payments-api`, and agents in the organisation find the pattern as `org:payments-service`.

## What the provider compares

| Resource | Compared by | So |
|---|---|---|
| `plotwork_organization_brand` | Lower-case `#rrggbb` | `#2A78D6` and `#2a78d6` are the same colour, and so are `#abc` and `#aabbcc` |
| `plotwork_organization_icon` | `content_sha256` of the file sent | Plotwork rewrites the SVG, but a new file uploads again and the same file never does |
| `plotwork_pattern` | The file as JSON | Spacing and key order are no change; a new `name` replaces the pattern |

An icon or pattern someone changes in the portal shows as a change in the next plan, and the apply puts the file back. Destroying removes the brand, icons and patterns this configuration made.

## Writing a pattern file

Start from one Plotwork gives you: in the Plotwork MCP server, `get_pattern` with `file: true`, then `check_pattern` to check it, or follow [the pattern schema](https://docs.plotwork.dev/schemas/plotwork.pattern.json). Every template must be valid Plotwork source once its `{{slot}}` markers take their defaults; Plotwork checks that before it saves.

## Icons from somewhere else

[`storage/icons-from-buckets-and-cdns`](../../storage/icons-from-buckets-and-cdns) reads the SVG from S3, Azure Blob Storage or a CDN instead of the module's folder.

`name_prefix` puts a prefix on every icon and pattern name; the smoke test uses it to keep its runs apart.
