# k8s_tutum_csi

Deploy Tutum CSI Driver to Kubernetes cluster for certificate volume provisioning.

## Requirements

- Ansible >= 2.14
- `kubernetes.core` collection
- kubectl configured with cluster access
- Tutum Engine deployed (for certificate fetching)

## Role Variables

### Component Versions

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_csi_version` | `4.0.1` | Tutum CSI Driver version |
| `k8s_csi_provisioner_version` | `v3.6.0` | CSI provisioner sidecar version |
| `k8s_csi_node_driver_registrar_version` | `v2.9.0` | Node driver registrar version |

### Kubernetes Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_namespace` | `tutum-system` | Kubernetes namespace |
| `k8s_distribution` | `standard` | K8s distribution: `standard`, `microk8s`, `k3s`, `rke2`, `openshift` |
| `k8s_tutum_engine_url` | `tutum-engine.tutum-system.svc.cluster.local:9090` | Tutum Engine gRPC URL |

### CSI Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_csi_driver_name` | `csi.tutum.io` | CSI driver name |
| `k8s_tutum_csi_storage_class_name` | `tutum-csi` | StorageClass name |
| `k8s_tutum_csi_volume_binding_mode` | `Immediate` | Volume binding mode |
| `k8s_tutum_csi_reclaim_policy` | `Delete` | Reclaim policy |

### State

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_csi_state` | `present` | `present` or `absent` |

## Kubernetes Distributions

The role supports different Kubernetes distributions with appropriate kubelet paths:

| Distribution | Kubelet Path |
|-------------|--------------|
| `standard` | `/var/lib/kubelet` |
| `microk8s` | `/var/snap/microk8s/common/var/lib/kubelet` |
| `k3s` | `/var/lib/rancher/k3s/agent` |
| `rke2` | `/var/lib/rancher/rke2/agent` |
| `openshift` | `/var/lib/kubelet` |

## Example Playbook

```yaml
- hosts: localhost
  connection: local
  gather_facts: false

  vars:
    k8s_distribution: "microk8s"
    k8s_tutum_engine_url: "tutum-engine.tutum-system.svc.cluster.local:9090"

  roles:
    - role: tutum_pro.cicd.k8s.tutum_csi
```

## Created Resources

- ServiceAccount: `tutum-csi-controller`
- ServiceAccount: `tutum-csi-node`
- ClusterRole: `tutum-csi-controller-role`
- ClusterRole: `tutum-csi-node-role`
- ClusterRoleBinding: `tutum-csi-controller-binding`
- ClusterRoleBinding: `tutum-csi-node-binding`
- CSIDriver: `csi.tutum.io`
- Deployment: `tutum-csi-controller`
- DaemonSet: `tutum-csi-node`
- StorageClass: `tutum-csi`

## Usage

After deployment, create PersistentVolumeClaims to provision certificate volumes:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-certificate
spec:
  storageClassName: tutum-csi
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 1Mi
  # Volume attributes for certificate selection
  # csi:
  #   volumeAttributes:
  #     namespace: "my-namespace"
  #     group: "my-group"
  #     certificate: "my-cert"
```

Or use ephemeral volumes directly in pods:

```yaml
volumes:
  - name: cert-volume
    csi:
      driver: csi.tutum.io
      volumeAttributes:
        engineUrl: "tutum-engine.tutum-system.svc.cluster.local:9090"  # Required for ephemeral volumes
        certificateName: "tls-cert"
        namespace: "production"      # Tutum certificate namespace
        groupID: "web-servers"       # Tutum certificate group
```

> **Note**: For ephemeral inline volumes, you must provide `engineUrl` in `volumeAttributes`
> since these volumes don't use the StorageClass parameters. For tree mode (all certificates
> with given name), omit `namespace` and `groupID`.

## License

Proprietary - Tutum Pro
