# AGENTS.md — Guidance for AI coding agents

This file defines the rules and conventions AI coding agents (and human
contributors) must follow when developing Terraform modules in this
repository. Read it fully before writing any code.

## Repository conventions

- Branch from `master`; never commit directly to `master`.
- Use Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `ci:`,
  `chore:`.
- Pull requests must pass all CI checks (`terraform-ci.yml`) before merge.
- Never commit secrets, credentials, `.tfvars`, `backend.*.hcl`, plan files,
  or provider lock directories. The `.gitignore` already covers these.

## Terraform module standards

Every module under `modules/` MUST follow the standardized layout:

```text
modules/<name>/
├── README.md       # terraform-docs generated (keep in sync: `make docs`)
├── main.tf         # resources & data sources only
├── outputs.tf      # all outputs have descriptions
├── variables.tf    # all inputs have descriptions, types, sensible defaults
└── versions.tf     # terraform >= 1.3 + required_providers with constraints
```

Rules:

1. **No `provider` blocks in modules** — declare only `required_providers`
   in `versions.tf`. Providers are configured by the caller (`examples/`).
2. **No `backend` blocks in modules** — state configuration is the caller's
   responsibility. Examples may use partial backend configuration
   (`backend "s3" {}`) initialized with `-backend-config=...`.
3. **Pin versions with ranges** (e.g. `>= 4.67, < 6.0`), not exact pins.
4. **Every variable and output has a `description`.** Use `validation`
   blocks for constrained inputs (names, ports, allowed values).
5. **Prefer `optional()` attributes** in `object` variables (requires
   Terraform `>= 1.3`, which `versions.tf` enforces).
6. **Never use hardcoded resource names** — derive everything from `var.name`
   or explicit variables.
7. **Use `dynamic` blocks** for repeatable configuration (e.g. CORS rules)
   instead of duplicating resources.
8. **New features ship with an example** under `examples/` plus updated
   module README docs.
9. **Follow the CORS scope of this project**: modules must default to
   restrictive settings (origin allowlists, `https_only`, versioning) and
   expose `"*"`-style defaults only where the calling example explicitly
   opts in.

## Quality gates (must all pass)

```sh
make fmt-check   # terraform fmt -check -recursive -diff
make validate    # terraform init -backend=false && terraform validate
make lint        # tflint
make security    # trivy (tfsec) config scan
make docs        # terraform-docs; README diff must be clean
```

If a tool is unavailable locally, rely on the GitHub Actions CI workflow
`terraform-ci.yml` as the source of truth and iterate until it is green.

## CI/CD behavior you must preserve

- `terraform-ci.yml` auto-discovers every directory containing `*.tf` under
  `modules/` and `examples/` via a matrix — new modules are picked up
  automatically; never hardcode module names in the matrix.
- `terraform-plan.yml` comments plans on PRs; `terraform-apply.yml` applies
  on `master`; both are safely skipped when cloud credentials are absent.
- `terraform-drift-check.yml` runs weekly; it depends on
  `scripts/send_drift_email.py` and `scripts/log_to_cloudwatch.py`.
- Module releases use tags of the form `modules/<name>/v<semver>`
  (see `release.yml`).

## Acceptance checklist for new modules

- [ ] Standard file set present and formatted (`terraform fmt`)
- [ ] `versions.tf` with provider constraints
- [ ] Every input/output documented and validated where applicable
- [ ] `README.md` regenerated (`make docs`) and diff clean
- [ ] Example root module under `examples/<module>/` with
      `terraform.tfvars.example` and backend config example
- [ ] CI matrix picks up the module and passes
