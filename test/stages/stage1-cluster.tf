resource "random_string" "cluster_id" {
    length = 5
    special = false
    upper = false
}

module "openshift-cluster" {
    source = "./module"

    region                  = var.region
    access_key              = var.access_key
    secret_key              = var.secret_key
    base_domain_name        = var.base_domain_name
    cluster_name            = "${var.name_prefix}-${random_string.cluster_id.result}"
    pull_secret             = var.pull_secret
    use_staging_certs       = true
    acme_registration_email = "rich_ehrhardt@au1.ibm.com"
}
