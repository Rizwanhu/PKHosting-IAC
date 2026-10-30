provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "admin" {
  name       = "${var.name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Cloud-level firewall = first layer. UFW on the host is the second layer.
resource "hcloud_firewall" "web" {
  name = "${var.name}-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_ssh_cidrs
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "web" {
  name         = "${var.name}-web"
  server_type  = var.server_type
  image        = var.image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.web.id]

  # cloud-init creates the non-root admin user on first boot, so Ansible
  # never needs to log in as root.
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    admin_user = var.admin_user
    pubkey     = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })

  labels = { project = var.name, managed_by = "terraform" }
}
