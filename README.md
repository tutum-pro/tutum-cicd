# Tutum Pro CI/CD - Ansible Collection

Ansible collection for deploying Tutum Pro certificate management platform.

**Collection:** `tutum_pro.cicd`

## Installation

### From Ansible Galaxy

```bash
ansible-galaxy collection install tutum_pro.cicd
```

### From Git

```bash
ansible-galaxy collection install git+https://github.com/tutum/tutum-cicd.git
```

### Using requirements.yml

```yaml
# requirements.yml
collections:
  - name: tutum_pro.cicd
    version: ">=1.0.0"
```

```bash
ansible-galaxy collection install -r requirements.yml
```

## Quick Start

### Using Collection Playbooks

```bash
# Install all components (Docker)
ansible-playbook -i inventory/hosts.yml tutum_pro.cicd.site

# Install individual components
ansible-playbook -i inventory/hosts.yml tutum_pro.cicd.engine
ansible-playbook -i inventory/hosts.yml tutum_pro.cicd.plugin
ansible-playbook -i inventory/hosts.yml tutum_pro.cicd.cli

# Show version report
ansible-playbook -i inventory/hosts.yml tutum_pro.cicd.report

# Uninstall all
ansible-playbook -i inventory/hosts.yml tutum_pro.cicd.uninstall
```

### Using Roles in Your Playbook

**With embedded PostgreSQL (default):**

```yaml
# site.yml
- name: Deploy Tutum Pro
  hosts: docker_servers
  become: true

  vars:
    docker_tutum_engine_version: "4.2.2"
    docker_tutum_master_key: "YourSecure32CharacterKeyHere!!!"
    docker_tutum_jwt_secret: "YourSecure32CharacterJwtSecret!"

  roles:
    - role: tutum_pro.cicd.docker.tutum_postgres
    - role: tutum_pro.cicd.docker.tutum_engine
    - role: tutum_pro.cicd.docker.tutum_plugin
    - role: tutum_pro.cicd.docker.tutum_cli
```

**With external PostgreSQL:**

```yaml
# site.yml
- name: Deploy Tutum Pro
  hosts: docker_servers
  become: true

  vars:
    docker_tutum_engine_version: "4.2.2"
    docker_tutum_external_db_url: "postgres://tutum:password@db.example.com:5432/tutum?sslmode=require"
    docker_tutum_master_key: "YourSecure32CharacterKeyHere!!!"
    docker_tutum_jwt_secret: "YourSecure32CharacterJwtSecret!"

  roles:
    - role: tutum_pro.cicd.docker.tutum_engine
    - role: tutum_pro.cicd.docker.tutum_plugin
    - role: tutum_pro.cicd.docker.tutum_cli
```

## Roles

### Docker Roles (`docker.*`)

For deployment on Docker hosts. Located in `roles/docker/`.

All variables use `docker_tutum_` prefix.

#### tutum_pro.cicd.docker.tutum_postgres

Installs PostgreSQL database for Tutum Engine.

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_postgres_version` | `15-alpine` | PostgreSQL version |
| `docker_tutum_postgres_container_name` | `tutum-postgres` | Container name |
| `docker_tutum_db_name` | `tutum` | Database name |
| `docker_tutum_db_user` | `tutum` | Database user |
| `docker_tutum_db_password` | `tutum` | Database password |
| `docker_tutum_db_port` | `5432` | PostgreSQL port |
| `docker_tutum_postgres_state` | `present` | `present` or `absent` |
| `docker_tutum_postgres_remove_data` | `false` | Remove data on uninstall |

#### tutum_pro.cicd.docker.tutum_engine

Installs Tutum Engine. Supports embedded PostgreSQL (via `tutum_postgres` role) or external database.

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_engine_version` | `4.2.2` | Tutum Engine version |
| `docker_tutum_external_db_url` | `""` | External PostgreSQL URL (skips embedded DB) |
| `docker_tutum_db_name` | `tutum` | Database name (embedded mode) |
| `docker_tutum_db_user` | `tutum` | Database user (embedded mode) |
| `docker_tutum_db_password` | `tutum` | Database password (embedded mode) |
| `docker_tutum_master_key` | (generated) | 32-char AES-256 encryption key |
| `docker_tutum_jwt_secret` | (generated) | 32-char JWT secret |
| `docker_tutum_rest_port` | `8080` | REST API port |
| `docker_tutum_grpc_port` | `9090` | gRPC API port |
| `docker_tutum_log_level` | `info` | Log level |
| `docker_tutum_engine_state` | `present` | `present` or `absent` |
| `docker_tutum_engine_remove_data` | `false` | Remove data on uninstall |

#### tutum_pro.cicd.docker.tutum_plugin

Installs Tutum Docker Volume Plugin.

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_plugin_version` | `2.1.6` | Plugin version |
| `docker_tutum_engine_url` | `localhost:9090` | Tutum Engine gRPC URL |
| `docker_tutum_volume_dir` | `/var/lib/tutum/volumes` | Volume mount directory |
| `docker_tutum_log_level` | `info` | Log level |
| `docker_tutum_plugin_state` | `present` | `present` or `absent` |
| `docker_tutum_plugin_remove_volumes` | `false` | Remove volumes on uninstall |

#### tutum_pro.cicd.docker.tutum_cli

Installs Tutum Admin CLI container.

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_cli_version` | `0.2.1` | CLI version |
| `docker_tutum_cli_container_name` | `tutum-admin-cli` | Container name |
| `docker_tutum_engine_url` | `localhost:9090` | Tutum Engine gRPC URL |
| `docker_tutum_cli_state` | `present` | `present` or `absent` |

#### tutum_pro.cicd.docker.tutum_report

Generates version report of installed Docker components.

### Kubernetes Roles (`k8s.*`)

For deployment on Kubernetes clusters. Located in `roles/k8s/`.
All variables use `k8s_tutum_` prefix.

#### tutum_pro.cicd.k8s.tutum_engine

Deploys Tutum Engine to Kubernetes cluster.

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_version` | `4.2.2` | Tutum Engine version |
| `k8s_tutum_namespace` | `tutum-system` | Kubernetes namespace |
| `k8s_tutum_postgres_host` | `""` | **Required**: PostgreSQL host |
| `k8s_tutum_postgres_port` | `5432` | PostgreSQL port |
| `k8s_tutum_postgres_db` | `tutum` | Database name |
| `k8s_tutum_postgres_user` | `tutum` | Database user |
| `k8s_tutum_postgres_password` | `tutum` | Database password |
| `k8s_tutum_master_key` | (generated) | 32-char AES-256 encryption key |
| `k8s_tutum_jwt_secret` | (generated) | 32-char JWT secret |
| `k8s_tutum_engine_state` | `present` | `present` or `absent` |

#### tutum_pro.cicd.k8s.tutum_csi

Deploys Tutum CSI Driver to Kubernetes for certificate volume provisioning.

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_csi_version` | `3.1.0` | CSI Driver version |
| `k8s_tutum_namespace` | `tutum-system` | Kubernetes namespace |
| `k8s_distribution` | `standard` | K8s distribution: `standard`, `microk8s`, `k3s`, `openshift` |
| `k8s_tutum_engine_url` | `tutum-engine.tutum-system.svc.cluster.local:9090` | Tutum Engine gRPC URL |
| `k8s_tutum_csi_storage_class_name` | `tutum-csi` | StorageClass name |
| `k8s_tutum_csi_state` | `present` | `present` or `absent` |

#### tutum_pro.cicd.k8s.tutum_init

Generates Kubernetes installation playbook (similar to `docker.tutum_init`).

```bash
# Generate K8s installation files
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_init \
  -e k8s_tutum_init_postgres_host=192.168.1.100 \
  -e k8s_tutum_init_distribution=microk8s
```

### Kubernetes Quick Start

```bash
# Deploy to Kubernetes (requires external PostgreSQL)
ansible-playbook playbooks/install-tutum-k8s.yml \
  -e k8s_tutum_postgres_host=192.168.1.100 \
  -e k8s_tutum_postgres_password=secure-password

# For MicroK8s
ansible-playbook playbooks/install-tutum-k8s.yml \
  -e k8s_distribution=microk8s \
  -e k8s_tutum_postgres_host=192.168.1.100

# Uninstall from Kubernetes
ansible-playbook playbooks/uninstall-tutum-k8s.yml
```

## Example: External Project

See `docs/examples/external-project/` for a complete example of using this collection in your project.

```
my-project/
├── requirements.yml          # Collection dependency
├── inventory/
│   ├── hosts.yml
│   └── group_vars/all.yml    # Your configuration
├── site.yml                  # Your playbook using roles
└── Makefile                  # Your deployment commands
```

## Development / Local Usage

If using this repository directly (not as a collection):

```bash
# Show available targets
make help

# Install all components
make install-all

# Install individually
make install-engine
make install-plugin
make install-cli

# Show version report
make report

# Uninstall
make uninstall-all

# Run tests
make test
```

### Building the Collection

```bash
# Build tarball
make collection-build

# Install locally for testing
make collection-install

# Publish to Galaxy
GALAXY_API_KEY=your_key make collection-publish
```

## Directory Structure

```
tutum-cicd/
├── galaxy.yml                 # Collection metadata
├── version                    # Version file
├── Makefile                   # Build and deployment tasks
├── roles/
│   ├── docker/               # Docker platform roles (docker_tutum_* vars)
│   │   ├── tutum_postgres/   # PostgreSQL database
│   │   ├── tutum_engine/     # Tutum Engine (+ migrations)
│   │   ├── tutum_plugin/     # Volume Plugin
│   │   ├── tutum_cli/        # Admin CLI
│   │   ├── tutum_init/       # Installation file generator
│   │   └── tutum_report/     # Version report
│   └── k8s/                  # Kubernetes roles (k8s_tutum_* vars)
│       ├── tutum_engine/     # Tutum Engine Deployment
│       ├── tutum_csi/        # CSI Driver (controller + node)
│       └── tutum_init/       # K8s playbook generator
├── playbooks/
│   ├── site.yml              # Full stack installation
│   ├── engine.yml            # Engine only
│   ├── plugin.yml            # Plugin only
│   ├── cli.yml               # CLI only
│   ├── report.yml            # Version report
│   └── uninstall.yml         # Full stack uninstall
├── inventory/                 # Local development inventory
└── docs/
    └── examples/
        └── external-project/  # Example external project
```

## Production Deployment

### Generate Secure Keys

```bash
# Generate 32-character keys
openssl rand -base64 32 | head -c 32
```

### Use Ansible Vault

```bash
# Create encrypted vars file
ansible-vault create inventory/group_vars/vault.yml

# Contents:
# docker_tutum_master_key: "your-32-char-key"
# docker_tutum_jwt_secret: "your-32-char-secret"
# docker_tutum_db_password: "secure-password"

# Run with vault
ansible-playbook site.yml --ask-vault-pass
```

## License

MIT
