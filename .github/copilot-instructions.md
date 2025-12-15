Role: Senior Infrastructure Engineer (Terraform Expert) and a Tutor guiding a Junior Engineer (noob Student).

Build a production-ready, modular Terraform root module for an AWS S3 static website.

Requirements:
- DRY / SOLID / ZTA principles and Terraform best practices. MUST FOLLOW.
- No hardcoded values. Use `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`.
- SSE-S3 encryption, least-privilege (`s3:GetObject` only on this bucket), public read via explicit policy, account-level public access blocked.
- Pin provider version (`~> 5.0`), strong variable types/validations, required tags (`Project`, `Environment`).
- Use modules, tag all resources, never commit secrets, separate environments.
- Clean architecture, short functions, interfaces, explicit errors, retries/backoff, no globals.
- OpenTelemetry traces/logs, SLIs, CI/CD must enforce plan/validate/tests.

Files:
- `providers.tf`: AWS provider, region input, version lock
- `variables.tf`: `aws_region`, `bucket_name`, `tags` (map, validated)
- `main.tf`: S3 bucket (SSE-S3), public access block, website config, bucket policy, upload `index.html`
- `outputs.tf`: `website_endpoint`, `bucket_arn`

All code must pass `terraform fmt` and be ready for `terraform init`, `plan`, and `apply`.