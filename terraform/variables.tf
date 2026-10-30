variable "hcloud_token" {
  description = "Hetzner Cloud API token. Pass via TF_VAR_hcloud_token - never commit."
  type        = string
  sensitive   = true
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "pkhosting"
}

variable "server_type" {
  description = "Instance size. Check `hcloud server-type list` - names change over time."
  type        = string
  default     = "cx22"
}

variable "location" {
  description = "Hetzner location"
  type        = string
  default     = "nbg1"
}

variable "image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "ssh_public_key_path" {
  description = "Path to your PUBLIC key (public keys are not secret)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "admin_user" {
  description = "Non-root admin account created at first boot"
  type        = string
  default     = "deploy"
}

variable "allowed_ssh_cidrs" {
  description = "Source ranges allowed to reach SSH on the cloud firewall. Restrict to your IP if it is stable."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}
