# Openshift on Oxide cloud computer

This is some notes regarding semi automated setup of openshift 4.20 on the 0xide cloud computer.

I consider it work in progress, and the notes are intended for my own remembering.

The setup has been tested with Openshift enterprise 4.20, however it should
work equally well with OKD, as long as the install config is adjested
accordingly.

Note: Once there exist RHCOS images that reads the "user_data"  provided by
 the 0xide metadata service (NoCloud) creating tailored images with kernel
 params for fetchin ignition configs will not be necessary anymore.

NB: This setup is not intended for production use!

## Runbook

* Install openshift-install and openshift clients from https://access.redhat.com/downloads/
* Install Opentofu or Terraform
* Install awscli and configure it in order to create an s3 bucket for uploading ignition files.
  * Set ACLs on bucket to public, and limit source IP access to what is expected from your 0xide silo
* Provision an Ubuntu server instance 24.04 (or similar), and install haproxy. This will be your loadbalncer
* Allocate a floating IP and attach it to the loadblancer instance
* Own a DNS base domain where you can configer A-records in.
* Create the DNS A-records for *.apps.clustername.base-domain, api.clustername.base-domain and api-int.clustername.base-domaan pointing to the floating IP-adress of the loadbalancer instance
* Download the "Red Hat Enterprise Linux CoreOS - Baremetal QEMU Image (QCOW2)" image from RedHat.
* Convert it to raw format and create an image for it in your 0xide project. (Ref: https://docs.oxide.computer/guides/creating-and-sharing-images)
* Create a disk from the RHCOS image and attach the disk to the loadbalancer instance
* Boot the loadbalancer instance and mount the RHCOS image's boot partition and append kernel arguments "ignition.config.url=<address-of-your-s3-bootstrap.ign-file>" to the grub config
* Unmount the RHCOS disk's boot partition, stop the loadbalancer instance and create a snapshot of the RHCOS disk, then create a dedicateed  RHCOS image from that snapshot. This is the image-id you will use later to create the bootstrap node instance in cluster.yaml
* Repeat the above process to create RHCOS image for control plane nodes and worker nodes respectively, so that they boot and fetch ignition configs from the master.ign and worker.ign files in your s3 bucket. This will be the image ids you confgure for control plne and worker nodes in the cluster.yaml file later
* Create VPC firewall rules to allow traffic to tcp ports 6443, 22623, 80 and 443 within the VPC . (Note this can be made more granular and also included in the Terraform config)
* Fetch the id of your default vpc and subnet.
* Fill in the vpc_id, project_id and normalized_cluster_name in the cluster.yaml file, and adjust the valeus to your liking. The defaults should be sufficient for a POC cluster of Openshift.
* Run terreform init, plan and apply (if all looks good)
* source the functions file, run fetch_master_backends and combine the output with the haproxy_config stub and apply the config to the loadbalancer.
* export KUBECONFIG=installer_dir/auth/kubeconfig and check the bootstrap progress. Wait for `openshift-install wait-for bootstrap-complete --dir=instlller_dir` before proceeding.
* In the cluster.yaml file, adjust the count of bootstrap nodes ot 0 and the count of worker nodes to >= 2
* Run tofu apply again This will remove the bootstrap node (not needed anymore) and add worker nodes.
* Run `oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve` to approve the worker nodes into the cluster
* Run fetch_worker_backends function and add the back ends to haproxy and remove the bootstrap backend and reload haproxy.
* Wait for `openshift-install wait-for install-complete --dir=instlller_dir`

