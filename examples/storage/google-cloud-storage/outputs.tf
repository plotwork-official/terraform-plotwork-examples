output "object" {
  description = "Where the SVG was written."
  value       = "gs://${google_storage_bucket_object.diagram.bucket}/${google_storage_bucket_object.diagram.name}"
}
