variable "vsphere_user" {
  type        = string
  description = "Username of vsphere environment"
}

variable "vsphere_password" {
  type        = string
  description = "Password for username in vsphere environment"
}

variable "vsphere_server" {
  type        = string
  description = "Server URL for vsphere environment"
}

variable "skip_ssl_verify" {
  type        = bool
  description = "Flag to disable SSL verification when connecting to vsphere"
  default     = true
}

variable "datacenter_name" {
  type        = string
  description = "DC name in vsphere"
}

variable "ha_mode" {
  type        = bool
  description = "Flag to enable HA Control Plane"
  default     = false
}

variable "datastore_name" {
  type        = string
  description = "Datastore name"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name in vsphere"
}

variable "vm_folder" {
  type        = string
  description = "The vSphere VM folder in which to create the cluster"
  default     = ""
}

variable "network_name" {
  type        = string
  description = "Network name for cluster"
}

variable "cp_cpu_count" {
  type        = string
  description = "Control plane cpu count"
}

variable "cp_memory_size_mb" {
  type        = string
  description = "Control plane memory size in mb"
}

variable "cp_disk_size_gb" {
  type = string
  description = "Control plane disk size in gb"
}

variable "worker_cpu_count" {
  type        = string
  description = "Worker cpu count"
}

variable "worker_memory_size_mb" {
  type        = string
  description = "Worker memory size in mb"
}

variable "worker_disk_size_gb" {
  type = string
  description = "Worker disk size in gb"
}

variable "esxi_hosts" {
  type        = list
  description = "List of ESXi hosts"
}

variable "node_prefix" {
  type        = string
  description = "The prefix to apply to a node name, usually an environment or cluster prefix"
  default     = "rke2"
}

variable "cluster_token" {
  type        = string
  description = "Token used for joining rke2 cluster"
  default     = "mysharedtoken"
}

variable "rke2_version" {
  type        = string
  default     = "v1.24.9+rke2r2"
}

variable "worker_count" {
  type        = number
  description = "The amount of worker nodes to spawn"
  default     = 3
}

variable "kubeconfig_filename" {
  type        = string
  description = "The kubeconfig filename to output"
  default     = "kube_config.yaml"
}

variable "rke2_apiserver_lb_ip" {
  type        = string
  description = "The API server LB IP/URL (this is just a SAN entry for TLS)"
}

variable "rke2_registry" {
  type        = string
  description = "The system registry to pull images from"
}

variable "carbide_username" {
  type        = string
  description = "The carbide registry username"
}

variable "carbide_password" {
  type        = string
  description = "The carbide registry password"
}

variable "rke2_interface" {
  type        = string
  description = "The network interface on the control plane VMs to configure for static IPs"
  default     = "eth0"
}

variable "rke2_image_name" {
  type        = string
  description = "The name of the image in your content library"
}

variable "content_library_name" {
  type        = string
  description = "The name of the content library hosting the base images"
}

variable "os_user" {
  type        = string
  description = "The OS-level base username for the VM image (ubuntu for ubuntu, opensuse for SUSE Leap 15)"
}

variable "cp0_ip_address" {
  type        = string
  description = "The static IP address of the first control plane node"
}

variable "cpha_ip_addresses" {
  type        = list
  description = "Two IP addresses as strings for each additional control plane node in an HA configuration"  
}

variable "network_gateway_ip" {
  type        = string
  description = "The IP address of the network gateway for this cluster"
}

variable "dns_server_ip" {
  type        = string
  description = "The DNS IP address for this cluster"
}