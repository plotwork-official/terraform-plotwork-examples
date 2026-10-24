locals {
  # Replace with path.module to draw the configuration this sits in.
  fixture_dir = "${path.module}/../../../fixtures/aws-three-tier"
}

data "plotwork_import" "stack" {
  format = "terraform"
  files = {
    for f in fileset(local.fixture_dir, "*.tf") : f => file("${local.fixture_dir}/${f}")
  }
}

data "plotwork_render" "stack" {
  source = data.plotwork_import.stack.source
  scheme = "auto"
}

resource "azurerm_storage_blob" "diagram" {
  name                   = var.object_key
  storage_account_name   = var.storage_account_name
  storage_container_name = var.container_name
  type                   = "Block"
  content_type           = "image/svg+xml"
  source_content         = data.plotwork_render.stack.svg
}
