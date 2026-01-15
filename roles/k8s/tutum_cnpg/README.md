# k8s_tutum_cnpg

Deploy CloudNativePG (CNPG) PostgreSQL cluster to Kubernetes.

## Description

This role installs the CloudNativePG operator and creates a PostgreSQL cluster for the Tutum Platform. CloudNativePG is a Kubernetes operator that manages the full lifecycle of PostgreSQL clusters with features like:

- Automated failover and high availability
- Continuous backup and point-in-time recovery
- Rolling updates
- Connection pooling (PgBouncer)
- Monitoring integration

## Requirements

- Ansible >= 2.14
- `kubernetes.core` collection
- kubectl configured with cluster access
- Kubernetes 1.25+

## Usage

### Basic Usage

```bash
# Deploy CNPG cluster with default settings
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_cnpg

# Custom database password
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_cnpg \
  -e k8s_tutum_cnpg_db_password=secure-password

# High availability setup (3 instances)
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_cnpg \
  -e k8s_tutum_cnpg_instances=3
```

### Using in Playbook

```yaml
- hosts: k8s_controllers
  roles:
    - role: tutum_pro.cicd.k8s.tutum_cnpg
      vars:
        k8s_tutum_cnpg_instances: 3
        k8s_tutum_cnpg_storage_size: "10Gi"
        k8s_tutum_cnpg_enable_pooler: true
```

## Role Variables

### CNPG Operator

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_operator_version` | `1.25.0` | CNPG operator version |
| `k8s_tutum_cnpg_operator_namespace` | `cnpg-system` | Operator namespace |
| `k8s_tutum_cnpg_install_operator` | `true` | Install operator (false if already installed) |

### PostgreSQL Cluster

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_namespace` | `tutum-system` | Cluster namespace |
| `k8s_tutum_cnpg_cluster_name` | `tutum-postgres` | Cluster name |
| `k8s_tutum_cnpg_postgres_version` | `16` | PostgreSQL major version |
| `k8s_tutum_cnpg_instances` | `1` | Number of instances (1 primary + N-1 replicas) |
| `k8s_tutum_cnpg_image` | `""` | Custom image (empty = CNPG default) |

### Storage

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_storage_class` | `""` | Storage class (empty = default) |
| `k8s_tutum_cnpg_storage_size` | `5Gi` | Storage size per instance |

### Database Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_db_name` | `tutum` | Database name |
| `k8s_tutum_cnpg_db_user` | `tutum` | Database user |
| `k8s_tutum_cnpg_db_password` | `""` | Password (empty = auto-generate) |
| `k8s_tutum_cnpg_superuser_password` | `""` | Superuser password (empty = auto-generate) |

### Resources

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_resources.requests.cpu` | `100m` | CPU request |
| `k8s_tutum_cnpg_resources.requests.memory` | `256Mi` | Memory request |
| `k8s_tutum_cnpg_resources.limits.cpu` | `1000m` | CPU limit |
| `k8s_tutum_cnpg_resources.limits.memory` | `1Gi` | Memory limit |

### PostgreSQL Parameters

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_postgres_parameters` | See defaults | PostgreSQL configuration |
| `k8s_tutum_cnpg_pg_hba` | `[]` | Additional pg_hba.conf entries |

### Optional Features

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_enable_monitoring` | `false` | Enable Prometheus PodMonitor |
| `k8s_tutum_cnpg_enable_pooler` | `false` | Enable PgBouncer pooler |
| `k8s_tutum_cnpg_pooler_instances` | `1` | Number of pooler instances |
| `k8s_tutum_cnpg_pooler_mode` | `transaction` | Pooling mode |

### State

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_state` | `present` | State: `present` or `absent` |
| `k8s_tutum_cnpg_remove_operator` | `false` | Remove operator on uninstall |
| `k8s_tutum_cnpg_remove_data` | `false` | Remove PVCs on uninstall |

## Services Created

After deployment, the following services are available:

| Service | Description |
|---------|-------------|
| `tutum-postgres-rw` | Read-write service (primary) |
| `tutum-postgres-ro` | Read-only service (replicas, if instances > 1) |
| `tutum-postgres-r` | Read service (any instance) |
| `tutum-postgres-pooler-rw` | PgBouncer pooler (if enabled) |

## Secrets Created

| Secret | Description |
|--------|-------------|
| `tutum-postgres-app-credentials` | Application user credentials |
| `tutum-postgres-superuser-credentials` | PostgreSQL superuser credentials |

## Connecting to the Database

```bash
# Get app password
kubectl get secret tutum-postgres-app-credentials -n tutum-system \
  -o jsonpath='{.data.password}' | base64 -d

# Connect from within cluster
psql -h tutum-postgres-rw.tutum-system.svc.cluster.local \
  -U tutum -d tutum

# Port forward for local access
kubectl port-forward svc/tutum-postgres-rw 5432:5432 -n tutum-system
psql -h localhost -U tutum -d tutum
```

## High Availability

For production, use at least 3 instances:

```yaml
k8s_tutum_cnpg_instances: 3
```

This creates:
- 1 primary instance (read-write)
- 2 replica instances (read-only)
- Automatic failover if primary fails

## Uninstalling

```bash
# Remove cluster only
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_cnpg \
  -e k8s_tutum_cnpg_state=absent

# Remove cluster and data
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_cnpg \
  -e k8s_tutum_cnpg_state=absent \
  -e k8s_tutum_cnpg_remove_data=true

# Remove everything including operator
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_cnpg \
  -e k8s_tutum_cnpg_state=absent \
  -e k8s_tutum_cnpg_remove_data=true \
  -e k8s_tutum_cnpg_remove_operator=true
```

## License

Proprietary - Tutum Pro
