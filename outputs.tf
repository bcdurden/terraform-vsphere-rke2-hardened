output "ssh_key" {
    value = tls_private_key.global_key.private_key_pem
    sensitive = true
}
output "ssh_pubkey" {
    value = tls_private_key.global_key.public_key_openssh
}
output "kubeconfig" {
    value = local_file.kube_config_server_yaml.filename
    sensitive = true
}