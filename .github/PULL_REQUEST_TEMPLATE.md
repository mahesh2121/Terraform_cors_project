## Description

<!-- Describe the change and why it is needed. Link related issues. -->

Fixes #<issue>

## Type of change

<!-- Delete options that do not apply. -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New module
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that changes module inputs/outputs)
- [ ] Documentation update
- [ ] CI/CD improvement

## Checklist

- [ ] `terraform fmt -check -recursive -diff` passes
- [ ] `terraform init -backend=false && terraform validate` passes for every changed directory
- [ ] `tflint` passes for every changed directory
- [ ] Module README(s) regenerated with `make docs` (docs diff is clean)
- [ ] Variables and outputs are documented (`description` on every input/output)
- [ ] Example under `examples/` added or updated where applicable
- [ ] No secrets, `.tfvars`, backend config, or state files committed

## How has this been tested?

<!-- e.g. terraform plan output, CI run link, manual steps -->

## Additional context

<!-- Anything else reviewers should know. -->
