data "plotwork_render" "flow" {
  source = "flow \"Key\"\n\nnode a service \"A\"\n"
}

output "svg_bytes" {
  description = "Never reached with a key Plotwork does not know."
  value       = length(data.plotwork_render.flow.svg)
}
