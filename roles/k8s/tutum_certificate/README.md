# k8s_tutum_certificate

Generate TutumCertificate CR manifest for Kubernetes.

## Description

The `k8s_tutum_certificate` role generates a TutumCertificate Custom Resource manifest that can be applied to a Kubernetes cluster with the Tutum Operator installed.

## Requirements

- Ansible >= 2.14
- Tutum Operator installed in the cluster (for applying the manifest)

## Usage

### Generate manifest file (default)

```bash
# Tree mode (all certificates)
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_certificate \
  -e k8s_tutum_cert_name=my-app-certs \
  -e k8s_tutum_cert_secret_name=my-app-tls \
  -e k8s_tutum_cert_deploy_namespace=my-app

# Single certificate mode
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_certificate \
  -e k8s_tutum_cert_name=my-certificate \
  -e k8s_tutum_cert_secret_name=my-tls-secret \
  -e k8s_tutum_cert_tree_mode=false \
  -e k8s_tutum_cert_group_id=my-group \
  -e k8s_tutum_cert_namespace=my-namespace
```

### Generate and apply to cluster

```bash
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_certificate \
  -e k8s_tutum_cert_name=my-app-certs \
  -e k8s_tutum_cert_secret_name=my-app-tls \
  -e k8s_tutum_cert_apply=true
```

### Custom output path

```bash
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_certificate \
  -e k8s_tutum_cert_name=my-app-certs \
  -e k8s_tutum_cert_secret_name=my-app-tls \
  -e k8s_tutum_cert_output_path=/path/to/manifests \
  -e k8s_tutum_cert_output_file=my-cert.yml
```

## Role Variables

### Required Parameters

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cert_name` | `""` | Certificate name in Tutum Engine |
| `k8s_tutum_cert_secret_name` | `""` | Kubernetes Secret name to create |

### Mode Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cert_tree_mode` | `true` | Tree mode (true) or single cert mode (false) |
| `k8s_tutum_cert_group_id` | `""` | Group ID (required when treeMode=false) |
| `k8s_tutum_cert_namespace` | `""` | Namespace in Tutum Engine (required when treeMode=false) |

### Deployment Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cert_deploy_namespace` | `default` | Kubernetes namespace for CR |

### Certificate Options

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cert_version` | `0` | Certificate version (0 = latest) |
| `k8s_tutum_cert_refresh_interval` | `5m` | Sync interval |
| `k8s_tutum_cert_channel` | `default` | Distribution channel |
| `k8s_tutum_cert_auth_token` | `""` | Auth token for channel |

### Secret Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cert_secret_type` | `Opaque` | Secret type (`Opaque` or `kubernetes.io/tls`) |
| `k8s_tutum_cert_include_ca` | `true` | Include CA certificate |
| `k8s_tutum_cert_engine_url` | `""` | Override Tutum Engine URL |
| `k8s_tutum_cert_secret_labels` | `{}` | Additional Secret labels |
| `k8s_tutum_cert_secret_annotations` | `{}` | Additional Secret annotations |

### Output Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cert_output_path` | `.` | Output directory |
| `k8s_tutum_cert_output_file` | `""` | Custom output filename (if empty, uses `{prefix}-{cert_name}.yml`) |
| `k8s_tutum_cert_output_prefix` | `tutumcertificate` | Filename prefix (used when `output_file` is empty) |
| `k8s_tutum_cert_apply` | `false` | Apply manifest to cluster |
| `k8s_tutum_cert_state` | `present` | `present` or `absent` |

**Note:** Certificate name and custom output filename must be valid Unix filenames: start with alphanumeric, contain only `a-z`, `A-Z`, `0-9`, `.`, `_`, `-`, max 253 characters.

## Tree Mode vs Single Mode

### Tree Mode (`k8s_tutum_cert_tree_mode: true`)

Fetches all certificates from Tutum Engine and creates a directory structure:

```
/certs/
  cert1.crt
  cert2.crt
/private/
  cert1.key
  cert2.key
/ca/
  ca.crt
```

- `secretType` must be `Opaque`
- `groupId` and `certNamespace` must be empty

### Single Mode (`k8s_tutum_cert_tree_mode: false`)

Fetches a single certificate:

```
tls.crt
tls.key
ca.crt (optional)
```

- `secretType` can be `kubernetes.io/tls` or `Opaque`
- `groupId` and `certNamespace` are required

## Examples

### Tree mode with custom labels

```yaml
- hosts: localhost
  tasks:
    - name: Generate TutumCertificate manifest
      ansible.builtin.include_role:
        name: tutum_pro.cicd.k8s.tutum_certificate
      vars:
        k8s_tutum_cert_name: production-certs
        k8s_tutum_cert_secret_name: prod-tls
        k8s_tutum_cert_deploy_namespace: production
        k8s_tutum_cert_refresh_interval: "1h"
        k8s_tutum_cert_secret_labels:
          app.kubernetes.io/part-of: my-app
          environment: production
```

### Single certificate for TLS Ingress

```yaml
- hosts: localhost
  tasks:
    - name: Generate TutumCertificate for Ingress
      ansible.builtin.include_role:
        name: tutum_pro.cicd.k8s.tutum_certificate
      vars:
        k8s_tutum_cert_name: api-gateway
        k8s_tutum_cert_secret_name: api-gateway-tls
        k8s_tutum_cert_tree_mode: false
        k8s_tutum_cert_group_id: production
        k8s_tutum_cert_namespace: api
        k8s_tutum_cert_secret_type: "kubernetes.io/tls"
        k8s_tutum_cert_deploy_namespace: ingress-nginx
        k8s_tutum_cert_apply: true
```

## Generated Manifest Example

```yaml
apiVersion: tutum.io/v1
kind: TutumCertificate
metadata:
  name: my-app-certs
  namespace: default
spec:
  certificateName: my-app-certs
  treeMode: true
  secretName: my-app-tls
  secretType: Opaque
  includeCa: true
  refreshInterval: 5m
```
