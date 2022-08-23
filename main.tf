locals {
  pull_secret = var.pull_secret_file != "" ? "${chomp(file(var.pull_secret_file))}" : var.pull_secret

  install_path = "${path.cwd}/${var.install_offset}"
  binary_path = "${path.cwd}/${var.binary_offset}"

  cluster_type = "openshift"
  cluster_type_code = "ocp4"
  cluster_version = "${data.external.cluster_info.result.serverVersion}_openshift"

  resource_group = var.cluster_name

  key_name = "ocp_access"
}

resource "local_file" "aws_config" {
    content = templatefile("${path.module}/templates/credentials.tftpl",{
        ACCESS_KEY      = var.access_key
        ACCESS_SECRET   = var.secret_key
    })
    filename        = pathexpand("~/.aws/credentials")
    file_permission = "0600"
}

resource "tls_private_key" "key" {
    count     = var.public_ssh_key == "" ? 1 : 0

    algorithm = var.algorithm
    rsa_bits  = var.algorithm == "RSA" ? var.rsa_bits : null
    ecdsa_curve = var.algorithm == "ECDSA" ? var.ecdsa_curve : null
}

resource "local_file" "private_key" {
    count           = var.public_ssh_key == "" ? 1 : 0

    content         = tls_private_key.key[0].private_key_pem
    filename        = "${local.install_path}/${local.key_name}"
    file_permission = "0600"
}

resource "local_file" "public_key" {
    count           = var.public_ssh_key == "" ? 1 : 0
    
    content         = tls_private_key.key[0].public_key_openssh
    filename        = "${local.install_path}/${local.key_name}.pub"
    file_permission = "0644"
}

data "local_file" "pub_key" {
    depends_on = [
      local_file.public_key
    ]

    filename        = "${local.install_path}/${local.key_name}.pub"
}

module setup_clis {
    source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

    bin_dir = local.binary_path
    clis    = ["openshift-install-${var.openshift_version}","jq","yq4","oc"]
}

resource "local_file" "install_config" {
    content = templatefile("${path.module}/templates/install-config.yaml.tftpl", {
        BASE_DOMAIN             = var.base_domain_name
        MASTER_HYPERTHREADING   = var.master_hyperthreading
        MASTER_ARCHITECTURE     = var.master_architecture
        MASTER_NODE_TYPE        = var.master_node_type
        MASTER_NODE_QTY         = var.master_node_qty
        WORKER_HYPERTHREADING   = var.worker_hyperthreading
        WORKER_ARCHITECTURE     = var.worker_architecture
        WORKER_NODE_TYPE        = var.worker_node_type
        WORKER_VOLUME_IOPS      = var.worker_volume_iops
        WORKER_VOLUME_SIZE      = var.worker_volume_size
        WORKER_VOLUME_TYPE      = var.worker_volume_type
        WORKER_NODE_QTY         = var.worker_node_qty
        CLUSTER_NAME            = var.cluster_name
        CLUSTER_CIDR            = var.cluster_cidr
        CLUSTER_HOST_PREFIX     = var.cluster_host_prefix
        MACHINE_CIDR            = var.existing_vpc ? var.vpc_cidr : var.machine_cidr
        NETWORK_TYPE            = var.network_type
        SERVICE_NETWORK_CIDR    = var.service_network_cidr
        AWS_REGION              = var.region
        RESOURCE_GROUP          = local.resource_group
        EXISTING_VPC            = var.existing_vpc
        PRIVATE_SUBNET1         = var.existing_vpc ? var.private_subnet1 : ""
        PRIVATE_SUBNET2         = var.existing_vpc ? var.private_subnet2 : ""
        PRIVATE_SUBNET3         = var.existing_vpc ? var.private_subnet3 : ""
        PUBLIC_SUBNET1          = var.existing_vpc && !var.private ? var.public_subnet1 : ""
        PUBLIC_SUBNET2          = var.existing_vpc && !var.private ? var.public_subnet2 : ""
        PUBLIC_SUBNET3          = var.existing_vpc && !var.private ? var.public_subnet3 : ""
        PULL_SECRET             = local.pull_secret
        PUBLISH                 = var.private ? "Internal" : "External"
        ENABLE_FIPS             = var.enable_fips
        PUBLIC_SSH_KEY          = var.public_ssh_key == "" ? data.local_file.pub_key.content : file(var.public_ssh_key)
    })
    filename        = "${local.install_path}/install-config.yaml"
    file_permission = "0664"
}

resource "null_resource" "openshift-install" {
  depends_on = [
        local_file.aws_config,
        local_file.install_config,
        module.setup_clis
  ]

  triggers = {
        binary_path = local.binary_path
        install_path = local.install_path
  }

  provisioner "local-exec" {
    when = create

    command = "${path.module}/scripts/install.sh"

    environment = {
        BINARY_PATH = "${self.triggers.binary_path}"
        INSTALL_PATH = "${self.triggers.install_path}"
     }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/destroy.sh"
    
    environment = {
        BINARY_PATH = "${self.triggers.binary_path}"
        INSTALL_PATH = "${self.triggers.install_path}"
     }
  }
}

data external "cluster_info" {
    depends_on = [
        null_resource.openshift-install,
        module.setup_clis
    ]

    program = ["bash", "${path.module}/scripts/cluster-info.sh"]
    
    query = {
        bin_dir = local.binary_path
        log_file = "${local.install_path}/.openshift_install.log"
        metadata_file = "${local.install_path}/metadata.json"
        kubeconfig_file = "${local.install_path}/auth/kubeconfig"
    }
}