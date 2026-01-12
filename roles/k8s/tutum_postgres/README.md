# k8s_tutum_postgres

Deploy PostgreSQL database to Kubernetes for Tutum Engine.

## Description

The `k8s_tutum_postgres` role deploys a PostgreSQL database to Kubernetes cluster. This role is used when you want to run an embedded PostgreSQL instead of using an external database.

## Requirements

- Ansible >= 2.14
- `kubernetes.core` collection
- kubectl configured to access the target cluster

## Usage

```yaml
- name: Deploy Tutum Platform with embedded PostgreSQL
  hosts: localhost
  connection: local
  gather_facts: false

  roles:
    - role: tutum_pro.cicd.k8s.tutum_postgres
    - role: tutum_pro.cicd.k8s.tutum_engine
    - role: tutum_pro.cicd.k8s.tutum_csi
```

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_postgres_version` | `15-alpine` | PostgreSQL image tag |
| `k8s_tutum_namespace` | `tutum-system` | Kubernetes namespace |
| `k8s_tutum_db_name` | `tutum` | Database name |
| `k8s_tutum_db_user` | `tutum` | Database user |
| `k8s_tutum_db_password` | `tutum` | Database password |
| `k8s_tutum_db_port` | `5432` | PostgreSQL port |
| `k8s_tutum_postgres_storage_class` | `""` | StorageClass (empty = default) |
| `k8s_tutum_postgres_storage_size` | `5Gi` | PVC size |
| `k8s_tutum_postgres_state` | `present` | `present` or `absent` |
| `k8s_tutum_postgres_remove_data` | `false` | Remove PVC on uninstall |

## Created Resources

- **Secret**: `tutum-postgres-secret` - Database credentials
- **PersistentVolumeClaim**: `tutum-postgres-data` - Data storage
- **Deployment**: `tutum-postgres` - PostgreSQL container
- **Service**: `tutum-postgres` - ClusterIP service

## Connection from Tutum Engine

When using embedded PostgreSQL, the Tutum Engine connects using:
```
tutum-postgres.tutum-system.svc.cluster.local:5432
```

## License

MIT
