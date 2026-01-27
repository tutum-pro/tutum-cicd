# Tutum Operator Role for Kubernetes

This role deploys the Tutum Operator to a Kubernetes cluster. The operator provides a **rootless alternative** to the CSI driver for certificate delivery.

## Overview

Unlike the CSI driver which requires privileged access for mount operations, the Tutum Operator:
- Runs as non-root user (UID 65532)
- Creates standard Kubernetes Secrets from Tutum Engine certificates
- Automatically refreshes certificates at configurable intervals
- Requires no special kernel capabilities

## Requirements

- Kubernetes 1.25+
- `kubectl` configured with cluster access
- Tutum Engine deployed and accessible

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_operator_version` | `1.0.0` | Operator image version |
| `k8s_tutum_namespace` | `tutum-system` | Namespace for deployment |
| `k8s_tutum_operator_image` | `tutumpro/tutum-operator-k8s` | Operator image |
| `k8s_tutum_engine_url` | `tutum-engine.tutum-system.svc.cluster.local:9090` | Tutum Engine gRPC URL |
| `k8s_tutum_operator_sync_interval` | `5m` | Default certificate sync interval |
| `k8s_tutum_operator_log_level` | `info` | Log level (debug, info, warn, error) |
| `k8s_tutum_operator_watch_namespaces` | `""` | Comma-separated namespaces to watch (empty = all) |
| `k8s_tutum_operator_skip_crd_install` | `false` | Skip CRD installation (generate manifest only) |
| `k8s_tutum_operator_crd_manifest_path` | `./tutum-operator-crd.yml` | Path for generated CRD manifest |
| `k8s_tutum_operator_state` | `present` | Set to `absent` to uninstall |

## Usage

### Install (with cluster-admin permissions)

```yaml
- hosts: k8s_controllers
  roles:
    - role: tutum_pro.cicd.k8s.tutum_operator
```

### Install without cluster-admin (OpenShift/Restricted environments)

When you don't have cluster-admin permissions, you can:
1. Generate CRD manifest for manual installation
2. Install operator with namespace-scoped permissions

```yaml
- hosts: k8s_controllers
  roles:
    - role: tutum_pro.cicd.k8s.tutum_operator
      k8s_tutum_operator_skip_crd_install: true
      k8s_tutum_operator_crd_manifest_path: "./crd-for-admin.yml"
      k8s_tutum_operator_watch_namespaces: "production,staging"
```

This will:
- Generate CRD manifest at `./crd-for-admin.yml` (provide to cluster admin)
- Install operator with Role/RoleBinding (namespace-scoped)
- Configure operator to watch only specified namespaces

**Admin must install CRD:**
```bash
kubectl apply -f crd-for-admin.yml
```

### Uninstall

```yaml
- hosts: k8s_controllers
  roles:
    - role: tutum_pro.cicd.k8s.tutum_operator
      k8s_tutum_operator_state: absent
```

## TutumCertificate Custom Resource

After deployment, create `TutumCertificate` resources to sync certificates:

```yaml
apiVersion: tutum.io/v1
kind: TutumCertificate
metadata:
  name: my-cert
  namespace: my-app
spec:
  certificateName: web-server      # Name in Tutum Engine
  groupId: production              # Group ID in Tutum Engine
  namespace: default               # Namespace in Tutum Engine
  secretName: web-tls-secret       # K8s Secret to create
  refreshInterval: 5m              # Sync interval (optional)
```

The operator will:
1. Fetch the certificate from Tutum Engine
2. Create a Kubernetes Secret with certificate data
3. Periodically refresh the certificate

## Comparison: CSI Driver vs Operator

| Feature | CSI Driver | Operator |
|---------|------------|----------|
| Root required | Yes (mount syscalls) | No |
| Real-time mount | Yes | No (periodic sync) |
| Pod restart on cert update | Not needed | May need Reloader |
| Resource usage | DaemonSet (per node) | Single Deployment |
| Complexity | Higher | Lower |

Choose CSI driver when you need:
- Real-time certificate updates in pods
- No pod restarts on certificate changes

Choose Operator when you need:
- Rootless deployment
- Simpler architecture
- Standard Secret-based certificate delivery

## License

Proprietary - Tutum Pro
