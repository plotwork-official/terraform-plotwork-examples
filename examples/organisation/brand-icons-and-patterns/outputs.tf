output "brand_colours" {
  description = "The three colours Plotwork paints with, the derived ones included."
  value = {
    primary   = plotwork_organization_brand.this.effective_primary
    secondary = plotwork_organization_brand.this.effective_secondary
    accent    = plotwork_organization_brand.this.effective_accent
  }
}

output "icon_refs" {
  description = "What a diagram writes to draw each icon, by file name."
  value       = { for file, icon in plotwork_organization_icon.this : file => icon.ref }
}

output "pattern_ids" {
  description = "What agents pass to draw_from_pattern, by file name."
  value       = { for file, pattern in plotwork_pattern.this : file => pattern.pattern_id }
}

output "first_icon_ref" {
  description = "The first icon's reference, for a quick check."
  value       = values(plotwork_organization_icon.this)[0].ref
}

output "first_pattern_id" {
  description = "The first pattern's id, for a quick check."
  value       = values(plotwork_pattern.this)[0].pattern_id
}
