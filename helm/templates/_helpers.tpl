{{/* vim: set filetype=mustache: */}}


{{- define "toNormalString" -}}
{{ printf "%s" (. | toString | replace "+" "_" | trunc 63 | trimSuffix "-" | quote) }}
{{- end }}


### Deployment ###

{{/*
GCXI version
*/}}
{{- define "gcxiVersion" }}
{{- if .Values.gcxi.deployment.gcxiVersion }}
{{- printf "%s" (.Values.gcxi.deployment.gcxiVersion) }}
{{- else }}
{{- printf "%s" (.Chart.AppVersion) }}
{{- end }}
{{- end }}

{{/*
Create a deploymentCode
*/}}
{{- define "deploymentCode" }}
{{- if .Values.gcxi.deployment.code }}
{{- printf "-%s" (.Values.gcxi.deployment.code | toString | replace "+" "_" | trunc 63 | trimSuffix "-") }}
{{- else if eq .Values.gcxi.deployment.type "azure" }}
{{- printf "-%s-%s" (.Values.gcxi.deployment.tenantId | toString | replace "+" "_" | trunc 63 | trimSuffix "-") (.Values.gcxi.deployment.tenantColor | toString | replace "+" "_" | trunc 63 | trimSuffix "-") }}
{{- end }}
{{- end }}


{{/*
Create a deploymentUrl
*/}}
{{- define "deploymentUrl" }}
{{- if .Values.gcxi.deployment.tenantName }}
{{- printf "%s-%s-%s" (.Values.gcxi.deployment.tenantName | toString | replace "+" "_" | trunc 63 | trimSuffix "-") "gcxi" (.Values.gcxi.deployment.tenantColor | toString | replace "+" "_" | trunc 63 | trimSuffix "-") }}
{{- else }}
{{- printf "%s%s" "gcxi" (include "deploymentCode" .) }}
{{- end }}
{{- end }}


{{/*
Create a globalCode
*/}}
{{- define "globalCode" }}
{{- if .Values.gcxi.deployment.globalCode }}
{{- printf "-%s" (.Values.gcxi.deployment.globalCode | toString | replace "+" "_" | trunc 63 | trimSuffix "-") }}
{{- else if eq .Values.gcxi.deployment.type "azure" }}
{{- printf "-%s" (.Values.gcxi.deployment.tenantId | toString | replace "+" "_" | trunc 63 | trimSuffix "-") }}
{{- end }}
{{- end }}


{{/*
Create a globalUrl
*/}}
{{- define "globalUrl" }}
{{- if .Values.gcxi.deployment.tenantName }}
{{- printf "%s-%s" (.Values.gcxi.deployment.tenantName | toString | replace "+" "_" | trunc 63 | trimSuffix "-") "gcxi" }}
{{- else }}
{{- printf "%s%s" "gcxi" (include "globalCode" .) }}
{{- end }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "gcxi.labels" -}}
helm.sh/chart: {{ include "toNormalString" (printf "%s-%s" .Chart.Name .Chart.Version) }}
{{- if .Values.gcxi.deployment.tenantId }}
app.kubernetes.io/component: {{ include "toNormalString" .Values.gcxi.deployment.tenantId }}
{{- end }}
app.kubernetes.io/instance: {{ include "toNormalString" (printf "%s-%s" .Chart.Name .Chart.AppVersion) }}
app.kubernetes.io/managed-by: {{ include "toNormalString" .Release.Service }}
app.kubernetes.io/name: {{ include "toNormalString" .Chart.Name }}
app.kubernetes.io/part-of: {{ include "toNormalString" .Chart.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ include "toNormalString" .Chart.AppVersion }}
{{- end }}
{{- if eq .Values.gcxi.deployment.deployMain true }}
gcxi/deployment-code: gcxi{{ include "deploymentCode" . }}
{{- else }}
gcxi/deployment-code: gcxi{{ include "globalCode" . }}
{{- end }}
gcxi/global-code: gcxi{{ include "globalCode" . }}
service: gcxi
servicename: gcxi
{{- if .Values.gcxi.deployment.tenantId }}
tenant: {{ include "toNormalString" .Values.gcxi.deployment.tenantId }}
{{- end }}
{{- end -}}


### Images ###

{{/*
Image repo name
*/}}
{{- define "imageRepo" }}
{{- if .Values.gcxi.images.repository }}
{{- tpl .Values.gcxi.images.repository . }}/
{{- end }}
{{- end }}


{{/*
Create an image pull secret
*/}}
{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.gcxi.imageCredentials.registry (printf "%s:%s" .Values.gcxi.imageCredentials.username .Values.gcxi.imageCredentials.password | b64enc) | b64enc }}
{{- end }}


### Ingress ###


{{/*
Generate external domain name
*/}}
{{- define "extDomain" }}
{{- if .Values.gcxi.ingress.external.domain }}
{{- printf "%s" (tpl .Values.gcxi.ingress.external.domain .) }}
{{- else if .Values.gcxi.ingress.domain }}
{{- printf "%s" (tpl .Values.gcxi.ingress.domain .) }}
{{- end }}
{{- end }}


{{/*
Generate internal domain name
*/}}
{{- define "intDomain" }}
{{- if .Values.gcxi.ingress.internal.domain }}
{{- printf "%s" (tpl .Values.gcxi.ingress.internal.domain .) }}
{{- else if .Values.gcxi.ingress.domain }}
{{- printf "%s" (tpl .Values.gcxi.ingress.domain .) }}
{{- end }}
{{- end }}


{{/*
Generate external host name
*/}}
{{- define "extHost" }}
{{- $domain := (include "extDomain" .) }}
{{- if .Values.gcxi.ingress.external.host }}
{{- printf "%s" (tpl .Values.gcxi.ingress.external.host .) }}
{{- else if $domain }}
{{- if eq (.Values.gcxi.deployment.deployMain | default false) true }}
{{- printf "%s%s.%s" (include "deploymentUrl" .) (.Values.gcxi.ingress.external.suffix | default "") $domain }}
{{- else }}
{{- printf "%s%s.%s" (include "globalUrl" .) (.Values.gcxi.ingress.external.suffix | default "") $domain }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Generate internal host name
*/}}
{{- define "intHost" }}
{{- $domain := (include "intDomain" .) }}
{{- if .Values.gcxi.ingress.internal.host }}
{{- printf "%s" (tpl .Values.gcxi.ingress.internal.host .) }}
{{- else if $domain }}
{{- if eq (.Values.gcxi.deployment.deployMain | default false) true }}
{{- printf "%s%s.%s" (include "deploymentUrl" .) (.Values.gcxi.ingress.internal.suffix | default "") $domain }}
{{- else }}
{{- printf "%s%s.%s" (include "globalUrl" .) (.Values.gcxi.ingress.internal.suffix | default "") $domain }}
{{- end }}
{{- end }}
{{- end }}


{{/*
External URL for MSTR Library app
*/}}
{{- define "mstrExtUrl" }}
{{- $domain := (include "extDomain" .) }}
{{- if .Values.gcxi.env.MSTR_EXTURL }}
{{- .Values.gcxi.env.MSTR_EXTURL }}
{{- else if $domain }}
{{- printf "%s://%s.%s" (.Values.gcxi.deployment.urlProto) (include "globalUrl" .) $domain }}
{{- end }}
{{- end }}


### CSI Mounts ###

{{/*
CSI GCXI Secrets Mount
*/}}
{{- define "mntSecretGCXI" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretGCXI | default false) true }}
- mountPath: /genesys/gcxi/var/META_DB_PASSWORD
  name: gcxi-var-metadb-pwd
  readOnly: true
- mountPath: /genesys/gcxi/var/META_HIST_PASSWORD
  name: gcxi-var-histdb-pwd
  readOnly: true
- mountPath: /genesys/gcxi/var/MSTR_PASSWORD
  name: gcxi-var-mstr-pwd
  readOnly: true
- mountPath: /genesys/gcxi/var/TOMCAT_ADMINPWD
  name: gcxi-var-tomcat-pwd
  readOnly: true
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI GIM Secrets Mount
*/}}
{{- define "mntSecretGIM" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretGIM | default false) true }}
- mountPath: /genesys/gcxi/var/GCXI_GIM_DB__DATA
  name: gcxi-var-gim
  readOnly: true
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI GWS Secrets Mount
*/}}
{{- define "mntSecretGWS" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretGWS | default false) true }}
- mountPath: /genesys/gcxi/var/GAUTH_CLIENT
  name: gcxi-var-gws-client-id
  readOnly: true
- mountPath: /genesys/gcxi/var/GAUTH_KEY
  name: gcxi-var-gws-client-secret
  readOnly: true
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI iWD Secrets Mount
*/}}
{{- define "mntSecretIWD" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretIWD | default false) true }}
- mountPath: /genesys/gcxi/var/IWD_DB__PASSWORD
  name: gcxi-var-iwd
  readOnly: true
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI MSTR License Secrets Mount
*/}}
{{- define "mntSecretMSTRLicense" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretMSTRLicense | default false) true }}
- mountPath: /genesys/gcxi/var/MSTR_LICENSE
  name: gcxi-var-mstr-license
  readOnly: true
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI Postgres Admin Secrets Mount
*/}}
{{- define "mntSecretPG" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretPG | default false) true }}
- mountPath: /genesys/gcxi/var/META_DB_ADMINPWD
  name: gcxi-var-pg-admin-password
  readOnly: true
- mountPath: /genesys/gcxi/var/META_DB_ADMIN
  name: gcxi-var-pg-admin-username
  readOnly: true
{{- end }}
{{- end }}
{{- end }}


### CSI Volumes ###

{{/*
CSI GCXI Secret Volume
*/}}
{{- define "csiSecretGCXI" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretGCXI | default false) true }}
- name: gcxi-var-metadb-pwd
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-metadb-pwd-{{.Values.gcxi.deployment.tenantId}}-{{.Values.gcxi.deployment.tenantColor}}
- name: gcxi-var-histdb-pwd
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-histdb-pwd-{{.Values.gcxi.deployment.tenantId}}-{{.Values.gcxi.deployment.tenantColor}}
- name: gcxi-var-mstr-pwd
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-mstr-pwd-{{.Values.gcxi.deployment.tenantId}}-{{.Values.gcxi.deployment.tenantColor}}
- name: gcxi-var-tomcat-pwd
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-tomcat-pwd-{{.Values.gcxi.deployment.tenantId}}-{{.Values.gcxi.deployment.tenantColor}}
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI GIM Secret Volume
*/}}
{{- define "csiSecretGIM" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretGIM | default false) true }}
- name: gcxi-var-gim
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ tpl .Values.gcxi.env.GCXI_GIM_DB.SECRET . }}
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI GWS Secret Volume
*/}}
{{- define "csiSecretGWS" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretGWS | default false) true }}
- name: gcxi-var-gws-client-id
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-gws-client-id
- name: gcxi-var-gws-client-secret
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-gws-client-secret
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI iWD Secret Volume
*/}}
{{- define "csiSecretIWD" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretIWD | default false) true }}
- name: gcxi-var-iwd
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ tpl .Values.gcxi.env.IWD_DB.SECRET . }}
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI MSTR License Secret Volume
*/}}
{{- define "csiSecretMSTRLicense" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretMSTRLicense | default false) true }}
- name: gcxi-var-mstr-license
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-mstr-license
{{- end }}
{{- end }}
{{- end }}


{{/*
CSI Postgres Config Volume
*/}}
{{- define "csiSecretPG" }}
{{- if eq (.Values.gcxi.deployment.useCSISecrets | default false) true }}
{{- if eq (.Values.gcxi.deployment.injectSecretPG | default false) true }}
- name: gcxi-var-pg-admin-password
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-pg-admin-password
- name: gcxi-var-pg-admin-username
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: keyvault-gcxi-pg-admin-username
{{- end }}
{{- end }}
{{- end }}


{{/*
Generate mount setup commands
*/}}
{{- define "mountSetupCmd" }}
{{- if .Values.gcxi.pvc.log.hostPath }}
{{- if .Values.gcxi.deployment.code }}mkdir -p {{ .Values.gcxi.pvc.log.hostPath }} {{ range $count := until (.Values.gcxi.replicas.worker|int) }}{{ $.Values.gcxi.pvc.log.hostPath }}/gcxi-{{ $.Values.gcxi.deployment.code }}-{{ $count }} {{ end }}&& chown -R {{ .Values.gcxi.securityContext.worker.runAsGroup }}:{{ .Values.gcxi.securityContext.worker.runAsUser }} {{ .Values.gcxi.pvc.log.hostPath }}
{{- else if eq .Values.gcxi.deployment.type "azure" }}mkdir -p {{ .Values.gcxi.pvc.log.hostPath }} {{ range $count := until (.Values.gcxi.replicas.worker|int) }}{{ $.Values.gcxi.pvc.log.hostPath }}/gcxi-{{ $.Values.gcxi.deployment.tenantId }}-{{ $.Values.gcxi.deployment.tenantColor }}-{{ $count }} {{ end }}&& chown -R {{ .Values.gcxi.securityContext.worker.runAsGroup }}:{{ .Values.gcxi.securityContext.worker.runAsUser }} {{ .Values.gcxi.pvc.log.hostPath }}
{{- else }}mkdir -p {{ .Values.gcxi.pvc.log.hostPath }} {{ range $count := until (.Values.gcxi.replicas.worker|int) }}{{ $.Values.gcxi.pvc.log.hostPath }}/gcxi-{{ $count }} {{ end }}&& chown -R {{ .Values.gcxi.securityContext.worker.runAsGroup }}:{{ .Values.gcxi.securityContext.worker.runAsUser }} {{ .Values.gcxi.pvc.log.hostPath }}
{{- end }}
{{- end }}
{{- end }}
