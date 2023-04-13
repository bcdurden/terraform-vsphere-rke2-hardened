resource "vsphere_virtual_machine" "rke2_cp_0" {
  name                 = "${var.node_prefix}-cp-0"
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id

  wait_for_guest_net_timeout = 5

  num_cpus         = var.cp_cpu_count
  memory           = var.cp_memory_size_mb
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  provisioner "remote-exec" {
    inline = [
    "echo 'Waiting for cloud-init to complete...'",
    "cloud-init status --wait > /dev/null",
    "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.default_ip_address
      user        = "ubuntu"
      private_key = tls_private_key.global_key.private_key_openssh
    }
  }

  clone {
    template_uuid = data.vsphere_content_library_item.ubuntu_ovf.id
  }

  disk {
    label            = "disk0"
    size             = 40
  }
  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      "hostname" = "${var.node_prefix}-cp-0",
      "user-data" = base64encode( <<EOT
        #cloud-config
        package_update: true
        hostname: rancher-cp-0
        write_files:
        - path: /etc/rancher/rke2/config.yaml
          owner: root
          content: |
            token: ${var.cluster_token}
            tls-san:
            - ${var.node_prefix}-cp-0
            - ${var.rke2_vip}
        - path: /etc/hosts
          owner: root
          content: |
            127.0.0.1 localhost
            127.0.0.1 rancher-cp-0
        runcmd:
        - curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${var.rke2_version} sh -
        - mkdir -p /var/lib/rancher/rke2/server/manifests/
        - wget https://kube-vip.io/manifests/rbac.yaml -O /var/lib/rancher/rke2/server/manifests/kube-vip-rbac.yaml
        - curl -sL kube-vip.io/k3s |  vipAddress=${var.rke2_vip} vipInterface=${var.rke2_vip_interface} sh | sudo tee /var/lib/rancher/rke2/server/manifests/vip.yaml
        - systemctl enable rke2-server.service
        - systemctl start rke2-server.service
        ssh_authorized_keys: 
        - ${tls_private_key.global_key.public_key_openssh}
      EOT
      )  
    }
  }
}

resource "vsphere_virtual_machine" "rke2_worker" {
  count = var.worker_count
  depends_on = [
    vsphere_virtual_machine.rke2_cp_0
  ]

  name                 = "${var.node_prefix}-worker-${count.index}"
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id

  wait_for_guest_net_timeout = 5

  num_cpus         = var.worker_cpu_count
  memory           = var.worker_memory_size_mb
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  provisioner "remote-exec" {
    inline = [
    "echo 'Waiting for cloud-init to complete...'",
    "cloud-init status --wait > /dev/null",
    "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.default_ip_address
      user        = "ubuntu"
      private_key = tls_private_key.global_key.private_key_openssh
    }
  }

  clone { 
    template_uuid = data.vsphere_content_library_item.ubuntu_ovf.id
  }

  disk {
    label            = "disk0"
    size             = 40
  }
  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      "hostname" = "${var.node_prefix}-worker-${count.index}",
      "user-data" = base64encode( <<EOT
        #cloud-config
        package_update: true
        hostname: rancher-worker-${count.index}
        write_files:
        - path: /etc/rancher/rke2/config.yaml
          owner: root
          content: |
            token: ${var.cluster_token}
            server: https://${var.rke2_vip}:9345
        - path: /etc/hosts
          owner: root
          content: |
            127.0.0.1 localhost
            127.0.0.1 ${var.node_prefix}-worker-${count.index}
        runcmd:
        - curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" INSTALL_RKE2_VERSION=${var.rke2_version} sh -
        - systemctl enable rke2-agent.service
        - systemctl start rke2-agent.service
        ssh_authorized_keys: 
        - ${tls_private_key.global_key.public_key_openssh}
      EOT
      )  
    }
  }
}