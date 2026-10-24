# TFLint for every example. The terraform ruleset's "recommended" preset
# checks naming, unused declarations, typed variables and pinned versions.
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}
