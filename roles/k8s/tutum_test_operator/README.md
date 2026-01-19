# Tutum Test Operator Role

Test role for verifying Tutum Operator certificate mounting using a busybox container.

## Overview

This role deploys:
1. A `TutumCertificate` custom resource requesting the certificate `ksef-digital-fp-cert`
2. A busybox Deployment that mounts the certificate Secret as a volume

This allows testing the full certificate delivery flow:
```
TutumCertificate CR → Tutum Operator → Kubernetes Secret → Pod Volume Mount
```

## Requirements

- Kubernetes cluster with `kubectl` configured
- Tutum Operator deployed (`tutum_pro.cicd.k8s.tutum_operator` role)
- Tutum Engine running and accessible
- Certificate `ksef-digital-fp-cert` available in Tutum Engine

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_namespace` | `tutum-system` | Namespace for deployment |
| `k8s_tutum_test_app_name` | `tutum-test-app` | Name of test Deployment |
| `k8s_tutum_test_image` | `busybox:latest` | Test container image |
| `k8s_tutum_test_cert_name` | `ksef-digital-fp-cert` | Certificate name in Tutum Engine |
| `k8s_tutum_test_cert_group_id` | `default` | Group ID in Tutum Engine |
| `k8s_tutum_test_cert_namespace` | `default` | Namespace in Tutum Engine |
| `k8s_tutum_test_cert_secret_name` | `ksef-digital-fp-cert-secret` | K8s Secret name |
| `k8s_tutum_test_cert_refresh_interval` | `5m` | Certificate sync interval |
| `k8s_tutum_test_cert_mount_path` | `/etc/ssl/certs/ksef` | Mount path in pod |
| `k8s_tutum_test_operator_state` | `present` | Set to `absent` to uninstall |

## Usage

### Install

```yaml
- hosts: k8s_controllers
  roles:
    - role: tutum_pro.cicd.k8s.tutum_test_operator
```

Or with custom certificate:

```yaml
- hosts: k8s_controllers
  roles:
    - role: tutum_pro.cicd.k8s.tutum_test_operator
      k8s_tutum_test_cert_name: my-certificate
      k8s_tutum_test_cert_group_id: production
      k8s_tutum_test_cert_secret_name: my-cert-secret
```

### Uninstall

```yaml
- hosts: k8s_controllers
  roles:
    - role: tutum_pro.cicd.k8s.tutum_test_operator
      k8s_tutum_test_operator_state: absent
```

## Verification

After deployment, verify certificates are mounted:

```bash
# Check TutumCertificate status
kubectl get tutumcertificate ksef-digital-fp-cert -n tutum-system -o wide

# Check if Secret was created
kubectl get secret ksef-digital-fp-cert-secret -n tutum-system

# Check pod logs
kubectl logs deploy/tutum-test-app -n tutum-system

# List certificate files in pod
kubectl exec -it deploy/tutum-test-app -n tutum-system -- ls -la /etc/ssl/certs/ksef

# View certificate content
kubectl exec -it deploy/tutum-test-app -n tutum-system -- cat /etc/ssl/certs/ksef/tls.crt
```

## Certificate Structure

The Secret mounted in the pod contains:

| File | Description |
|------|-------------|
| `tls.crt` | Server certificate (PEM) |
| `tls.key` | Private key (PEM) |
| `ca.crt` | CA certificate chain (PEM) |

## Architecture

```
┌────────────────────┐
│  TutumCertificate  │
│  ksef-digital-fp   │
└─────────┬──────────┘
          │ watched by
          ▼
┌────────────────────┐      fetch cert     ┌────────────────────┐
│  Tutum Operator    │ ──────────────────► │  Tutum Engine      │
└─────────┬──────────┘                     └────────────────────┘
          │ creates
          ▼
┌────────────────────┐
│  Kubernetes Secret │
│  ksef-...-secret   │
└─────────┬──────────┘
          │ mounted as volume
          ▼
┌────────────────────┐
│  busybox Pod       │
│  /etc/ssl/certs/   │
└────────────────────┘
```

## License

Proprietary - Tutum Pro
