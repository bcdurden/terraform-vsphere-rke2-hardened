module "rke2-hardened" {
  source  = "bcdurden/rke2-hardened/vsphere"
  version = "0.0.1"
  vsphere_user = 
  vsphere_password =
  vsphere_server =
  skip_ssl_verify =
  datacenter_name =
  datastore_name =
  cluster_name =
  network_name =
  cp_cpu_count =
  cp_memory_size_mb =
  worker_cpu_count =
  worker_memory_size_mb =
  esxi_hosts =
  node_prefix =
  cluster_token =
  rke2_version =
  worker_count =
  kubeconfig_filename =
  rke2_vip =
  rke2_vip_interface =
  rke2_image_name =
  content_library_name =                                                                  
}