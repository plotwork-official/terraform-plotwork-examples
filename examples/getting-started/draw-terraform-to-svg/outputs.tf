output "diagram_path" {
  description = "Where the SVG was written."
  value       = local_file.diagram.filename
}

output "svg_bytes" {
  description = "The size of the SVG."
  value       = length(data.plotwork_render.stack.svg)
}

output "kind" {
  description = "The kind of diagram the Terraform became."
  value       = data.plotwork_import.stack.kind
}

output "coverage" {
  description = "How much of the Terraform the diagram shows."
  value       = data.plotwork_import.stack.coverage
}

output "warnings" {
  description = "What the import left out or changed."
  value       = data.plotwork_import.stack.warnings
}
