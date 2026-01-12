# k8s_tutum_init

Generate Tutum Platform Kubernetes installation playbook.

## Description

The `k8s_tutum_init` role generates an Ansible playbook for deploying Tutum Platform to Kubernetes. This is analogous to `docker_tutum_init` but for Kubernetes environments.

## Requirements

- Ansible >= 2.14
- `tutum_pro.cicd` collection

## Usage

Run the role directly from command line:

```bash
# Basic usage (generate playbook with default settings)
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init

# With PostgreSQL configuration
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_postgres_host=192.168.1.100 \
  -e k8s_tutum_init_postgres_password=secure-password

# For MicroK8s
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_distribution=microk8s \
  -e k8s_tutum_init_postgres_host=192.168.1.100

# Overwrite existing files
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_overwrite=true
```

## Role Variables

### Output Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_output_path` | `.` | Output directory |
| `k8s_tutum_init_playbook_file` | `tutum-k8s-install.yml` | Playbook filename |
| `k8s_tutum_init_overwrite` | `false` | Overwrite existing files |

### Kubernetes Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_namespace` | `tutum-system` | Kubernetes namespace |
| `k8s_tutum_init_distribution` | `standard` | K8s distribution: `standard`, `microk8s`, `k3s`, `openshift` |

### Component Versions

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_version` | `4.2.2` | Tutum Engine version |
| `k8s_tutum_csi_version` | `3.1.0` | CSI Driver version |

### PostgreSQL Connection

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_postgres_host` | `""` | **Required**: PostgreSQL host |
| `k8s_tutum_init_postgres_port` | `5432` | PostgreSQL port |
| `k8s_tutum_init_postgres_db` | `tutum` | Database name |
| `k8s_tutum_init_postgres_user` | `tutum` | Database user |
| `k8s_tutum_init_postgres_password` | `tutum` | Database password |

### Security Keys

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_master_key` | `""` | Master key (empty = auto-generate) |
| `k8s_tutum_init_jwt_secret` | `""` | JWT secret (empty = auto-generate) |

### Component Selection

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_generate_engine` | `true` | Generate Tutum Engine role |
| `k8s_tutum_init_generate_csi` | `true` | Generate CSI Driver role |

## Generated Files

After running the role:

1. **Playbook** (`tutum-k8s-install.yml`):
   - Deploys Tutum Engine
   - Deploys CSI Driver
   - Creates necessary Kubernetes resources

## Installation

After generating files:

```bash
# Ensure kubectl is configured
kubectl cluster-info

# Run the playbook
ansible-playbook tutum-k8s-install.yml
```

## License

Proprietary - Tutum Pro
