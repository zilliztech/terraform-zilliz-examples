image:
  repository: "${repository}"
  tag: "${tag}"
  registrykey: ""

tunnelClient:
  image: ${jsonencode(tunnelClientImage)}

config:
  tunnel:
    serverHost: "${serverHost}"
    authToken: "${authToken}"
    dataPlaneId: "${dataPlaneId}"
    tunnelHost: "${tunnelHost}"
    ssl: true
    endpointIp: "${endpointIp}"

rbac:
  maintenanceClientId: "${maintenanceClientId}"