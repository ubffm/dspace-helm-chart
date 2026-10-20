{{/*
Copyright 2025-, UB JCS, Goethe University Frankfurt am Main

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.

SPDX-License-Identifier: MPL-2.0
*/}}

{{/* A set of labels that all resource from this chart share */}}
{{- define "dspace.commonLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* The kubernetes label for the specified component */}}
{{- define "dspace.componentLabel" -}}
app.kubernetes.io/component: {{ . }}
{{- end -}}

{{/* Node tolerations that allow the deployment to be picked up by a node in the target cluster */}}
{{- define "dspace.clusterTolerations" -}}
{{- if .Values.tolerationKey -}}
tolerations:
  - effect: NoSchedule
    key: {{ .Values.tolerationKey }}
    operator: Equal
    value: 'true'
{{- end -}}
{{- end -}}

{{/* Pull Secret if specified */}}
{{- define "dspace.imagePullSecret" -}}
{{- if .Values.imagePullSecret -}}
imagePullSecrets:
  - name: {{ .Values.imagePullSecret }}
{{- end -}}
{{- end -}}

{{/* Cluster Internal Domain Name for the frontend*/}}
{{- define "dspace.frontendServiceInternalDomain" -}}
{{ .Release.Name }}-frontend.{{ .Values.namespace }}.svc.cluster.local
{{- end -}}

{{/* Cluster Internal Domain Name for the backend*/}}
{{- define "dspace.backendServiceInternalDomain" -}}
{{ .Release.Name }}-backend.{{ .Values.namespace }}.svc.cluster.local
{{- end -}}

{{/* Cluster Internal Domain Name for the proxy */}}
{{- define "dspace.proxyServiceInternalDomain" -}}
{{ .Release.Name }}-proxy.{{ .Values.namespace }}.svc.cluster.local
{{- end -}}

{{/* Cluster Internal Domain Name for the database */}}
{{- define "dspace.databaseServiceInternalDomain" -}}
{{ .Release.Name }}-database.{{ .Values.namespace }}.svc.cluster.local
{{- end -}}

{{/* Cluster Internal Domain Name for Cantaloupe */}}
{{- define "dspace.cantaloupeServiceInternalDomain" -}}
{{ .Release.Name }}-iiif.{{ .Values.namespace }}.svc.cluster.local
{{- end -}}

{{/* URL with protocol */}}
{{- define "dspace.fullURL" -}}
{{ .Values.hostProtocol }}://{{ .Values.host }}
{{- end -}}

{{/* DB must be set manually if an existing DB is used, else it is constructed from the service DNS */}}
{{- define "dspace.databaseConnectionString" -}}
{{ default (print "jdbc:postgresql://" (include "dspace.databaseServiceInternalDomain" . ) ":5432/" .Values.dbDatabaseName ) .Values.dbUrl }}
{{- end -}}

{{/* Solr must be set manually if an existing Solr instance is used, else it is constructed from the service DNS */}}
{{- define "dspace.solrConnectionString" -}}
{{ default (print "http://" .Release.Name "-solr." .Values.namespace ".svc.cluster.local:8983/solr" ) .Values.solrUrl }}
{{- end -}}
