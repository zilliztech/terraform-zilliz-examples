image:
  repository: "${repository}"
  tag: "${tag}"
  registrykey: ""

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