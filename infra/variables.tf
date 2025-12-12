variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = length(var.aws_region) > 0
    error_message = "aws_region must be a non-empty string."
  }
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must use lowercase letters, numbers, dots, or hyphens and start/end with alphanumerics."
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["Project", "Environment"] : contains(keys(var.tags), k)])
    error_message = "tags must include keys 'Project' and 'Environment'."
  }

  validation {
    condition     = alltrue([for k, v in var.tags : length(trimspace(v)) > 0])
    error_message = "All tag values must be non-empty."
  }
}

variable "use_localstack" {
  description = "If true, target LocalStack at http://localhost:4566 instead of AWS."
  type        = bool
  default     = false
}
