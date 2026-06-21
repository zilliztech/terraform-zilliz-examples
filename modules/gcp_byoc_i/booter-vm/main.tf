resource "google_compute_instance" "this" {
  project      = var.gcp_project_id
  name         = local.instance_name
  zone         = var.gcp_zone
  machine_type = var.machine_type
  tags         = ["zilliz-byoc", "zilliz-byoc-booter"]

  labels = merge(
    {
      vendor     = "zilliz-byoc"
      managed_by = "terraform"
      component  = "booter"
    },
    var.labels,
  )

  boot_disk {
    initialize_params {
      image = var.source_image
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
  }

  service_account {
    email  = var.booter_service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    block-project-ssh-keys = "true"
    startup-script         = local.startup_script
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }
}
