output "blob_url" {
  description = "Where the SVG was written."
  value       = azurerm_storage_blob.diagram.url
}
