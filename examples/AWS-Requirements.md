# Requirements for Deploying BYOC in AWS

### VPC High Availability and Best Practices

To ensure high availability, Zilliz recommends deploying resources across at least three availability zones. This approach helps to achieve fault tolerance and minimizes the risk of service disruption.

1. **S3 Endpoint Configuration**:
   - Configure an S3 VPC endpoint to allow private access to Amazon S3 without traversing the public internet.

2. **Private Subnet Tagging**:
   - Tag private subnets with `kubernetes.io/role/internal-elb=1` to enable the use of internal Application Load Balancers (ALBs).

3. **Tags for Resources**:
   - Tag all VPC subnets and other resources with the following tag to ensure proper identification and management:
     - `Vendor = "zilliz-byoc"`
4. security group rules:
   - Ensure that security groups are configured to allow all traffic within the VPC.
   - Allow egress traffic on port 443 (HTTPS) to the internet to enable secure communication.
     - For **Private Link Mode**: This configuration is not required.
      

### Private EKS Cluster Support
To support a private EKS cluster, follow the guidelines outlined in the [AWS EKS Private Clusters Documentation](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html):

1. **Private API Server Endpoint**:
   - Enable the private API server endpoint for the EKS cluster.
   - Disable the public API server endpoint to restrict access.

2. **VPC Endpoints**:
   - Ensure the following VPC endpoints are configured:
     - `com.amazonaws.[region].ec2`
     - `com.amazonaws.[region].ecr.api`
     - `com.amazonaws.[region].ecr.dkr`
     - `com.amazonaws.[region].s3`
     - `com.amazonaws.[region].elasticloadbalancing`
     - `com.amazonaws.[region].xray`
     - `com.amazonaws.[region].logs`
     - `com.amazonaws.[region].sts`
     - `com.amazonaws.[region].eks_auth`
     - `com.amazonaws.[region].eks`
     - `com.amazonaws.[region].autoscaling`

3. **Tags for Resources**:
   - Tag all resources with the following tag to ensure they are managed by Zilliz:
      - `Vendor = "zilliz-byoc"`