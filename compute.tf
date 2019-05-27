data "google_compute_zones" "available" {}

resource "google_compute_instance" "opencart-instance" {
  project      = "${var.project}"
  zone         = "${var.zone}"
  name         = "opencart-instance"
  machine_type = "g1-small"
  tags = ["http-firewall"]

  boot_disk {
    initialize_params {
      image = "opencart-base-image"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${var.ip-address}"
    }
  }

  metadata_startup_script = "${file("deploy_opencart.sh")}"

  metadata {
    ipAddress    = "${var.ip-address}"
    serverAdmin  = "${var.server_admin}"
    serverName   = "${var.server_name}"
    serverAlias  = "${var.server_alias}"
  }
}
