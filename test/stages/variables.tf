variable "region" {
  description = "AWS region to deploy cluster"
  type        = string
}

variable "access_key" {
  description = "AWS account access key"
  type        = string
}

variable "secret_key" {
  description = "AWS account secret key"
  type        = string
}

variable "base_domain_name" {
  description = "Base domain name (e.g. myclusters.mydomain.com)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the cluster name and environment tag"
  type        = string
}

variable "pull_secret" {
    description = "Pull secret for OpenShift image repository access and to register the cluster"
    type        = string
}
