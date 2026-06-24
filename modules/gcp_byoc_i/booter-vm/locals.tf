locals {
  instance_name = var.instance_name

  boot_config = {
    GCP_PROJECT_ID   = var.gcp_project_id
    GKE_CLUSTER_NAME = var.gke_cluster_name
    GKE_LOCATION     = var.gcp_region
    DATAPLANE_ID     = var.dataplane_id
    AGENT_CONFIG     = jsonencode(var.agent_config)
  }

  startup_script = <<-EOF
    #!/bin/bash
    set -uo pipefail

    echo "zilliz gcp byoc-i booter start"

    INSTANCE_NAME='${local.instance_name}'
    ZONE='${var.gcp_zone}'
    PROJECT='${var.gcp_project_id}'
    BOOTER_IMAGE='${var.booter_image}'
    SELF_DELETE_TTL_SECONDS='${var.self_delete_ttl_seconds}'

    mkdir -p /var/lib/zilliz-byoc-i-booter
    cat >/var/lib/zilliz-byoc-i-booter/boot-config.json <<'BOOT_CONFIG'
    ${jsonencode(local.boot_config)}
    BOOT_CONFIG

    cat >/var/lib/zilliz-byoc-i-booter/self-delete.sh <<SELF_DELETE_SCRIPT
    #!/bin/bash
    set -uo pipefail
    INSTANCE_NAME='$${INSTANCE_NAME}'
    ZONE='$${ZONE}'
    PROJECT='$${PROJECT}'

    echo "requesting booter VM self-delete"
    token="\$(curl -fsS -H 'Metadata-Flavor: Google' \\
      'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token' \\
      | sed -n 's/.*"access_token"[ ]*:[ ]*"\\([^"]*\\)".*/\\1/p')"
    if [ -z "\$${token}" ]; then
      echo "failed to get metadata access token for self-delete" >&2
      exit 1
    fi
    curl -fsS -X DELETE \\
      -H "Authorization: Bearer \$${token}" \\
      "https://compute.googleapis.com/compute/v1/projects/\$${PROJECT}/zones/\$${ZONE}/instances/\$${INSTANCE_NAME}" \\
        >/var/lib/zilliz-byoc-i-booter/self-delete-operation.json
    SELF_DELETE_SCRIPT
    chmod +x /var/lib/zilliz-byoc-i-booter/self-delete.sh

    delete_self() {
      echo "requesting booter VM self-delete"
      bash /var/lib/zilliz-byoc-i-booter/self-delete.sh
    }

    schedule_self_delete() {
      delay="$${1}"
      nohup bash -c "sleep '$${delay}'; bash /var/lib/zilliz-byoc-i-booter/self-delete.sh" \
        >/var/log/zilliz-byoc-i-booter-self-delete.log 2>&1 &
    }

    run_booter_once() {
      docker pull "$${BOOTER_IMAGE}" && \
      docker run --rm --network=host \
        -e BOOT_CONFIG="$(cat /var/lib/zilliz-byoc-i-booter/boot-config.json)" \
        -e KUBECTL_PROXY_IMAGE="$${BOOTER_IMAGE}" \
        "$${BOOTER_IMAGE}"
    }

    until docker info >/dev/null 2>&1; do
      echo "waiting for docker"
      sleep 3
    done

    status=1
    for attempt in 1 2 3; do
      echo "zilliz gcp byoc-i booter attempt $${attempt}"
      run_booter_once
      status=$?
      echo "zilliz gcp byoc-i booter attempt $${attempt} result $${status}"

      if [ "$${status}" -eq 0 ]; then
        schedule_self_delete "$${SELF_DELETE_TTL_SECONDS}"
        exit 0
      fi

      if [ "$${attempt}" -lt 3 ]; then
        retry_delay=120
        if [ "$${attempt}" -eq 2 ]; then
          retry_delay=300
        fi
        echo "booter failed; retrying in $${retry_delay}s"
        sleep "$${retry_delay}"
      fi
    done

    echo "booter failed after 3 attempts; deleting VM"
    delete_self || echo "booter VM self-delete failed after bootstrap failure" >&2

    exit "$${status}"
  EOF
}
