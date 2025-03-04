apiVersion: v1
kind: Config
preferences: {}
current-context: ${cluster_name}

clusters:
- cluster:
    certificate-authority-data: ${cluster_ca_data}
    server: ${cluster_endpoint}
  name: ${cluster_name}

contexts:
- context:
    cluster: ${cluster_name}
    user: service-account
  name: ${cluster_name}

users:
- name: service-account
  user:
    token: ${service_account_token} 