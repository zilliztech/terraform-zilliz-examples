# Milvus CMEK for GCP BYOC

This module creates a dedicated customer-project `cseSa` for Milvus CMEK and creates a regional symmetric Cloud KMS key or references an existing key. It is independent from GCS, PD and GKE secrets encryption. Bucket Integration continues to use `storageSa`.

The dedicated `cseSa` receives `roles/cloudkms.cryptoKeyEncrypterDecrypter` and `roles/cloudkms.viewer` on the selected CryptoKey only. The DataPlane's `storageSa` receives `roles/iam.serviceAccountTokenCreator` on `cseSa`, allowing its workload to obtain short-lived credentials for the dedicated CMEK identity. No private key is created. CMEK and Bucket Integration records remain independent; removing a CMEK integration must not delete an identity still needed by encrypted data or backups.

The GCP BYOC-I example exposes `enable_cse` (default false), `gcp_cse_key_name`, and `cse_key_protection_level` (SOFTWARE/HSM). Terraform passes the dedicated `cseSa` and key name to the provider. It grants both key-scoped roles on new and existing keys, so the runner needs permission to update the selected key's IAM policy, even when `manage_iam=false` for other DataPlane resources. Enable Cloud KMS API in the key project and retain the existing Workload Identity setup.

With `enable_cse=false`, this module creates neither a CMEK service account nor a key. Provisioning a DataPlane without a default key and then configuring CMEK from the page requires a separate identity-only path; this module does not currently provide one.

The example requires a provider build that supports the new `gcp.cse` block. Release that provider before publishing/using this example; previously published provider versions do not recognize the new schema. The existing minimum provider version alone is not a sufficient compatibility check for this unreleased feature.

DataPlane bootstrap verifies and registers the default key; individual Milvus clusters must still opt into CMEK through the platform APIs. This does not enable encryption for existing unencrypted clusters. The existing example ignores changes to the `gcp` block: enabling this on an existing DataPlane requires a supported platform configuration upgrade, not just changing tfvars.

New keys have `prevent_destroy`. Removing an integration must not destroy a key, an old key version or an identity needed by instances or backups. Keep these resources until all dependent encrypted data and backups are retired. If an earlier unreleased module was already applied with a dedicated CMEK GSA, do not apply this change blindly: review the Terraform plan and preserve the old GSA and its grants until encrypted instances and backups no longer depend on them. This change does not migrate existing encrypted data or identity records.

Run `terraform init -backend=false` and `terraform test` in this module to execute the mocked-provider tests. They do not create real cloud resources.
