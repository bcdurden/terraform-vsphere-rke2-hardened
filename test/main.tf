module "rke2-hardened" {
  source  = "../"
  
  vsphere_user          = ""                        
  vsphere_password      = ""
  vsphere_server        = ""
  skip_ssl_verify       = true         
  datacenter_name       = "Datacenter"                       
  datastore_name        = "datastore1"
  cluster_name          = "Cluster"
  network_name          = "rgs-network"
  ha_mode               = true
  cp_cpu_count          = 4
  cp_memory_size_mb     = 8192                            # this value MUST be in terms of actual megabytes, ie. 4096, 8192, 16384, 32768
  cp_disk_size_gb       = 40                              # this value is in whole gigabytes
  worker_cpu_count      = 4     
  worker_memory_size_mb = 8192                            # this value MUST be in terms of actual megabytes, ie. 4096, 8192, 16384, 32768
  worker_disk_size_gb   = 40                              # this value is in whole gigabytes

  esxi_hosts            = ["10.0.0.12"]                   # due to a limitation in the vsphere provider, this must be a list of all esxi hosts in the cluster
  node_prefix           = "rke2-module-test"              # this prefix is attached to all VM names
  cluster_token         = "mysharedtoken"                 # this is the RKE2 join token and can be any value
  rke2_version          = "v1.24.9+rke2r2"                # this is the RKE2 version to use
  worker_count          = 3
  rke2_vip              = "10.1.1.4"                      # This is the static VIP (virtual IP) used via kubevip for the RKE2 api server
  rke2_vip_interface    = "ens192"                        # This is the static VIP physical interface to bind to on the control plane VM(s) used by kubevip
  rke2_image_name       = "jammy-server-cloudimg-amd64"   # This is the name of the OVA image within the content library
  content_library_name  = "cl"
  vm_folder             = ""

  rke2_registry = ""                                      # leave these empty unless you are using carbide or an airgapped registry
  carbide_username = "" 
  carbide_password = ""
}