# Azure BYOC-I Milvus CSE

This module configures client-side encryption for Milvus using an **existing AES Key** in Azure Key Vault. It does not configure Storage Account encryption, AKS Secrets encryption or node disk encryption.

When `enabled = false` (the default), it does not read Azure resources or create identities, federated credentials or role assignments. When enabled, it:

1. Checks that the Key URL is versionless, matches the Vault ARM ID, and belongs to the deployment subscription. The Vault can be in another resource group.
2. Reads the existing Vault and requires the Azure RBAC permission model.
3. Reads the Key and requires `oct-HSM` (AES) with both `encrypt` and `decrypt` operations. Zilliz Cloud also verifies Key size, enabled/validity status and actual encryption/decryption before registration.
4. Creates a dedicated user-assigned managed identity in the DataPlane resource group. Storage identities are unchanged.
5. Creates a federated credential for the DataPlane AKS issuer, subject `system:serviceaccount:milvus-tool:milvus-bucket` and audience `api://AzureADTokenExchange`.
6. Assigns **Key Vault Crypto User** to that identity on the target **Key ARM resource**, not the entire Vault or Storage Account. This role provides Key metadata read and cryptographic operations; the integration requires encrypt/decrypt, not wrap/unwrap.

The Key is a Terraform data source, not a managed resource. Applying or destroying this module never creates, rotates or deletes the customer Key. Destroy removes the dedicated identity, federation and Key-scoped role assignment, so existing encrypted instances must be retired before those resources are removed.

## Inputs

| Name | Required | Description |
|---|---|---|
| `enabled` | No | Defaults to `false` |
| `name_prefix` | Yes | Prefix for `<prefix>-cse` managed identity |
| `location` | Yes | DataPlane managed identity location |
| `resource_group_name` | Yes | DataPlane resource group |
| `aks_oidc_issuer_url` | Yes | Actual DataPlane AKS OIDC issuer |
| `key_identifier` | When enabled | `https://<vault>.vault.azure.net/keys/<key>` without a version |
| `key_vault_id` | When enabled | `/subscriptions/<subscription>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>` |
| `tags` | No | Managed identity tags |

The Terraform caller needs management-plane read access to the Vault, data-plane Key read access, permission to create managed identities and federated credentials in the DataPlane resource group, and permission to create role assignments at the target Key scope. A Key's crypto-use permission alone does not permit IAM assignment. The Vault must be reachable by both the deployment environment and DataPlane verification/runtime workloads.

Only public Azure Key Vault URLs are supported. Cross-subscription Keys, Managed HSM endpoints, RSA/EC Keys, access-policy Vaults and new Key creation are outside this module's scope. This module does not modify a Vault's RBAC mode or networking. The existing Vault and Key must already be configured appropriately.

## Validation

```shell
terraform init -backend=false
terraform validate
terraform test
```

Tests require Terraform 1.7 or later and use mocked Azure providers without creating cloud resources. AzureRM exposes the Key type and allowed operations through [`azurerm_key_vault_key`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_key); the service performs the final authenticated AES probe.
