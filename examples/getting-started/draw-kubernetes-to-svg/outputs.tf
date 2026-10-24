output "diagram_path" {
  description = "Where the SVG was written."
  value       = local_file.diagram.filename
}

output "svg_bytes" {
  description = "The size of the SVG."
  value       = length(data.plotwork_render.catalogue.svg)
}

output "kind" {
  description = "The kind of diagram the manifests became."
  value       = data.plotwork_import.catalogue.kind
}

output "warnings" {
  description = "What the import left out or changed."
  value       = data.plotwork_import.catalogue.warnings
}
