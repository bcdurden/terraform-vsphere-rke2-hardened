# Hardened RKE2 Cluster on vSphere Terraform Module
This readme will cover the basics around using this repository locally and examples of how to use it as downloadable module.

WARNING: The module will be updated semi-frequently as new features are needed or bugs are discovered. Some of the more detailed info in this doc will by consequence become obsolete. It is impotant to check the module spec itself to verify.

## What this Module Does
The below module will create MOST components within a vSphere environment in order to deploy a configurable and hardened RKE2 cluster. By hardened, this means that the cluster will be compliant with the public DISA STIG for RKE2 1.24. 

It is possible that certain hypervisor/OS configurations will not like some of the kernel modifications that come with the cis-1.6 profile. This module has been tested on Ubuntu 20.04/22.04 but there is nothing Ubuntu-specific in any of the cloud-init configuration. The only dependency on the VM/OS template image used is that it supports cloud-init. Some base installations from an iso do not include this, but all cloud image releases from major OS maintainers do.

The module has several dependencies for existing infrastructure and they are outlined below. The module will automatically create SSH credentials, grabbing the kubeconfig from the control plane, and setting a static VIP for the cluster for a quasi-LB HA setup. However, for true production deployments, static IPs should be used on the control-plane nodes regardless of the status of an LB.

## Limitations
This module is not designed out of the box to function in a hard airgap. The `system default registry` is an available setting and this module CAN use the Carbide hardened container registry, but even when pulling from a local registry, the RKE2 installation will try to verify the binary checksums by reaching out to the public release page on github. There are ways around this, namely creating a custom VM OVA/OVF that contains pre-installed RKE2 checksums/binaries and updating the cloud-init to boot. All of this is exposed in the module itself, so there is no magic to detangle but it will require a bit of work. A feature request is out to fix this limitation.

Since this module uses an SSH provisioner to ensure cloud-init runs to successful completion, you will also need TCP/22 access to the VIP of the cluster as well as the IPs of each VM.

## Dependencies
There are several dependencies that must be addresses prior to using this module. They are listed below
* At least one Datacenter and Cluster within vCenter MUST be defined. This module does not support deploying to ESXi directly
* Credentials must exist with appropriate priviledges for creating VMs and attaching various components within vSphere. For full details on that, please see the [RKE2 documentation](https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/launch-kubernetes-with-rancher/use-new-nodes-in-an-infra-provider/vsphere/create-credentials). Administrator credentials also work
* A Distributed Switch port group must exist for the cluster to work
* This module requires a content library host the base OVF/OVA image for the VMs, while there are other methods available from within Terraform, it was identified that CLs are the more future-proof option and the best way to access. However, this requires that certain credential bindings be completed at the top-level as content libraries exist adjascent to Datacenters from a permissions heirarchy point of view.
* The module requires DHCP/IPAM support on the chosen network/portgroup.

Given the above is in place, using the module is mostly a fill-in-the-blank process. Within the `test` directory, you'll see `main.tf`. This file and directory is used to encapsulate a single Terraform deployment. All dependencies in this test are handled by the module itself. 

## Deploying via Test mode (locally)
Within the `test/main.tf` file, at the top you can see how the module is referenced using a local directory under the `source` field:
```hcl
module "rke2-hardened" {
  source  = "../"
  
  vsphere_user          = ""                        
  vsphere_password      = ""
  vsphere_server        = "10.0.0.5"
  skip_ssl_verify       = true         
  datacenter_name       = "Datacenter"                       
  datastore_name        = "datastore1"
```

Since this references the module locally, the module itself does not need to download, however the module has upstream dependencies and will download them when `terraform init` is run. When running in an airgap, you'll need to prep your directory with internet access so these dependencies can be downloaded. Hosting modules locally can be done but requires some work and is not really in scope for a basic test/poc. It's generally easiest to include the terraform code locally until a more scalable solution is needed.

### Init
If you are going to test this in a hard airgap, it is ok to run `terraform init` from within the `test` directory. After it is complete, tarball the entire repo (not just the test directory) and bring it into your airgap.
```bash
> terraform init
Initializing modules...
- rke2-hardened in ..

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/local versions matching "2.2.3"...
- Finding loafoe/ssh versions matching "2.6.0"...
- Finding hashicorp/random versions matching "3.4.3"...
- Finding latest version of hashicorp/tls...
- Finding latest version of hashicorp/vsphere...
- Installing hashicorp/local v2.2.3...
- Installed hashicorp/local v2.2.3 (signed by HashiCorp)
- Installing loafoe/ssh v2.6.0...
- Installed loafoe/ssh v2.6.0 (self-signed, key ID C0E4EB79E9E6A23D)
- Installing hashicorp/random v3.4.3...
- Installed hashicorp/random v3.4.3 (signed by HashiCorp)
- Installing hashicorp/tls v4.0.4...
- Installed hashicorp/tls v4.0.4 (signed by HashiCorp)
- Installing hashicorp/vsphere v2.4.0...
- Installed hashicorp/vsphere v2.4.0 (signed by HashiCorp)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Apply
Within the `main.tf`, fill all fields out. vSphere requires case to match as well as spaces. Using spaces in naming conventions of cloud and on-prem objects is generally poor form and to be avoided, but sometimes existing infrastructure is inherited.

Once filled, the module can be deployed using `terraform apply` within the `test` directory. Depending on how many worker nodes are chosen and whether HA mode is enabled, you will see around 10 or more objects to be created. If everything looks good, type yes to apply.

```bash
    }

Plan: 12 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + kubeconfig = (sensitive value)
  + ssh_key    = (sensitive value)
  + ssh_pubkey = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

### Finish
After finishing, assuming successful completion, you will see the kubeconfig file in your test directory. This file allows administrative access to the cluster that was just created. You can either copy this file to `~/.kube/config` or if you already have one, you can merge this config as a new context into your existing config using [kubecm](https://kubecm.cloud/).

```bash
...
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

kubeconfig = <sensitive>
ssh_key = <sensitive>
ssh_pubkey = <<EOT
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+TwLuQYnuPUQx5qrsZXRG7WE4X4LA/POJwcRI7/cqZoAz3unntzY5lzGEVUKofqLj+s41mvQ6kigbNUsaJsIp0ULWlGJ9QECe7OYgLOFjREJhgquOPiCFZ+E+vE5vNV85NDWd/TUSoyLxLKeU6p8rYNwp3IBp5D/NcwAU6JujCsT/Ghbt1VMuQvkT1UmxPxVuiEkVTBkPkhFyLVCloGA+yQgck10ol9Jtazj08iElwq2kvK+pAxOgINXbt0KIZxN7nsJhFPjzDKoVA/Gf9GbpMevYSZSj+aQ95DRQqQ+M3/B6UiIPmHzrBS+vqnpNpA0w49uwr0V+JUj+RVfFCUfp
```

## Deploying as a true Module
The steps above will follow the same process but now your only directory of need is the test directory. The `source` line will need to be modified to reflect the official Terraform module registry location of this module as well as the version desired. This information is also exposed as an [official Terraform module](https://registry.terraform.io/modules/bcdurden/rke2-hardened/vsphere/latest)

```hcl
module "rke2-hardened" {
  source  = "bcdurden/rke2-hardened/vsphere"
  version = "0.0.12"
```

Follow the same process as above. If in an airgap, you'll need to run `terraform init` to pull all dependent modules down, then tarball the directory, and bring into your airgap. Once everything is square, you should be able to run `terraform apply` and see a similar result to above.

Using the public module is not absolutely necessary, but from a sustainment aspect you want to keep a central source of truth where this module may not be hosted with other Terraform code. The best way to do that is via a remote module.

## Day1 and beyond
While this process can get your cluster up and running quickly, your next thoughts should be around what this looks like in production. The biggest one is how you will store the Terraform state. By default, and also in this module, the state is stored locally as a file. This file contains everything about the existing environment, losing it can cause major problems if you intend on modifying the existing environment. Without it, Terraform has no way of establishing what objects it has already created so it cannot reconcile any changes or deletions. 

To solve this problem, the `backend` field in the provider code needs to be considered. This is essentially where Terraform stores the state file. It can be stored in a variety of places such as Kubernetes itself, S3 buckets, databases, etc. The other benefit is the lock/lease mechanism built around the statefile in the backend to prevent multiple users from applying conflicting changes to the same environment while another change is in progress.