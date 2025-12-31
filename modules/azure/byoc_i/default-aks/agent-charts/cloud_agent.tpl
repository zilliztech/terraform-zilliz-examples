image:
  repository: "${repository}"
  tag: "${tag}"
  registrykey: ""

config:
  tunnel:
    serverHost: "${serverHost}"
    authToken: "${authToken}"
    dataPlaneId: "${dataPlaneId}"
    k8sToken: ""
    tunnelHost: "${tunnelHost}"
    ssl: true
    endpointIp: "${endpointIp}"

rbac:
  maintenanceClientId: "${maintenanceClientId}"