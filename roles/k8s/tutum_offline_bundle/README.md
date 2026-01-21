# tutum_offline_bundle

Prepares an offline installation bundle for air-gapped (disconnected) Tutum Platform deployments on Kubernetes.

## Description

This role creates a complete offline bundle containing:
- All required Docker images (pulled, retagged, and saved as tar files)
- Ansible collection with dependencies
- Installation scripts (load-images.sh, push-images.sh, install-collection.sh)
- Sample inventory pre-configured for internal registry
- Documentation (README.md, images-manifest.yml)

## Requirements

- Docker must be installed and running
- Internet access to pull images and download collections
- Sufficient disk space (typically 1-3 GB depending on configuration)

## Role Variables

### Output Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_offline_output_path` | `./tutum-offline-bundle` | Output directory for bundle |
| `k8s_tutum_offline_archive_name` | `tutum-offline-bundle` | Archive filename prefix |
| `k8s_tutum_offline_archive_timestamp` | `true` | Add date timestamp to archive name |

### Component Selection

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_offline_db_mode` | `embedded` | Database mode: `embedded`, `cnpg`, `external` |
| `k8s_tutum_offline_injection_mode` | `csi` | Injection mode: `csi` or `operator` |
| `k8s_tutum_offline_inventory_path` | `""` | Read versions from existing inventory file |

### Internal Registry

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_offline_internal_registry` | `""` | Internal registry address for retagging |
| `k8s_tutum_offline_internal_prefix` | `tutum` | Prefix for internal registry images |
| `k8s_tutum_offline_save_retagged` | `true` | Save retagged images as separate tar files |

### Collection

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_offline_include_collection` | `true` | Include Ansible collection in bundle |
| `k8s_tutum_offline_collection_name` | `tutum_pro.cicd` | Collection name |
| `k8s_tutum_offline_collection_source` | `galaxy` | Source: `galaxy`, `git`, `local` |
| `k8s_tutum_offline_collection_version` | `""` | Collection version (empty = latest) |

## Usage

### Basic Usage (embedded PostgreSQL + CSI driver)

```bash
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_offline_bundle \
  -e k8s_tutum_offline_output_path=./tutum-bundle
```

### Production Setup (CNPG + Operator)

```bash
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_offline_bundle \
  -e k8s_tutum_offline_output_path=./tutum-bundle \
  -e k8s_tutum_offline_db_mode=cnpg \
  -e k8s_tutum_offline_injection_mode=operator
```

### With Internal Registry

```bash
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_offline_bundle \
  -e k8s_tutum_offline_output_path=./tutum-bundle \
  -e k8s_tutum_offline_internal_registry=registry.example.com \
  -e k8s_tutum_offline_internal_prefix=tutum
```

### From Existing Inventory

```bash
ansible localhost -m include_role -a name=tutum_pro.cicd.k8s.tutum_offline_bundle \
  -e k8s_tutum_offline_output_path=./tutum-bundle \
  -e k8s_tutum_offline_inventory_path=./inventory/k8s.ini
```

## Bundle Contents

```
tutum-offline-bundle/
├── images/                    # Docker images as tar files
│   ├── engine.tar
│   ├── cnpg-operator.tar     # (if db_mode=cnpg)
│   ├── cnpg-postgres.tar     # (if db_mode=cnpg)
│   └── operator.tar          # (if injection_mode=operator)
├── collection/               # Ansible collection
│   ├── tutum_pro-cicd-*.tar.gz
│   └── kubernetes-core-*.tar.gz
├── scripts/
│   ├── load-images.sh       # Load images into Docker
│   ├── push-images.sh       # Push to internal registry
│   └── install-collection.sh
├── images-manifest.yml       # Image manifest
├── sample-inventory.ini      # Pre-configured inventory
└── README.md
```

## Air-Gapped Installation

1. Transfer bundle to air-gapped system
2. Extract: `tar -xzf tutum-offline-bundle-*.tar.gz`
3. Load images: `./scripts/load-images.sh`
4. Push to registry: `./scripts/push-images.sh` (if using internal registry)
5. Install collection: `./scripts/install-collection.sh`
6. Copy and edit `sample-inventory.ini`
7. Run installation playbook

## License

Proprietary

## Author

Tutum Team
