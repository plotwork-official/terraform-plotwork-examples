# Icons from buckets and CDNs

Uploads organisation icons whose SVG lives outside the module: in S3, in Azure Blob Storage, or behind an https address such as a CDN or a pre-signed URL. Each source is optional: leave its variable unset and that icon is skipped.

| | |
|---|---|
| Blocks | `plotwork_organization_icon`, `aws_s3_object` (data), `http` (data) |
| Plan | Pro organisation |
| Key | The owner's or an admin's key, or an organisation key with the `design:write` scope |

| Source | How | Watch for |
|---|---|---|
| S3 | `svg = data.aws_s3_object.icon.body` | The aws provider fills `body` only for text content types, not `image/svg+xml`. Store the SVG as `application/xml`, or use a pre-signed address with `source_url` |
| Azure Blob Storage | `svg = data.http.icon.response_body`, with a read-only SAS address | `azurerm_storage_blob` does not read a blob's contents. Keep the SAS address in a sensitive variable |
| CDN or pre-signed URL | `source_url = "https://cdn.acme.example/icons/gateway.svg"` | The provider downloads it during every plan: https only, 30 s, at most 32 KB, served as an SVG or untyped. `source_url` is sensitive in plans |

```shell
export PLOTWORK_API_KEY="pw_..."
terraform init
terraform apply -var organization=acme -var s3_bucket=acme-design -var cdn_icon_url=https://cdn.acme.example/icons/gateway.svg
```

Each way, the provider keeps `content_sha256` of the file it sent, so a new file at the source uploads it again on the next apply, and the same file never does.

This example needs your own bucket or address, so the smoke test validates it but does not run it.
