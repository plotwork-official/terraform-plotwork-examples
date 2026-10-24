output "icon_refs" {
  description = "What a diagram writes to draw each icon this example uploaded."
  value = concat(
    plotwork_organization_icon.from_s3[*].ref,
    plotwork_organization_icon.from_azure[*].ref,
    plotwork_organization_icon.from_cdn[*].ref,
  )
}
