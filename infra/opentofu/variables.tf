variable "target_host" {
  description = "The target hostname or IP address for deployment."
  type        = string
  default     = "exonomy.local"
}

variable "target_user" {
  description = "The SSH user for the target host."
  type        = string
  default     = "exocrat"
}

variable "ssh_password" {
  description = "The SSH password (for local dev environments)."
  type        = string
  default     = "."
  sensitive   = true
}

variable "binary_source_path" {
  description = "Path to the compiled conscia binary."
  type        = string
  default     = "../../conscia/target/release/conscia"
}

variable "target_deployment_dir" {
  description = "Directory on the target host to deploy the beacon."
  type        = string
  default     = "~/deployments/conscia/daemon"
}
