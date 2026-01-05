# Tutum Platform - CI/CD Automation

Ansible automation for deploying and managing the Tutum Platform:
- **Tutum Engine** - Certificate management server with PostgreSQL
- **Tutum CSI Driver** - Docker volume plugin for certificate distribution

## Directory Structure

```
tutum-cicd/
├── ansible.cfg           # Ansible configuration
├── inventory/
│   ├── docker            # Your inventory (create from docker.example)
│   └── docker.example    # Example inventory template
├── group_vars/
│   └── all.yml           # Default variables for all hosts
├── host_vars/            # Per-host variable overrides
├── playbooks/
│   ├── install-tutum-engine.yml    # Install Tutum Engine + PostgreSQL
│   ├── uninstall-tutum-engine.yml  # Remove Tutum Engine + PostgreSQL
│   ├── install-plugin.yml          # Install Docker volume plugin
│   └── uninstall-plugin.yml        # Remove Docker volume plugin
├── files/
│   └── migrations/       # Database migration files
├── roles/                # Custom roles (future)
└── logs/                 # Ansible logs
```

## Quick Start

```bash
# 1. Enter the tutum-cicd directory
cd tutum-cicd

# 2. Create inventory from example
cp inventory/docker.example inventory/docker

# 3. Edit inventory with your hosts
vim inventory/docker

# 4. Test connectivity
ansible all -m ping

# 5. Install Tutum Engine with PostgreSQL
ansible-playbook playbooks/install-tutum-engine.yml

# 6. Install Docker Volume Plugin
ansible-playbook playbooks/install-plugin.yml
```

## Usage

### All commands must be run from the `tutum-cicd` directory!

```bash
cd /path/to/tutum-cicd
```

### Install Tutum Engine

```bash
# With defaults
ansible-playbook playbooks/install-tutum-engine.yml

# With custom variables
ansible-playbook playbooks/install-tutum-engine.yml \
  -e tutum_engine_version=2.1.19 \
  -e db_password=secure_password

# With secure master key (recommended for production)
ansible-playbook playbooks/install-tutum-engine.yml \
  -e tutum_master_key=$(openssl rand -base64 32) \
  -e tutum_jwt_secret=$(openssl rand -base64 32)

# Target specific hosts
ansible-playbook playbooks/install-tutum-engine.yml --limit production
```

### Install Docker Volume Plugin

```bash
# With defaults
ansible-playbook playbooks/install-plugin.yml

# With custom Tutum Engine URL
ansible-playbook playbooks/install-plugin.yml \
  -e tutum_engine_url=tutum-engine.local:9090

# Specific version
ansible-playbook playbooks/install-plugin.yml \
  -e plugin_version=2.1.5
```

### Uninstall

```bash
# Remove Tutum Engine (keep data)
ansible-playbook playbooks/uninstall-tutum-engine.yml

# Remove Tutum Engine and data (DESTRUCTIVE!)
ansible-playbook playbooks/uninstall-tutum-engine.yml -e remove_data=true

# Remove plugin (keep volumes)
ansible-playbook playbooks/uninstall-plugin.yml

# Remove plugin and volumes
ansible-playbook playbooks/uninstall-plugin.yml -e remove_volumes=true
```

## Configuration

### Inventory

Edit `inventory/docker` to define your target hosts:

```ini
[docker_hosts]
server1 ansible_host=192.168.1.100
server2 ansible_host=192.168.1.101

[docker_hosts:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Variables

Default variables are in `group_vars/all.yml`. Override them:

1. **In inventory** - for group-specific settings
2. **In host_vars/** - for per-host settings
3. **On command line** - with `-e variable=value`

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `tutum_engine_version` | `2.1.19` | Tutum Engine version |
| `postgres_version` | `15-alpine` | PostgreSQL version |
| `db_name` | `tutum` | Database name |
| `db_user` | `tutum` | Database user |
| `db_password` | `tutum` | Database password |
| `tutum_master_key` | (auto-gen) | Encryption master key |
| `tutum_jwt_secret` | (auto-gen) | JWT signing secret |
| `tutum_rest_port` | `8080` | REST API port |
| `tutum_grpc_port` | `9090` | gRPC API port |
| `plugin_version` | `2.1.5` | CSI Driver version |
| `tutum_engine_url` | `localhost:9090` | Engine URL for plugin |

## Production Deployment

### 1. Generate Secure Keys

```bash
# Generate master key
export TUTUM_MASTER_KEY=$(openssl rand -base64 32)
echo "Master Key: $TUTUM_MASTER_KEY"

# Generate JWT secret
export TUTUM_JWT_SECRET=$(openssl rand -base64 32)
echo "JWT Secret: $TUTUM_JWT_SECRET"
```

### 2. Use Ansible Vault (Recommended)

```bash
# Create encrypted vars file
ansible-vault create group_vars/production/vault.yml

# Add secrets:
# tutum_master_key: "your-secure-key"
# tutum_jwt_secret: "your-jwt-secret"
# db_password: "your-db-password"

# Run with vault
ansible-playbook playbooks/install-tutum-engine.yml \
  --limit production \
  --ask-vault-pass
```

### 3. Deploy

```bash
ansible-playbook playbooks/install-tutum-engine.yml --limit production
ansible-playbook playbooks/install-plugin.yml --limit production
```

## Troubleshooting

### Test Connectivity

```bash
ansible all -m ping
```

### Check Services

```bash
# All containers
ansible all -m shell -a "docker ps"

# Tutum Engine health
ansible all -m shell -a "curl -s http://localhost:8080/health"

# Plugin status
ansible all -m shell -a "docker plugin ls"
```

### View Logs

```bash
# Tutum Engine logs
ansible all -m shell -a "docker logs tutum-engine --tail 50"

# PostgreSQL logs
ansible all -m shell -a "docker logs tutum-postgres --tail 50"

# Ansible logs
cat logs/ansible.log
```

### Migration Status

```bash
ansible all -m shell -a "docker exec tutum-postgres psql -U tutum -d tutum -c 'SELECT * FROM schema_migrations;'"
```

## CI/CD Integration

### GitLab CI

```yaml
deploy:
  stage: deploy
  image: ansible/ansible-runner
  script:
    - cd tutum-cicd
    - ansible-playbook playbooks/install-tutum-engine.yml
    - ansible-playbook playbooks/install-plugin.yml
```

### GitHub Actions

```yaml
- name: Deploy Tutum Platform
  run: |
    cd tutum-cicd
    ansible-playbook playbooks/install-tutum-engine.yml
    ansible-playbook playbooks/install-plugin.yml
  env:
    ANSIBLE_HOST_KEY_CHECKING: 'false'
```

## File Locations

After installation:

| Component | Location |
|-----------|----------|
| PostgreSQL data | `/var/lib/tutum/postgres` |
| Migrations | `/etc/tutum/migrations` |
| Volume data | `/var/lib/tutum/volumes` |
| Logs | `journalctl -u docker` |
