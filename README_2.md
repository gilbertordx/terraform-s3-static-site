# Terraform S3 Static Site

Deploy a secure, production-ready S3 static website using modular Terraform and Docker.

## Features
- Modular, DRY Terraform (SOLID principles)
- SSE-S3 encryption, least-privilege, Zero Trust policy
- Local dev: Docker + LocalStack
- Standards: CI/CD, security, testing, required tags

## Project Structure
```
infra/                  # Terraform code and static site content
  ├── index.html        # Static site
  ├── main.tf           # S3 resources, policies, website config
  ├── outputs.tf        # Outputs: website endpoint, bucket ARN
  ├── providers.tf      # AWS provider, version lock, LocalStack support
  ├── variables.tf      # Strongly-typed, validated variables
  └── terraform.tfvars.example  # Example config
docker-compose.yml      # LocalStack + dev container
Dockerfile              # Dev environment
```

## Quick Start
1. Clone & start:
	```bash
	git clone https://github.com/gilbertordx/terraform-s3-static-site.git
	cd terraform-s3-static-site
	docker compose up -d --build
	```
2. Enter dev container:
	```bash
	docker exec -it tf-dev bash
	```
3. Configure variables:
	```bash
	cp terraform.tfvars.example terraform.tfvars
	# Edit terraform.tfvars (set unique bucket_name, tags, etc)
	```
4. Deploy to LocalStack:
	```bash
	terraform init
	terraform plan
	terraform apply
	# Type 'yes' when prompted
	```
5. Verify:
	```bash
	curl http://localstack:4566/your-unique-bucket-name/index.html
	```

## Deploy to AWS
1. Set `use_localstack = false` in `terraform.tfvars`
2. Configure AWS credentials (`aws configure` or env vars)
3. Run:
	```bash
	terraform apply
	```
    
## License
MIT
