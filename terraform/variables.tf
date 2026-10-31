variable "vpc_id" {
  description = "Existing default VPC in eu-central-1"
  type        = string
  default     = "vpc-05b0d582881900a9a"
}

variable "subnet_ids" {
  description = "Existing subnets in eu-central-1"
  type        = list(string)

  default = [
    "subnet-022ce5386c3fbe97d",
    "subnet-0fc7931a6f037e361",
    "subnet-028788beb150d09aa"
  ]
}

variable "instance_type" {
  description = "EC2 instance type for SkyWatch servers"
  type        = string
  default     = "t3.small"
}

variable "cpu_credits" {
  description = "CPU credit mode for T3 instances"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "CPU credits must be standard or unlimited."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB for each EC2 instance"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Root volume size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  description = "EBS volume type for SkyWatch EC2 root disks"
  type        = string
  default     = "gp3"

  validation {
    condition     = var.root_volume_type == "gp3"
    error_message = "SkyWatch root volumes must use gp3."
  }
}

variable "delete_root_volume_on_termination" {
  description = "Delete the root EBS volume when its EC2 instance is terminated"
  type        = bool
  default     = true
}

variable "server_names" {
  description = "Names of the three SkyWatch EC2 servers"
  type        = list(string)

  default = [
    "skywatch-server-1",
    "skywatch-server-2",
    "skywatch-server-3"
  ]

  validation {
    condition     = length(var.server_names) == 3 && length(distinct(var.server_names)) == 3
    error_message = "SkyWatch requires exactly three unique server names."
  }
}

variable "worker_instance_type" {
  description = "EC2 instance type for SkyWatch worker nodes"
  type        = string
  default     = "t3.small"
}
