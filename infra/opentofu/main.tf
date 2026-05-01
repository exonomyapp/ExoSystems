terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

provider "null" {}

resource "null_resource" "conscia_deployment" {
  # Triggers when the binary hash changes
  triggers = {
    binary_hash = filemd5(var.binary_source_path)
  }

  # Ensure the target directory exists
  provisioner "local-exec" {
    command = "sshpass -p '${var.ssh_password}' ssh -o StrictHostKeyChecking=no ${var.target_user}@${var.target_host} 'mkdir -p ${var.target_deployment_dir}'"
  }

  # Copy the binary
  provisioner "local-exec" {
    command = "sshpass -p '${var.ssh_password}' scp -o StrictHostKeyChecking=no ${var.binary_source_path} ${var.target_user}@${var.target_host}:${var.target_deployment_dir}/conscia"
  }

  # Restart the systemd service
  provisioner "local-exec" {
    command = "sshpass -p '${var.ssh_password}' ssh -o StrictHostKeyChecking=no ${var.target_user}@${var.target_host} 'sudo systemctl restart conscia'"
  }
}
