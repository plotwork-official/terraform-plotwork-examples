# 1. An SVG in S3. The aws provider fills body only for text content types
# (text/*, application/xml and a few more), not image/svg+xml, so store the
# icon with content_type = "application/xml", or use the pre-signed route
# in 3 below.
data "aws_s3_object" "icon" {
  count = var.s3_bucket == null ? 0 : 1

  bucket = var.s3_bucket
  key    = var.s3_key
}

resource "plotwork_organization_icon" "from_s3" {
  count = var.s3_bucket == null ? 0 : 1

  organization = var.organization
  name         = "ledger"
  svg          = data.aws_s3_object.icon[0].body
}

# 2. An SVG in Azure Blob Storage. azurerm_storage_blob manages a blob but
# does not read its contents, so download it with a read-only SAS address.
# The data source reads it during plan, so a new blob is a planned change.
data "http" "azure_icon" {
  count = var.azure_blob_sas_url == null ? 0 : 1

  url = var.azure_blob_sas_url

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "The blob did not answer 200: check the SAS address and that it has not expired."
    }
  }
}

resource "plotwork_organization_icon" "from_azure" {
  count = var.azure_blob_sas_url == null ? 0 : 1

  organization = var.organization
  name         = "queue"
  svg          = data.http.azure_icon[0].response_body
}

# 3. An SVG on a CDN, or a pre-signed S3 or GCS address. The provider
# downloads it during every plan (https only, 30 s, at most 32 KB) and
# uploads it again when the file there changes. source_url is sensitive,
# because a signed address is a credential.
resource "plotwork_organization_icon" "from_cdn" {
  count = var.cdn_icon_url == null ? 0 : 1

  organization = var.organization
  name         = "gateway"
  source_url   = var.cdn_icon_url
}
