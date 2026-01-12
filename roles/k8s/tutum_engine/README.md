# k8s_tutum_engine

Deploy Tutum Engine to Kubernetes cluster.

## Requirements

- Ansible >= 2.14
- `kubernetes.core` collection
- kubectl configured with cluster access
- External PostgreSQL database (recommended for production)

## Role Variables

### Component Version

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_version` | `4.2.2` | Tutum Engine version |

### Kubernetes Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_namespace` | `tutum-system` | Kubernetes namespace |
| `k8s_tutum_engine_replicas` | `1` | Number of replicas |
| `k8s_tutum_engine_image` | `tutumpro/tutum-engine` | Docker image |
| `k8s_tutum_engine_image_pull_policy` | `Always` | Image pull policy |
| `k8s_tutum_engine_service_type` | `ClusterIP` | Service type |

### PostgreSQL Connection

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_postgres_host` | `""` | **Required**: PostgreSQL host |
| `k8s_tutum_postgres_port` | `5432` | PostgreSQL port |
| `k8s_tutum_postgres_db` | `tutum` | Database name |
| `k8s_tutum_postgres_user` | `tutum` | Database user |
| `k8s_tutum_postgres_password` | `tutum` | Database password |
| `k8s_tutum_postgres_sslmode` | `disable` | SSL mode |

### Security

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_master_key` | (generated) | 32-char AES-256 encryption key |
| `k8s_tutum_jwt_secret` | (generated) | 32-char JWT secret |

### Resource Limits

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_resources.requests.cpu` | `100m` | CPU request |
| `k8s_tutum_engine_resources.requests.memory` | `128Mi` | Memory request |
| `k8s_tutum_engine_resources.limits.cpu` | `500m` | CPU limit |
| `k8s_tutum_engine_resources.limits.memory` | `512Mi` | Memory limit |

### State

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_state` | `present` | `present` or `absent` |

## Example Playbook

```yaml
- hosts: localhost
  connection: local
  gather_facts: false

  vars:
    k8s_tutum_postgres_host: "192.168.1.100"
    k8s_tutum_postgres_password: "secure-password"
    k8s_tutum_master_key: "YourSecure32CharacterKeyHere!!!"
    k8s_tutum_jwt_secret: "AnotherSecure32CharJwtSecret!!"

  roles:
    - role: tutum_pro.cicd.k8s.tutum_engine
```

## Created Resources

- Namespace: `tutum-system`
- ConfigMap: `tutum-engine-config`
- Secret: `tutum-engine-secret`
- ServiceAccount: `tutum-engine`
- ClusterRole: `tutum-engine-pod-restarter`
- ClusterRoleBinding: `tutum-engine-pod-restarter`
- Deployment: `tutum-engine`
- Service: `tutum-engine` (ClusterIP)
- Service: `tutum-engine-headless` (headless)

## License

Proprietary - Tutum Pro
