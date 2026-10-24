output "diagram_id" {
  description = "The diagram's id in the library."
  value       = plotwork_diagram.booking.id
}

output "view_url" {
  description = "The portal page that shows the diagram to signed-in members."
  value       = plotwork_diagram.booking.view_url
}

output "library" {
  description = "The organisation that holds the diagram."
  value       = plotwork_diagram.booking.library
}

output "coverage" {
  description = "How much of the Terraform the diagram shows."
  value       = data.plotwork_import.booking.coverage
}
