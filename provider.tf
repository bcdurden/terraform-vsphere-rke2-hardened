terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.skip_ssl_verify
}

