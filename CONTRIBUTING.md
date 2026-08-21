# Contributing to Terraform CORS Project

Thanks for your interest in contributing! This repository follows a
standardized Terraform module structure and every change is validated by
automated CI/CD before it can be merged.

## Repository layout

```text
.
├── examples/               # Runnable root modules that consume the modules below
│   ├── s3-cors-website/
│   └── azure-webapp-cors/
├── modules/                # Reusable, versioned Terraform modules
│   ├── s3-cors-website/    # AWS S3 static website + CORS
│   └── azure-webapp-cors/  # Azure App Service (Linux web app) + CORS
├── scripts/                # Helper scripts used by CI (drift notifications, etc.)
├── .github/
│   ├── workflows/          # CI/CD pipelines
│   └── ISSUE_TEMPLATE/
└── ...
```

## Getting started

1. Fork and clone the repository.
2. Install the tooling:
   * [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.3`
   * [TFLint](https://github.com/terraform-linters/tflint)
   * [pre-commit](https://pre-commit.com/)
   * [terraform-docs](https://terraform-docs.io/) (for module docs)
3. Install the git hooks: `pre-commit install`

## Development workflow

1. Create a branch from `master`: `git checkout -b feat/my-change`.
2. Make your changes, then run the quality gates locally:

   ```sh
   make fmt        # terraform fmt -recursive
   make validate   # terraform init -backend=false && terraform validate (every dir)
   make lint       # tflint (every dir)
   make docs       # regenerate module READMEs with terraform-docs
   make security   # trivy config scan
   ```

3. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   `feat:`, `fix:`, `docs:`, `refactor:`, `ci:`, `chore:`.
4. Open a pull request against `master`.

## Module development standards

Every module under `modules/` must:

* Have the canonical file set: `versions.tf`, `variables.tf`, `main.tf`,
  `outputs.tf`, `README.md`.
* Pin `required_version` and provider version constraints in `versions.tf`.
* Document every variable and output with a `description`.
* Add sensible defaults and input `validation` blocks where applicable.
* Never declare `provider` blocks — only `required_providers`.
* Keep the module stateless: state backends belong to the `examples/`
  root modules, never to `modules/`.
* Keep the README in sync (`make docs`) — CI checks that docs match the code.
* Add or update an example under `examples/` when adding features.

AI coding agents must additionally follow [`AGENTS.md`](AGENTS.md).

## CI/CD pipeline

| Workflow | Trigger | Purpose |
| -------- | ------- | ------- |
| `terraform-ci.yml` | PR / push | fmt, init, validate, tflint, docs for every module & example |
| `terraform-plan.yml` | PR | Terraform plan for examples, posted as a PR comment |
| `terraform-apply.yml` | push to `master` | Plan + apply the examples (gated by `production` environment) |
| `terraform-drift-check.yml` | weekly + manual | Detect infrastructure drift and notify |
| `release.yml` | tag `modules/<name>/v*` | Validate + package a module into a GitHub Release |

## Releasing a module

```sh
git tag modules/s3-cors-website/v1.0.0
git push origin modules/s3-cors-website/v1.0.0
```

The release workflow validates the module and publishes a zip asset to a
GitHub Release.

## Questions?

Open a [discussion or issue](https://github.com/mahesh2121/Terraform_cors_project/issues).
