locals {
  servers = {
    for index, name in var.server_names :
    name => {
      subnet_id     = var.subnet_ids[index]
      instance_type = index == 0 ? var.instance_type : var.worker_instance_type
    }
  }
}
