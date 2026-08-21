plugin "aws" {
  enabled = true
  version = "0.48.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "azurerm" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# No cloud credentials are available during linting; rely on static checks only.
config {
  disabled_by_default = false
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}
