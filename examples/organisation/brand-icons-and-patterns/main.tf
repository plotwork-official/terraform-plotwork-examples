locals {
  design_dir = "${path.module}/../../../fixtures/organisation-design"

  pattern_files = {
    for f in fileset("${local.design_dir}/patterns", "*.pattern.json") :
    trimsuffix(f, ".pattern.json") => jsondecode(file("${local.design_dir}/patterns/${f}"))
  }
}

# The colours the organisation's diagrams are painted in. Left out,
# secondary and accent are made from primary.
resource "plotwork_organization_brand" "this" {
  organization = var.organization
  primary      = var.primary_colour
  secondary    = var.secondary_colour
}

# One icon per SVG in the folder, named after the file. Diagrams draw one
# with icon=org:<name>.
resource "plotwork_organization_icon" "this" {
  for_each = fileset("${local.design_dir}/icons", "*.svg")

  organization = var.organization
  name         = "${var.name_prefix}${trimsuffix(each.value, ".svg")}"
  svg          = file("${local.design_dir}/icons/${each.value}")
  aliases      = lookup(var.icon_aliases, trimsuffix(each.value, ".svg"), null)
}

# One approved pattern per pattern file. Agents in the organisation are
# offered these first. Without a prefix, content = file("x.pattern.json")
# does the same: the provider compares the file as JSON.
resource "plotwork_pattern" "this" {
  for_each = local.pattern_files

  organization = var.organization
  content      = jsonencode(merge(each.value, { name = "${var.name_prefix}${each.value.name}" }))
}
