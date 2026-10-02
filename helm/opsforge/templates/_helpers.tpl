{{- define "opsforge.name" -}}opsforge{{- end -}}
{{- define "opsforge.labels" -}}
app.kubernetes.io/name: {{ include "opsforge.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
