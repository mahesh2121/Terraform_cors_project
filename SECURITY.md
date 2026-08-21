# Security Policy

## Supported Versions

Only the latest version of each Terraform module is actively maintained.
Security fixes are released as patch releases of the affected module.

| Module | Supported |
| ------ | --------- |
| `modules/s3-cors-website` | :white_check_mark: |
| `modules/azure-webapp-cors` | :white_check_mark: |

## Reporting a Vulnerability

Please **do not open a public issue** for security vulnerabilities.

Instead, report them privately so the maintainers can address them before they
are publicly disclosed:

1. Use the **GitHub Security Advisory** mechanism: go to the
   `Security` tab of this repository and select
   `Report a vulnerability`.
2. Alternatively, email the repository owner with the details.

Please include:

* The affected module and version(s)
* A description of the vulnerability
* Steps to reproduce it (or a proof of concept)
* Any potential impact or mitigations you have identified

You will receive an acknowledgement within **7 days**, and an initial
assessment with a proposed timeline shortly afterwards. We request a
reasonable embargo period (typically 30 days) before public disclosure.

## Security Scanning in CI

Every pull request is automatically scanned by
[Trivy/tfsec](https://github.com/aquasecurity/trivy) (Infrastructure-as-Code
security scanner) and results are uploaded to GitHub code scanning. Review the
`Security` tab of the repository for findings.

## Best Practices for Users

* Never commit credentials or `.tfvars` files — they are gitignored.
* Use `sensitive` outputs and variables for any secret material.
* Restrict CORS `allowed_origins` to the origins you actually serve instead
  of `"*"` in production.
* Enable bucket versioning and state locking for the Terraform state
  (S3 + DynamoDB on AWS, Storage Account on Azure).
