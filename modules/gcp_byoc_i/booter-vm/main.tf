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

  dynamic "params" {
    for_each = length(var.resource_manager_tags) > 0 ? [1] : []
    content {
      resource_manager_tags = var.resource_manager_tags
    }
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

resource "terraform_data" "serial_console_log" {
  count = var.print_serial_logs_on_apply ? 1 : 0

  triggers_replace = {
    instance_id        = google_compute_instance.this.id
    startup_script_sha = sha256(local.startup_script)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      INSTANCE_NAME   = local.instance_name
      PROJECT         = var.gcp_project_id
      ZONE            = var.gcp_zone
      TIMEOUT_SECONDS = tostring(var.serial_log_timeout_seconds)
      POLL_SECONDS    = "10"
    }

    command = <<-EOT
      set -uo pipefail

      if ! command -v gcloud >/dev/null 2>&1; then
        echo "gcp-booter serial log: gcloud is not installed; skipping serial log streaming"
        exit 0
      fi

      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "$tmp_dir"' EXIT
      log_file="$tmp_dir/serial.log"
      error_file="$tmp_dir/error.log"
      printed_lines=0
      deadline=$(( $(date +%s) + TIMEOUT_SECONDS ))

      echo "gcp-booter serial log: streaming serial port output for $${INSTANCE_NAME} ($${PROJECT}/$${ZONE})"

      while [ "$(date +%s)" -lt "$deadline" ]; do
        if ! gcloud compute instances get-serial-port-output "$INSTANCE_NAME" \
          --project="$PROJECT" \
          --zone="$ZONE" \
          --port=1 \
          >"$log_file" 2>"$error_file"; then
          err="$(cat "$error_file")"
          if echo "$err" | grep -qiE 'not found|was not found|resource.*notFound'; then
            echo "gcp-booter serial log: instance is no longer available; stopping serial log streaming"
            exit 0
          fi
          echo "gcp-booter serial log: failed to read serial output: $err"
          sleep "$POLL_SECONDS"
          continue
        fi

        total_lines="$(wc -l <"$log_file" | tr -d ' ')"
        if [ "$total_lines" -gt "$printed_lines" ]; then
          tail -n "+$((printed_lines + 1))" "$log_file"
          printed_lines="$total_lines"
        fi

        if grep -qE 'zilliz gcp byoc-i booter attempt [0-9]+ result 0' "$log_file"; then
          echo "gcp-booter serial log: bootstrap success detected"
          exit 0
        fi

        if grep -q 'booter failed after 3 attempts' "$log_file"; then
          echo "gcp-booter serial log: bootstrap failure detected"
          exit 1
        fi

        sleep "$POLL_SECONDS"
      done

      echo "gcp-booter serial log: timed out after $${TIMEOUT_SECONDS}s; continuing without failing apply"
      exit 0
    EOT
  }

  depends_on = [google_compute_instance.this]
}
