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
  rke2_apiserver_lb_ip  = "10.1.1.3"                      # This is the static IP used for the apiserver load balancer
  rke2_interface        = "eth0"                          # This is the static physical interface to bind to on the control plane VM(s)
  rke2_image_name       = "suse-leap-15.5"                # This is the name of the OVA image within the content library
  content_library_name  = "cl"
  vm_folder             = ""

  rke2_registry         = ""                              # leave these empty unless you are using carbide or an airgapped registry
  carbide_username      = "" 
  carbide_password      = ""

  os_user               = "opensuse"                      # by default we're using SUSE Leap 15.5, so this user is opensuse (for ubuntu it would be ubuntu)

  cp0_ip_address        = "10.1.1.4"
  network_gateway_ip    = "10.1.1.1"
  dns_server_ip         = "8.8.8.8"
  cpha_ip_addresses     = ["10.1.1.5","10.1.1.6"]
}