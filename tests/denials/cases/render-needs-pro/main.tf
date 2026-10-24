data "plotwork_render" "flow" {
  source = "flow \"Free\"\n\nnode a service \"A\"\n"
}

output "svg_bytes" {
  description = "Never reached on the Free plan."
  value       = length(data.plotwork_render.flow.svg)
}
