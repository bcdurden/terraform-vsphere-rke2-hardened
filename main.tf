resource "vsphere_virtual_machine" "rke2_cp_0" {
  name                 = "${var.node_prefix}-cp-0"
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  folder               = "${data.vsphere_datacenter.datacenter.name}/${var.vm_folder}"

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
    size             = var.cp_disk_size_gb
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
        hostname: ${var.node_prefix}-cp-0
        write_files:
        - path: /etc/rancher/rke2/config.yaml
          owner: root
          content: |
            token: ${var.cluster_token}
            system-default-registry: ${var.rke2_registry}
            tls-san:
            - ${var.node_prefix}-cp-0
            - ${var.rke2_vip}
            profile: cis-1.6
            selinux: true
            secrets-encryption: true
            write-kubeconfig-mode: 0640
            use-service-account-credentials: true
            kube-controller-manager-arg:
            - bind-address=127.0.0.1
            - use-service-account-credentials=true
            - tls-min-version=VersionTLS12
            - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
            kube-scheduler-arg:
            - tls-min-version=VersionTLS12
            - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
            kube-apiserver-arg:
            - tls-min-version=VersionTLS12
            - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
            - authorization-mode=RBAC,Node
            - anonymous-auth=false
            - audit-policy-file=/etc/rancher/rke2/audit-policy.yaml
            - audit-log-mode=blocking-strict
            - audit-log-maxage=30
            kubelet-arg:
            - protect-kernel-defaults=true
            - read-only-port=0
            - authorization-mode=Webhook
            - streaming-connection-idle-timeout=5m
        - path: /etc/rancher/rke2/registries.yaml
          owner: root
          content: |
            configs:
              "rgcrprod.azurecr.us":
                auth:
                  username: ${var.carbide_username}
                  password: ${var.carbide_password}
        - path: /etc/hosts
          owner: root
          content: |
            127.0.0.1 localhost
            127.0.0.1 ${var.node_prefix}-cp-0
        runcmd:
        - curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${var.rke2_version} sh -
        - systemctl enable rke2-server.service
        - mkdir -p /var/lib/rancher/rke2/server/manifests/
        - wget https://kube-vip.io/manifests/rbac.yaml -O /var/lib/rancher/rke2/server/manifests/kube-vip-rbac.yaml
        - curl -sL kube-vip.io/k3s |  vipAddress=${var.rke2_vip} vipInterface=${var.rke2_vip_interface} sh | sudo tee /var/lib/rancher/rke2/server/manifests/vip.yaml
        - cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
        - useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
        - systemctl restart systemd-sysctl
        - systemctl start rke2-server.service
        ssh_authorized_keys: 
        - ${tls_private_key.global_key.public_key_openssh}
      EOT
      )  
    }
  }
}

resource "vsphere_virtual_machine" "rke2_cp_ha" {
  count = var.ha_mode ? 2 : 0
  depends_on = [
    vsphere_virtual_machine.rke2_cp_0
  ]

  name                 = "${var.node_prefix}-cp-${count.index+1}"
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  folder               = "${data.vsphere_datacenter.datacenter.name}/${var.vm_folder}"

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
    size             = var.cp_disk_size_gb
  }
  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      "hostname" = "${var.node_prefix}-cp-${count.index+1}",
      "user-data" = base64encode( <<EOT
        #cloud-config
        package_update: true
        hostname: ${var.node_prefix}-cp-${count.index+1}
        write_files:
        - path: /etc/rancher/rke2/config.yaml
          owner: root
          content: |
            token: ${var.cluster_token}
            server: https://${var.rke2_vip}:9345
            system-default-registry: ${var.rke2_registry}
            profile: cis-1.6
            selinux: true
            secrets-encryption: true
            write-kubeconfig-mode: 0640
            use-service-account-credentials: true
            kube-controller-manager-arg:
            - bind-address=127.0.0.1
            - use-service-account-credentials=true
            - tls-min-version=VersionTLS12
            - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
            kube-scheduler-arg:
            - tls-min-version=VersionTLS12
            - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
            kube-apiserver-arg:
            - tls-min-version=VersionTLS12
            - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
            - authorization-mode=RBAC,Node
            - anonymous-auth=false
            - audit-policy-file=/etc/rancher/rke2/audit-policy.yaml
            - audit-log-mode=blocking-strict
            - audit-log-maxage=30
            kubelet-arg:
            - protect-kernel-defaults=true
            - read-only-port=0
            - authorization-mode=Webhook
            - streaming-connection-idle-timeout=5m
        - path: /etc/rancher/rke2/registries.yaml
          owner: root
          content: |
            configs:
              "rgcrprod.azurecr.us":
                auth:
                  username: ${var.carbide_username}
                  password: ${var.carbide_password}
        - path: /etc/hosts
          owner: root
          content: |
            127.0.0.1 localhost
            127.0.0.1 ${var.node_prefix}-cp-${count.index+1}
        runcmd:
        - curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${var.rke2_version} sh -
        - systemctl enable rke2-server.service
        - cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
        - useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
        - systemctl restart systemd-sysctl
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
  folder               = "${data.vsphere_datacenter.datacenter.name}/${var.vm_folder}"

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
    size             = var.worker_disk_size_gb
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
        hostname: ${var.node_prefix}-worker-${count.index}
        write_files:
        - path: /etc/rancher/rke2/config.yaml
          owner: root
          content: |
            token: ${var.cluster_token}
            server: https://${var.rke2_vip}:9345
            system-default-registry: ${var.rke2_registry}
            write-kubeconfig-mode: 0640
            profile: cis-1.6
            kube-apiserver-arg:
            - authorization-mode=RBAC,Node
            kubelet-arg:
            - protect-kernel-defaults=true
            - read-only-port=0
            - authorization-mode=Webhook
        - path: /etc/rancher/rke2/registries.yaml
          owner: root
          content: |
            configs:
              "rgcrprod.azurecr.us":
                auth:
                  username: ${var.carbide_username}
                  password: ${var.carbide_password}
        - path: /etc/hosts
          owner: root
          content: |
            127.0.0.1 localhost
            127.0.0.1 ${var.node_prefix}-worker-${count.index}
        runcmd:
        - curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" INSTALL_RKE2_VERSION=${var.rke2_version} sh -
        - systemctl enable rke2-agent.service
        - cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
        - systemctl restart systemd-sysctl
        - systemctl start rke2-agent.service
        ssh_authorized_keys: 
        - ${tls_private_key.global_key.public_key_openssh}
      EOT
      )  
    }
  }
}