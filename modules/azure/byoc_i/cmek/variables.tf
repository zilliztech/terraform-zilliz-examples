variable "enabled" {
  description = "Enable Milvus client-side encryption using an existing Azure AES Key."
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix for the dedicated CSE managed identity."
  type        = string
}

variable "location" {
  description = "Azure location of the DataPlane managed identity."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the CSE managed identity."
  type        = string
}

variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the DataPlane AKS cluster."
  type        = string
}

variable "key_identifier" {
  description = "Existing versionless public Azure Key Vault Key URL: https://<vault>.vault.azure.net/keys/<key>."
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "ARM resource ID of the existing Key Vault. It may be in a different resource group."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for the CSE managed identity."
  type        = map(string)
  default     = {}
}
