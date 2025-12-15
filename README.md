# Terraform S3 Static Site

Secure, modular Terraform to deploy an S3 static website. Includes a Docker-based LocalStack dev environment.

Features
- Modular, DRY Terraform
- SSE-S3 encryption and least-privilege bucket policy
- Local development with Docker + LocalStack

Files
- `infra/` — Terraform code and `index.html`
- `docker-compose.yml`, `Dockerfile` — dev environment

Quick start (local)
1. Clone and start LocalStack:
	```bash
	git clone https://github.com/gilbertordx/terraform-s3-static-site.git
	cd terraform-s3-static-site
	docker compose up -d --build
	```
2. (Optional) Enter the dev container:
	```bash
	docker exec -it tf-dev bash
	```
3. Copy example vars and edit `infra/terraform.tfvars`:
	```bash
	cp infra/terraform.tfvars.example infra/terraform.tfvars
	# set a unique bucket_name and tags
	```
4. From `infra/` run:
	```bash
	terraform init
	terraform plan
	terraform apply
	```

Verify
- Inside the container:
  ```bash
  curl http://localstack:4566/<bucket-name>/index.html
  ```
- LocalStack website endpoint formats:
  - Host-style: `http://<bucket-name>.s3-website.localhost.localstack.cloud:4566`
  - Path-style: `http://localhost:4566/<bucket-name>/index.html`
  Or run `terraform output -raw website_endpoint` (from `infra/`) to print the endpoint.

Deploy to AWS
1. Set `use_localstack = false` in `infra/terraform.tfvars`
2. Configure AWS credentials
3. Run `terraform init` and `terraform apply`

Notes
- `infra/terraform.tfvars.example` defaults to `use_localstack = true` for local dev.
- `.gitignore` currently excludes `.github/`; keep it ignored if it only contains personal Copilot instructions.

License
MIT
