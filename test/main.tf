module "rke2-hardened" {
  source  = "../"
  
  vsphere_user = ""
  vsphere_password = ""
  vsphere_server = "10.0.0.5"
  skip_ssl_verify = true
  datacenter_name = "Datacenter"
  datastore_name = "datastore1"
  cluster_name = "Cluster"
  network_name = "rgs-network"
  ha_mode = true
  cp_cpu_count = 4
  cp_memory_size_mb = 8192
  cp_disk_size_gb = 40
  worker_cpu_count = 4
  worker_memory_size_mb = 8192
  worker_disk_size_gb = 40
  esxi_hosts = ["10.0.0.12"]
  node_prefix = "rke2-module-test"
  cluster_token = "mysharedtoken"
  rke2_version = "v1.24.9+rke2r2"
  worker_count = 3
  rke2_vip = "10.1.1.4"
  rke2_vip_interface = "ens192"
  rke2_image_name = "jammy-server-cloudimg-amd64"
  content_library_name = "cl"

  rke2_registry = ""
  carbide_username = "" 
  carbide_password = ""
}