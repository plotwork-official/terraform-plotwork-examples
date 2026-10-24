output "diagram_id" {
  description = "The diagram's id in Plotwork. It changes when the source does."
  value       = plotwork_diagram.payments.id
}

output "url" {
  description = "The public address of this version of the picture."
  value       = plotwork_diagram.payments.url
}

output "stable_url" {
  description = "The address that always shows the latest version. Embed this one."
  value       = plotwork_diagram.payments.stable_url
}

output "library" {
  description = "personal, or the id of an organisation whose Publishing setting took the diagram."
  value       = plotwork_diagram.payments.library
}
