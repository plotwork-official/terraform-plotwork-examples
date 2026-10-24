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

resource "google_storage_bucket_object" "diagram" {
  bucket       = var.bucket
  name         = var.object_key
  content      = data.plotwork_render.stack.svg
  content_type = "image/svg+xml"
}
