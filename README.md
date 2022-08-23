# AWS OpenShift with Installer Provisioned Infrastructure (IPI)

## Module Overview

This module creates an OpenShift cluster on Amazon Web Services (AWS) using Installer-Provisioned Infrastructure. As such, it interfaces to AWS to create the infrastructure components, such as EC2 instances, for the cluster. It can either create all the infrastructure components including VPC and subnets for a quickstart, or in future, it will support providing an existing VPC environment. The deployed cluster will be across 3 availability zones.

### Prerequisites

1. A public domain needs to be configured in Route 53 which will be used by the cluster
1. The target region must have quota available for an additional VPC with 3 elastic IPs and 3 NAT gateways.

### Software Dependencies

This module depends upon the following software components:

#### Command Line Tools
 - terraform >= 1.2.6

#### Terraform providers

- AWS provider >= v4.27.0

### Module Dependencies - new virtual network

When creating a new virtual network, this module has not dependencies on other modules.

### Module Dependencies - existing virtual network
Will be supported in a future release

## Input Variables

This module has the following input variables:
| Variable | Mandatory / Optional | Default Value | Description |
| -------------------------------- | --------------| ------------------ | ----------------------------------------------------------------------------- |
| cluster_name | Mandatory | "" | The name to give the OpenShift cluster  |
| base_domain_name | Mandatory | "" | The existing Route 53 wildcard base domain name that has been defined. For example, clusters.mydomain.com. |
| region | Mandatory | "" | AWS region into which to deploy the OpenShift cluster |
| access_key | Mandatory | "" | The AWS account access key |
| secret_key | Mandatory | "" | The AWS account secret key |
| pull_secret | Mandatory | "" | The Red Hat pull secret to access the Red Hat image repositories to install OpenShift. One of pull_secret or pull_secret_file is required. |
| pull_secret_file | Mandatory | "" | The full path and name of the file containing the Red Hat pull secret to access the Red Hat image repositories for the OpenShift installation. One of pull_secret or pull_secret_file is required. |
| public_ssh_key | Optional | "" | An existing public key to be used for post implementation node (EC2 Instance) access. If left as default, a new key pair will be generated. |
| algorithm | Optional | RSA | Algorithm to be utilized if creating a new key |
| rsa_bits | Optional | 4096 | The number of bits for the RSA key if creating a new RSA key |
| ecdsa_curve | Optional | P224 | The ECDSA curve value to be utilized if creating a new ECDSA key |
| private | Optional | false | (Not currently utilized) Flag to indicate whether cluster is in a private VPC |
| binary_offset | Optional | binaries | The path offset from the terraform root directory into which the binaries will be stored. |
| install_offset | Optional | install | The path offset from the terraform root directory into which the OpenShift installation files will be stored. |
| openshift_version | Optional | 4.10.11 | The version of OpenShift to be installed (must be available in the mirror repository - see below) |
| master_hyperthreading | Optional | Enabled | Flag to determine whether hyperthreading should be used for master nodes. |
| master_architecture | Optional | amd64 | CPU Architecture for the master nodes |
| master_node_type | Optional | m5.2xlarge | AWS EC2 Instance type for the master nodes. Note the minimum size is 8 vCPU and 32GB RAM |
| master_node_qty | Optional | 3 | The number of master nodes to be deployed. |
| worker_hyperthreading | Optional | Enabled | Flag to determine whether hyperthreading should be used for worker nodes. |
| worker_architecture | Optional | amd64 | CPU Architecture for the worker nodes |
| worker_node_type | Optional | m5.2xlarge | AWS EC2 Instance type for the worker nodes. Note the minimum size is 4 vCPU and 16GB RAM |
| worker_volume_iops | Optional | 400 | Worker node disk IOPS |
| worker_volume_size | Optional | 500 | Worker node disk size (GB) |
| worker_volume_type | Optional | io2 | Type of disk for worker nodes |
| worker_node_qty | Optional | 3 | The number of worker nodes to be deployed. |
| cluster_cidr | Optional | 10.128.0.0/14 | CIDR for the internal OpenShift network. |
| cluster_host_prefix | Optional | 23 | Host prefix for the internal OpenShift network |
| network_type | Optional | OpenShiftSDN | Network plugin to use for the OpenShift virtual networking. |
| machine_cidr | Optional | 10.0.0.0/16 | CIDR for the master and worker nodes. Must be the same or a subset of the VPC CIDR |
| service_network_cidr | Optional | 172.30.0.0/16 | CIDR for the internal OpenShift service network. |
| enable_fips | Optional | false | Flag to enable FIPS on the cluster. |
| existing_vpc | Optional | false | Flag to indicate use of an existing VPC (Not current implemented) |
| vpc_cidr | Optional | "" | Exisitng VPC CIDR (Not current implemented) |
| private_subnet1 | Optional | "" | Existing private subnet in availability zone 1 (Not current implemented) |
| private_subnet2 | Optional | "" | Existing private subnet in availability zone 2 (Not current implemented) |
| private_subnet3 | Optional | "" | Existing private subnet in availability zone 3 (Not current implemented) |
| public_subnet1 | Optional | "" | Existing public subnet in availability zone 1 (Not current implemented) |
| public_subnet2 | Optional | "" | Existing public subnet in availability zone 2 (Not current implemented) |
| public_subnet3 | Optional | "" | Existing public subnet in availability zone 3 (Not current implemented) |

## Example Usage 
```hcl-terraform
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

  }
}

provider "aws" {
  region        = var.region
  access_key    = var.access_key
  secret_key    = var.secret_key
}

module "openshift-cluster" {
    source = "github.com/cloud-native-toolkit/terraform-aws-ocp-ipi"

    region = var.region                       # AWS region to deploy cluster into
    access_key = var.access_key               # AWS access key
    secret_key = var.secret_key               # AWS access key secret
    base_domain_name = var.base_domain_name   # Base domain name registered in AWS (e.g. clusters.mydomain.com)
    cluster_name = var.cluster_name           # Name of the cluster and environment tag for deployed resources
    pull_secret_file = var.pull_secret_file   # Path to the file with the Red Hat OpenShift pull secret
}
```

## Post Installation

Post installation it is necessary to add your own certificate to the cluster to access the console.

To access the cluster from the command line (this is using the default binary and install path offsets),
```
  $ export KUBECONFIG=./install/auth/kubeconfig
  $ ./binaries/oc get nodes
```

## Troubleshooting

In the event that the openshift installation fails, check the logs under,
```
<root_path>/<install_path>/.openshift_install.log
```
the default install_path value is install, so from the place you ran the terraform from, it is possible to see the last log entries using the following command,
```shell
$ tail -25 ./install/.openshift_install.log
```

The default kubeconfig for cluster access is located under the same installation directory,
```
<root_path>/<install_path>/auth/kubeconfig
```

To login to the cluster from the CLI, export this as your KUBECONFIG shell environment value,
```shell
$ export KUBECONFIG=./install/auth/kubeconfig
```

You should then be able to obtain details of the cluster, such as (with the default binary path),
```shell
$ ./binaries/oc get clusterversion
```
