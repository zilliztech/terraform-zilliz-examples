# Minimal Roles Configuration

This module supports minimal role configuration through the `minimal_roles` object variable, allowing for flexible role separation and customization while maintaining backward compatibility.

## Variable Structure

```hcl
variable "minimal_roles" {
  description = "Minimal role configuration for EKS role separation and customization"
  type = object({
    # Cluster role configuration
    cluster_role = optional(object({
      enabled = optional(bool, false)
      name    = optional(string, "")
    }), {})
    # Node role configuration  
    node_role = optional(object({
      enabled = optional(bool, false)
      name    = optional(string, "")
    }), {})
  })
  default = {}
}
```

## Usage Examples

### 1. Default Behavior (Unified Role)
```hcl
# Uses the original unified eks_role
minimal_roles = {
  enabled = false
}
```

### 2. Enable Minimal Roles
```hcl
# Creates separate cluster and node roles
minimal_roles = {
  enabled = true
}
```

### 3. Custom Role Names
```hcl
minimal_roles = {
  enabled = true
  cluster_role = {
    name = "my-company-eks-cluster-role"
  }
  node_role = {
    name = "my-company-eks-node-role"
  }
}
```

### 4. Use Existing External Roles
```hcl
minimal_roles = {
  enabled = true
  cluster_role = {
    use_existing_arn = "arn:aws:iam::123456789012:role/my-existing-cluster-role"
  }
  node_role = {
    use_existing_arn = "arn:aws:iam::123456789012:role/my-existing-node-role"
  }
}
```

### 5. Mixed Configuration (Create + External)
```hcl
minimal_roles = {
  enabled = true
  cluster_role = {
    name = "new-cluster-role"  # Create new role
  }
  node_role = {
    use_existing_arn = "arn:aws:iam::123456789012:role/existing-node-role"  # Use existing
  }
}
```

## Role Usage in EKS Resources

### EKS Cluster
- **When `minimal_roles.enabled = false`**: Uses the original unified `eks_role`
- **When `minimal_roles.enabled = true`**: Uses the dedicated `eks_cluster_role`

### EKS Node Groups
- **When `minimal_roles.enabled = false`**: All node groups use the original unified `eks_role`
- **When `minimal_roles.enabled = true`**: All node groups use the dedicated `eks_node_role`

## Role Details

### EKS Cluster Role
- **Purpose**: EKS cluster management only
- **Service Principal**: `eks.amazonaws.com`
- **Policies**:
  - `AmazonEKSClusterPolicy`
  - `AmazonEKSVPCResourceController`
- **Default Name**: `{prefix}-eks-cluster-role`
- **Used by**: EKS cluster resource

### EKS Node Role
- **Purpose**: Worker node operations only
- **Service Principals**: `ec2.amazonaws.com`
- **Policies**:
  - `AmazonEKS_CNI_Policy`
  - `AmazonEC2ContainerRegistryReadOnly`
  - `AmazonEKSWorkerNodePolicy`
  - Custom assume role policy
- **Default Name**: `{prefix}-eks-node-role`
- **Used by**: All EKS node groups (core, search, index, fundamental, init)

## Backward Compatibility

- **Existing customers**: No changes required, existing deployments continue to work
- **Default behavior**: When `minimal_roles = {}`, uses the original unified `eks_role`
- **Gradual migration**: Can enable roles one at a time

## Outputs

When roles are enabled, additional outputs are available:

- `eks_cluster_role`: The EKS cluster role resource (null if not enabled)
- `eks_node_role`: The EKS node role resource (null if not enabled)

## External Role Support

When using external roles via `use_existing_arn`, the module will:
- **Validate** that the external role exists (using `data.aws_iam_role`)
- **Not create** new IAM roles
- **Not attach** policies to external roles
- **Return** the external role information in outputs
- **Assume** the external role has the required permissions

### Role Validation

The module automatically validates external roles by:
1. Parsing the ARN to extract the role name
2. Using `data.aws_iam_role` to verify the role exists
3. Failing with a clear error message if the role doesn't exist

### External Role Requirements

**Cluster Role** should have:
- Trust policy allowing `eks.amazonaws.com` service
- `AmazonEKSClusterPolicy` attached
- `AmazonEKSVPCResourceController` attached

**Node Role** should have:
- Trust policy allowing `ec2.amazonaws.com` services
- `AmazonEKS_CNI_Policy` attached
- `AmazonEC2ContainerRegistryReadOnly` attached
- `AmazonEKSWorkerNodePolicy` attached

## Future Extensibility

The object structure allows for easy extension:

```hcl
# Future extensions could include:
minimal_roles = {
  cluster_role = {
    enabled = true
    name    = "custom-cluster-role"
    # Future: additional_policies = [...]
    # Future: tags = {...}
  }
  node_role = {
    enabled = true
    name    = "custom-node-role"
    # Future: additional_policies = [...]
    # Future: tags = {...}
  }
  # Future: addon_role = {...}
  # Future: storage_role = {...}
}
```

## Role Assignment Logic

The module uses centralized locals variables to handle role selection:

```hcl
# In locals.tf - Unified role selection for EKS resources
# When minimal_roles is enabled, use dedicated roles; otherwise use the original unified role
eks_cluster_role_arn = var.minimal_roles.enabled ? local.eks_cluster_role.arn : local.eks_role.arn
eks_node_role_arn    = var.minimal_roles.enabled ? local.eks_node_role.arn : local.eks_role.arn
```

**EKS Cluster Configuration**:
```hcl
# In eks.tf
role_arn = local.eks_cluster_role_arn
```

**EKS Node Groups Configuration**:
```hcl
# In eks_nodegroup.tf (applies to all node groups)
node_role_arn = local.eks_node_role_arn
```

This centralized approach ensures that:
- **EKS Cluster** uses the appropriate role for cluster management
- **All Node Groups** use the appropriate role for worker node operations
- **Backward Compatibility** is maintained for existing deployments
- **Single Source of Truth** for role selection logic

## Security Benefits

1. **Least Privilege**: Each role only has the permissions it needs
2. **Separation of Concerns**: Cluster management and node operations are isolated
3. **Audit Trail**: Clear distinction between cluster and node activities
4. **Compliance**: Meets security requirements for role separation
5. **Flexibility**: Can enable roles independently based on requirements
