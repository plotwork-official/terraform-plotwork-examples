output "diagram_id" {
  description = "The diagram's id in Plotwork. It changes when a value in the picture does."
  value       = plotwork_diagram.network.id
}

output "url" {
  description = "The public address of this version of the picture."
  value       = plotwork_diagram.network.url
}

output "stable_url" {
  description = "The address that always shows the latest version."
  value       = plotwork_diagram.network.stable_url
}
