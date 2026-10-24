locals {
  servers = {
    for index, name in var.server_names :
    name => {
      subnet_id = var.subnet_ids[index]
    }
  }
}
