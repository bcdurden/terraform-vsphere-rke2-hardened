resource "ssh_resource" "retrieve_config" {
  host = vsphere_virtual_machine.rke2_cp_0.default_ip_address
  commands = [
    "sudo sed \"s/127.0.0.1/${var.rke2_vip}/g\" /etc/rancher/rke2/rke2.yaml"
  ]
  user        = var.os_user
  private_key = tls_private_key.global_key.private_key_pem
}
resource "local_file" "kube_config_server_yaml" {
  filename = var.kubeconfig_filename
  content  = ssh_resource.retrieve_config.result
}