{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cp-kafka-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cp-kafka-ui.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cp-kafka-ui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified kafka headless name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "cp-kafka-ui.cp-kafka-headless.fullname" -}}
{{- $name := "cp-kafka-headless" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Form the Kafka URL. If Kafka is installed as part of this chart, use k8s service discovery,
else use user-provided URL
*/}}
{{- define "cp-kafka-ui.kafka.bootstrapServers" -}}
{{- if .Values.kafka.bootstrapServers -}}
{{- .Values.kafka.bootstrapServers -}}
{{- else -}}
{{- printf "PLAINTEXT://%s:9092" (include "cp-kafka-ui.cp-kafka-headless.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Default Server Pool Id to Release Name but allow it to be overridden
*/}}
{{- define "cp-kafka-ui.serviceId" -}}
{{- if .Values.overrideServiceId -}}
{{- .Values.overrideServiceId -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified schema registry name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "cp-kafka-ui.cp-schema-registry.fullname" -}}
{{- $name := default "cp-schema-registry" (index .Values "cp-schema-registry" "nameOverride") -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cp-kafka-ui.cp-schema-registry.service-name" -}}
{{- if (index .Values "cp-schema-registry" "url") -}}
{{- printf "%s" (index .Values "cp-schema-registry" "url") -}}
{{- else -}}
{{- printf "http://%s:8081" (include "cp-kafka-ui.cp-schema-registry.fullname" .) -}}
{{- end -}}
{{- end -}}


{{/*
Create a default fully qualified KSQL server name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "cp-kafka-ui.cp-ksql-server.fullname" -}}
{{- $name := default "cp-ksql-server" (index .Values "cp-ksql-server" "nameOverride") -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cp-kafka-ui.cp-ksql-server.service-name" -}}
{{- if (index .Values "cp-ksql-server" "url") -}}
{{- printf "%s" (index .Values "cp-ksql-server" "url") -}}
{{- else -}}
{{- printf "http://%s:8088" (include "cp-kafka-ui.cp-ksql-server.fullname" .) -}} 
{{- end -}}
{{- end -}}


{{/*
Create a default fully qualified Kafka Connect name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "cp-kafka-ui.cp-kafka-connect.fullname" -}}
{{- $name := default "cp-kafka-connect" (index .Values "cp-kafka-connect" "nameOverride") -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default service URL for Kafka Connect.
*/}}
{{- define "cp-kafka-ui.cp-kafka-connect.service-name" -}}
{{- if (index .Values "cp-kafka-connect" "url") -}}
{{- printf "%s" (index .Values "cp-kafka-connect" "url") -}}
{{- else -}}
{{- printf "http://%s:8083" (include "cp-kafka-ui.cp-kafka-connect.fullname" .) -}}
{{- end -}}
{{- end -}}


