locals {
  instance_name = "${var.prefix_name}-booter"

  boot_config = {
    GCP_PROJECT_ID   = var.gcp_project_id
    GKE_CLUSTER_NAME = var.gke_cluster_name
    GKE_LOCATION     = var.gcp_region
    DATAPLANE_ID     = var.dataplane_id
    AGENT_CONFIG     = jsonencode(var.agent_config)
  }

  startup_script = <<-EOF
    #!/bin/bash
    set -euo pipefail

    echo "zilliz gcp byoc-i booter start"

    mkdir -p /var/lib/zilliz-byoc-i-booter
    cat >/var/lib/zilliz-byoc-i-booter/boot-config.json <<'BOOT_CONFIG'
    ${jsonencode(local.boot_config)}
    BOOT_CONFIG

    until docker info >/dev/null 2>&1; do
      echo "waiting for docker"
      sleep 3
    done

    docker pull '${var.booter_image}'

    set +e
    docker run --rm --network=host \
      -e BOOT_CONFIG="$(cat /var/lib/zilliz-byoc-i-booter/boot-config.json)" \
      -e KUBECTL_PROXY_IMAGE='${var.booter_image}' \
      '${var.booter_image}'
    status=$?
    set -e

    echo "zilliz gcp byoc-i booter result $${status}"

    if [ "$${status}" -eq 0 ]; then
      shutdown -h now
    else
      echo "booter failed; leaving VM running for log inspection"
    fi

    exit "$${status}"
  EOF
}
