locals {
  cluster_spec = yamldecode(file("cluster.yaml"))
}


resource "oxide_disk" "bootstrap_node_disk" {
  count           = local.cluster_spec.boot.count
  project_id      = local.cluster_spec.project_id
  description     = "Disk of bootstrap node ${count.index+1}"
  name            = "boot-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  size            = local.cluster_spec.boot.disk_size
  source_image_id = local.cluster_spec.boot.image_id
  timeouts = {
    read   = "1m"
    create = "3m"
    delete = "2m"
  }
}

resource "oxide_instance" "bootstrap" {
  count                = local.cluster_spec.boot.count
  project_id           = local.cluster_spec.project_id
  description          = "Openshift bootstrap node ${count.index+1}"
  name                 = "boot-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  host_name            = "boot-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  memory               = local.cluster_spec.boot.memory
  ncpus                = local.cluster_spec.boot.ncpus
  disk_attachments     = [oxide_disk.bootstrap_node_disk[count.index].id]
  network_interfaces = [
    {
      subnet_id   = local.cluster_spec.subnet_id
      vpc_id      = local.cluster_spec.vpc_id
      description = "Primary interface"
      name        = "primary"
    },
  ]
}

resource "oxide_disk" "cp_node_disk" {
  count           = local.cluster_spec.cp.count
  project_id      = local.cluster_spec.project_id
  description     = "Disk of control plane node ${count.index+1}"
  name            = "cp-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  size            = local.cluster_spec.cp.disk_size
  source_image_id = local.cluster_spec.cp.image_id
  timeouts = {
    read   = "1m"
    create = "3m"
    delete = "2m"
  }
}

resource "oxide_instance" "cp" {
  count                = local.cluster_spec.cp.count
  project_id           = local.cluster_spec.project_id
  description          = "Openshift control plane node ${count.index+1}"
  name                 = "cp-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  host_name            = "cp-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  memory               = local.cluster_spec.cp.memory
  ncpus                = local.cluster_spec.cp.ncpus
  disk_attachments     = [oxide_disk.cp_node_disk[count.index].id]
  network_interfaces = [
    {
      subnet_id   = local.cluster_spec.subnet_id
      vpc_id      = local.cluster_spec.vpc_id
      description = "Primary interface"
      name        = "primary"
    },
  ]
}

resource "oxide_disk" "worker_node_disk" {
  count           = local.cluster_spec.worker.count
  project_id      = local.cluster_spec.project_id
  description     = "Disk of worker node ${count.index+1}"
  name            = "worker-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  size            = local.cluster_spec.worker.disk_size
  source_image_id = local.cluster_spec.worker.image_id
  timeouts = {
    read   = "1m"
    create = "3m"
    delete = "2m"
  }
}

resource "oxide_instance" "worker" {
  count                = local.cluster_spec.worker.count
  project_id           = local.cluster_spec.project_id
  description          = "Openshift worker node ${count.index+1}"
  name                 = "worker-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  host_name            = "workercp-${count.index+1}-${local.cluster_spec.normalized_cluster_domain}"
  memory               = local.cluster_spec.worker.memory
  ncpus                = local.cluster_spec.worker.ncpus
  disk_attachments     = [oxide_disk.worker_node_disk[count.index].id]
  network_interfaces = [
    {
      subnet_id   = local.cluster_spec.subnet_id
      vpc_id      = local.cluster_spec.vpc_id
      description = "Primary interface"
      name        = "primary"
    },
  ]
}
