# k8s_tutum_init

Generate Tutum Platform Kubernetes installation playbook and inventory.

## Description

The `k8s_tutum_init` role generates an Ansible playbook and inventory file for deploying Tutum Platform to Kubernetes. This is analogous to `docker_tutum_init` but for Kubernetes environments.

Variables are placed in the inventory file, allowing easy customization without modifying the playbook.

## Requirements

- Ansible >= 2.14
- `tutum_pro.cicd` collection

## Usage

Run the role directly from command line:

```bash
# Basic usage with embedded PostgreSQL (generate playbook with default settings)
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init

# With CloudNativePG (recommended for production)
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_db_mode=cnpg

# With CloudNativePG HA cluster (3 instances)
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_db_mode=cnpg \
  -e k8s_tutum_cnpg_instances=3

# With external PostgreSQL configuration
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_db_mode=external \
  -e k8s_tutum_init_postgres_host=192.168.1.100 \
  -e k8s_tutum_init_postgres_password=secure-password

# For MicroK8s
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_distribution=microk8s

# Overwrite existing files
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_overwrite=true
```

## Role Variables

### Output Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_output_path` | `.` | Output directory |
| `k8s_tutum_init_inventory_path` | `inventory` | Inventory directory (relative to output_path) |
| `k8s_tutum_init_inventory_file` | `k8s.ini` | Inventory filename |
| `k8s_tutum_init_playbook_file` | `tutum-k8s-install.yml` | Playbook filename |
| `k8s_tutum_init_overwrite` | `false` | Overwrite existing files |

### Kubernetes Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_namespace` | `tutum-system` | Kubernetes namespace |
| `k8s_tutum_init_distribution` | `standard` | K8s distribution: `standard`, `microk8s`, `k3s`, `rke2`, `openshift` |

### Component Versions

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_version` | `5.0.8` | Tutum Engine version |
| `k8s_tutum_csi_version` | `4.0.0` | CSI Driver version |
| `k8s_tutum_postgres_version` | `15-alpine` | PostgreSQL version (embedded mode only) |

### Database Mode

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_db_mode` | `embedded` | Database mode: `embedded`, `cnpg`, or `external` |

- **embedded**: Deploys simple PostgreSQL in Kubernetes (tutum_postgres role) - suitable for development
- **cnpg**: Deploys CloudNativePG cluster (tutum_cnpg role) - recommended for production
- **external**: Uses external PostgreSQL (requires connection settings below)

### CloudNativePG Configuration (for db_mode=cnpg)

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_cnpg_operator_version` | `1.25.0` | CNPG operator version |
| `k8s_tutum_cnpg_postgres_version` | `16` | PostgreSQL major version |
| `k8s_tutum_cnpg_instances` | `1` | Number of instances (1=standalone, 3+=HA) |
| `k8s_tutum_cnpg_storage_size` | `5Gi` | Storage size per instance |
| `k8s_tutum_cnpg_enable_pooler` | `false` | Enable PgBouncer connection pooling |

### PostgreSQL Connection (for external mode)

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_postgres_host` | `""` | PostgreSQL host (required for external mode) |
| `k8s_tutum_init_postgres_port` | `5432` | PostgreSQL port |
| `k8s_tutum_init_postgres_db` | `tutum` | Database name |
| `k8s_tutum_init_postgres_user` | `tutum` | Database user |
| `k8s_tutum_init_postgres_password` | `tutum` | Database password |
| `k8s_tutum_init_external_db_url` | `""` | Full database URL (alternative to individual settings) |

### Security Keys

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_master_key` | `""` | Master key (empty = auto-generate) |
| `k8s_tutum_init_jwt_secret` | `""` | JWT secret (empty = auto-generate) |

### Component Selection

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_init_generate_postgres` | `true` | Generate PostgreSQL (for embedded/cnpg modes) |
| `k8s_tutum_init_generate_engine` | `true` | Generate Tutum Engine role |
| `k8s_tutum_init_generate_csi` | `true` | Generate CSI Driver role |

## Generated Files

After running the role:

1. **Inventory** (`inventory/k8s.ini`):
   - Host definition for local kubectl execution
   - All configuration variables for customization
   - Database connection settings (varies by mode)
   - Security keys (commented if auto-generate)

2. **Playbook** (`tutum-k8s-install.yml`):
   - Deploys PostgreSQL (embedded or CNPG based on mode)
   - Deploys Tutum Engine
   - Deploys CSI Driver
   - Auto-generates security keys if not provided

## Customizing the Installation

Edit the generated inventory file (`inventory/k8s.ini`) to customize:

```ini
[k8s_controllers:vars]
# Change namespace
k8s_tutum_namespace=my-namespace

# Update versions
k8s_tutum_engine_version=5.0.9

# Set security keys (recommended for production)
k8s_tutum_master_key=YourSecure32CharacterKeyHere!!!
k8s_tutum_jwt_secret=AnotherSecure32CharJwtSecret!!

# For CNPG mode - adjust cluster settings
k8s_tutum_cnpg_instances=3
k8s_tutum_cnpg_storage_size=10Gi
```

## Installation

After generating files:

```bash
# Ensure kubectl is configured
kubectl cluster-info

# Run the playbook with the generated inventory
ansible-playbook -i inventory/k8s.ini tutum-k8s-install.yml
```

## Database Mode Comparison

| Feature | embedded | cnpg | external |
|---------|----------|------|----------|
| Automatic failover | No | Yes | Depends |
| HA support | No | Yes (3+ instances) | Depends |
| Connection pooling | No | Optional (PgBouncer) | Depends |
| Backup/restore | Manual | Built-in | Depends |
| Complexity | Low | Medium | N/A |
| Production ready | No | Yes | Yes |

## License

Proprietary - Tutum Pro
