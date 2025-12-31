# Azure BYOC Project - Modular Configuration

This example demonstrates a **modular and extensible** Azure BYOC infrastructure configuration, designed for easy extension and modification.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│              Modular Configuration Structure              │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  variables.tf │  │  locals.tf   │  │   main.tf    │  │
│  │  (Input)      │→ │  (Process)   │→ │  (Execute)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Module Configurations (locals.tf)         │  │
│  │  • vnet_config                                    │  │
│  │  • storage_config                                 │  │
│  │  • private_endpoint_config                        │  │
│  │  • aks_config                                     │  │
│  │  • network_security                               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Key Features

### 1. **Modular Configuration Structure**
   - Configuration organized by module (VNet, Storage, Private Endpoint, AKS)
   - Each module has its own configuration object in `locals.tf`
   - Easy to extend with new modules or modify existing ones

### 2. **Abstraction Layer**
   - `locals.tf` provides a clean abstraction layer
   - Separates user input (`variables.tf`) from module execution (`main.tf`)
   - Default values and computed values handled in `locals.tf`

### 3. **Extensible Design**
   - Add new modules by:
     1. Adding variable definition in `variables.tf`
     2. Adding configuration in `locals.tf`
     3. Adding module call in `main.tf`
   - No need to modify existing code

### 4. **Type Safety**
   - All configurations use strongly-typed objects
   - Optional fields with defaults for flexibility
   - Validation rules in variable definitions

## File Structure

```
azure-project-byoc-I/
├── main.tf              # Module execution (calls Azure modules)
├── variables.tf         # Input variable definitions (user-facing)
├── locals.tf            # Configuration abstraction layer
├── outputs.tf           # Output values
├── provider.tf          # Provider configuration
├── terraform.tfvars.json # Example configuration
└── README.md            # This file
```

## Configuration Structure

### Variables (`variables.tf`)

Variables are organized by module. **VNet and Storage configurations are simplified**:

```hcl
variable "vnet" {
  description = "VNet configuration - CIDR is required, all else uses defaults"
  type = object({
    cidr = string  # Required: CIDR block for the virtual network
    custom_subnets = optional(map(object({...})), {})
  })
  nullable = false
}

variable "storage" {
  description = "Storage Account configuration - name is required, all else uses defaults"
  type = object({
    name = string  # Required: Storage account name
    # ... other optional fields
  })
  nullable = false
}
```

**Default VNet Settings:**
- `auto_split_subnets = true` (automatic subnet splitting)
- `create_nat_gateway = true` (NAT Gateway for outbound access)
- Uses Azure-provided DNS by default

**Default Storage Settings:**
- `network_default_action = "Allow"` (allows all VNet subnets)
- `public_network_access_enabled = true`
- `account_tier = "Standard"`, `account_replication_type = "RAGRS"`

### Locals (`locals.tf`)

Each module has a configuration object with sensible defaults:

```hcl
locals {
  vnet_config = {
    name                = "${local.name_prefix}-vnet"
    location            = var.location
    cidr                = var.vnet.cidr  # CIDR is now in vnet object
    auto_split_subnets  = true  # Always enabled by default
    create_nat_gateway  = true  # Always created by default
    # Uses Azure-provided DNS by default
    custom_subnets      = try(var.vnet.custom_subnets, {})
    # ... other defaults
  }
}
```

### Main (`main.tf`)

Modules are called using local configurations:

```hcl
module "vnet" {
  source = "../../modules/azure/byoc_i/default-virtual-networks"
  
  vnet_name = local.vnet_config.name
  # ... uses local.vnet_config
}
```

## Usage Examples

### Minimal Configuration (Recommended)

Only specify CIDR, storage account name, and AKS node pools - all other options use defaults:

```json
{
  "name": "my-project",
  "location": "East US",
  "resource_group_name": "rg-my-project",
  "vnet": {
    "cidr": "10.0.0.0/16"
  },
  "storage": {
    "name": "mystorageaccount"
  },
  "enable_private_link": true,
  "private_endpoint": {
    "name": "storage-pe"
  },
  "aks": {
    "node_pools": []
  }
}
```

### Disable Private Link

To disable Private Endpoint creation:

```json
{
  "enable_private_link": false
  // private_endpoint object not needed when disabled
}
```

**Default VNet Behavior:**
- ✅ Auto-split subnets enabled (creates milvus, privatelink, default, GatewaySubnet)
- ✅ NAT Gateway created for outbound internet access
- ✅ Azure-provided DNS (168.63.129.16)
- ✅ All subnets include Microsoft.Storage service endpoints
- ✅ VNet-internal traffic allowed, public internet disabled by default

**Default Storage Account Behavior:**
- ✅ Allows access from all VNet subnets
- ✅ Public network access enabled
- ✅ Standard tier with RAGRS replication

**Default Private Endpoint Behavior (when enable_private_link=true):**
- ✅ Connects to Storage Account blob and file services
- ✅ Creates Private DNS Zones automatically
- ✅ Links DNS zones to VNet for automatic resolution
- ✅ Uses privatelink subnet by default
- ⚠️ Set `enable_private_link=false` to disable Private Endpoint creation

### Custom Subnet Configuration

Only specify what you need to customize:

```json
{
  "vnet": {
    "cidr": "10.0.0.0/16",
    "custom_subnets": {
      "milvus": {
        "public_support": true  // Enable outbound HTTPS/443
      }
    }
  },
  "storage": {
    "name": "mystorageaccount"
  },
  "enable_private_link": true,
  "private_endpoint": {
    "name": "storage-pe"
    // All other options use defaults: ["blob", "file"], DNS zones auto-created
  }
}
```

### Custom Storage Configuration

```json
{
  "storage": {
    "account_tier": "Premium",
    "account_replication_type": "LRS",
    "network_default_action": "Allow",
    "allowed_subnet_names": ["milvus", "default", "privatelink"]
  }
}
```

### AKS Configuration

Only `node_pools` is required - all other options use defaults:

```json
{
  "aks": {
    "node_pools": [
      {
        "name": "infra",
        "vm_size": "Standard_D8as_v5",
        "node_count": 2,
        "min_count": 2,
        "max_count": 2,
        "enable_auto_scaling": false,
        "os_disk_size_gb": 256,
        "os_disk_type": "Managed",
        "node_labels": {
          "node-group": "infra"
        },
        "node_taints": []
      }
    ]
  }
}
```

**Default AKS Settings:**
- `kubernetes_version`: Latest available version
- `service_cidr`: `10.255.0.0/16` (default, can be overridden)
- `subnet_name`: `milvus`
- `default_node_pool`: `Standard_D4as_v5` (1-5 nodes, auto-scaling enabled, zones 1-3)

## Extending the Configuration

### Adding a New Module

1. **Add variable definition** (`variables.tf`):
```hcl
variable "new_module" {
  description = "New module configuration"
  type = object({
    enabled = optional(bool, true)
    # ... other options
  })
  default = {}
}
```

2. **Add configuration** (`locals.tf`):
```hcl
locals {
  new_module_config = {
    enabled = try(var.new_module.enabled, true)
    # ... merge with defaults
  }
}
```

3. **Add module call** (`main.tf`):
```hcl
module "new_module" {
  source = "../../modules/azure/new-module"
  
  # Use local.new_module_config
}
```

### Modifying Existing Modules

Simply update the configuration object in `locals.tf`:

```hcl
locals {
  vnet_config = {
    # Add new fields or modify existing ones
    new_field = try(var.vnet.new_field, "default")
  }
}
```

## Benefits of This Structure

1. **Separation of Concerns**
   - Input (variables) → Processing (locals) → Execution (main)
   - Clear separation makes code easier to understand and maintain

2. **Easy Extension**
   - Add new modules without touching existing code
   - Modify configurations without changing module calls

3. **Default Values**
   - Sensible defaults in `locals.tf`
   - Users only need to specify what they want to change

4. **Type Safety**
   - Strong typing prevents configuration errors
   - IDE autocomplete works better with object types

5. **Documentation**
   - Configuration structure is self-documenting
   - Clear variable descriptions explain each option

## Best Practices

1. **Use `try()` for optional fields**: `try(var.module.field, default)`
2. **Group related configs**: Keep module configs together in `locals.tf`
3. **Provide sensible defaults**: Make common use cases easy
4. **Document complex configs**: Add comments for non-obvious logic
5. **Validate inputs**: Use validation blocks in variable definitions

## Migration from Flat Structure

If migrating from a flat variable structure:

1. Group related variables into objects
2. Move default logic to `locals.tf`
3. Update `main.tf` to use local configurations
4. Update `terraform.tfvars.json` to use nested objects

Example:
```hcl
# Before
variable "vnet_cidr" { default = "10.0.0.0/16" }
variable "create_nat_gateway" { default = true }

# After
variable "vnet" {
  type = object({
    cidr = optional(string, "10.0.0.0/16")
    create_nat_gateway = optional(bool, true)
  })
  default = {}
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |

## Related Modules

- [default-virtual-networks](../../modules/azure/byoc_i/default-virtual-networks/README.md)
- [default-storageaccount](../../modules/azure/byoc_i/default-storageaccount/README.md)
- [default-storage-identity](../../modules/azure/byoc_i/default-storage-identity/README.md)
- [default-privatelink](../../modules/azure/byoc_i/default-privatelink/README.md)
- [default-aks](../../modules/azure/byoc_i/default-aks/README.md)
