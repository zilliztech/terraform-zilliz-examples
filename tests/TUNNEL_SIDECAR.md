# BYOC-I tunnel sidecar deployment

New Data Planes use split containers when the settings API returns a non-empty
`op_config.tunnel_client_image_url` (from the global
`byoc_tunnel_client_image_url` setting). Missing/null/empty values retain the
legacy deployment. Set this together with a matching split cloud-agent image;
an old embedded-tunnel agent must not run alongside the sidecar.

## Required releases

1. Release the Terraform provider change exposing
   `op_config.tunnel_client_image_url` on BYOC-I settings. These examples reference
   the field directly so an older provider fails validation instead of silently
   discarding an enabled split configuration. Upgrade the provider lock file with
   `terraform init -upgrade` after the containing provider release is available.
   No unreleased provider version is assumed here.
2. Publish the updated AWS booter image from `paas-deploy/bootstrap` and GCP booter
   image from `zilliz-cloud/infra/gcp-booter` to each target registry. Terraform's
   booter image selection must reference those builds.
3. Publish matching cloud-agent and cloud-tunnel-client images to the selected
   region/customer registry, then configure the global agent and tunnel tags.
4. Use these updated Terraform modules/examples for new Data Planes. Azure embeds
   the chart in `agent-context.zip`, which is updated with the source chart here.

AWS passes the API value through `agent_config.tunnel_client_tag` to the booter.
GCP resolves it into `agent_config.tunnel_client_image`, honoring the custom image
repository and retaining full references when there is no override. Azure passes
`tunnel_client_tag` into its chart and resolves tags against the configured ACR.

The sidecar shares the corresponding primary/backup ConfigMap, listens on
`127.0.0.1:9999`, and uses the same CPU/memory resources as cloud-agent. It keeps
the existing `/cloud/check_healthy_db` readiness contract; this endpoint does not
prove that the remote tunnel is authenticated. Main and backup retain `srvNo`
1 and 2. Split Deployments use Recreate and preserve the original selector and Pod labels.

This change targets new deployments. Existing Data Planes are upgraded manually
through the established procedure. It is not an automatic fleet migration.

## Offline validation

Requires Terraform, Helm, Python 3 and PyYAML. No cloud access is performed.

```sh
python3 tests/test_tunnel_sidecar.py
```

The checks render legacy/split Azure Deployments, compare uploaded ZIP contents
and rendering against source, and evaluate the actual GCP Terraform image
expressions for missing values, tags, full references and custom registries.
