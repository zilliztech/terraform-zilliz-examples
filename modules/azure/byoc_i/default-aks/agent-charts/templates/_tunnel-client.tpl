{{- define "cloud-agent.tunnelClient" -}}
- name: tunnel-client
  image: {{ .Values.tunnelClient.image | trim | quote }}
  imagePullPolicy: Always
  env:
    - name: OTEL_TRACES_EXPORTER
      value: none
    - name: OTEL_METRICS_EXPORTER
      value: none
    - name: OTEL_LOGS_EXPORTER
      value: none
    - name: OTEL_SERVICE_NAME
      value: tunnel-client-app
    - name: SPRING_CONFIG_ADDITIONAL_LOCATION
      value: file:///spring-config/application.yml
    - name: SPRING_APPLICATION_NAME
      value: tunnel-client-app
    - name: SERVER_ADDRESS
      value: 127.0.0.1
    - name: SERVER_PORT
      value: "9999"
    - name: BYOC_K8S_KEY
      value: {{ .Values.config.tunnel.authToken | quote }}
  ports:
    - name: tunnel-health
      containerPort: 9999
  readinessProbe:
    exec:
      command:
        - curl
        - --fail
        - --silent
        - --show-error
        - http://127.0.0.1:9999/cloud/check_healthy_db
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 5
  resources:
    limits:
      cpu: 2
      memory: 2Gi
    requests:
      cpu: 1
      memory: 1Gi
  volumeMounts:
    - mountPath: /spring-config
      name: spring-config
{{- end -}}
