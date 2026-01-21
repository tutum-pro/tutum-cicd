# tutum_manifests

Generate all Kubernetes manifests for Tutum Platform deployment.

## Description

This role generates static YAML manifests for deploying Tutum Platform to Kubernetes. Unlike the deployment roles that apply manifests directly, this role outputs files to a specified directory for manual review, GitOps workflows, or custom deployment pipelines.

## Features

- **Database modes**: embedded PostgreSQL, CloudNativePG (CNPG), or external database
- **Injection modes**: CSI driver or Kubernetes operator
- **Distribution support**: standard K8s, MicroK8s, K3s, RKE2, OpenShift
- **Kustomize ready**: generates `kustomization.yaml` for easy deployment
- **Customizable**: all component versions, resources, and configurations are parameterizable

## Requirements

- Ansible 2.14+

## Usage

### Basic usage (embedded PostgreSQL + operator)

```yaml
- name: Generate Tutum Platform manifests
  hosts: localhost
  tasks:
    - name: Generate manifests
      ansible.builtin.include_role:
        name: tutum_pro.cicd.k8s.tutum_manifests
      vars:
        k8s_tutum_manifests_output_path: "./manifests"
        k8s_tutum_manifests_db_mode: "embedded"
        k8s_tutum_manifests_injection_mode: "operator"
```

### Production setup (CNPG + operator)

```yaml
- name: Generate production manifests
  hosts: localhost
  tasks:
    - name: Generate manifests
      ansible.builtin.include_role:
        name: tutum_pro.cicd.k8s.tutum_manifests
      vars:
        k8s_tutum_manifests_output_path: "./prod-manifests"
        k8s_tutum_manifests_db_mode: "cnpg"
        k8s_tutum_manifests_injection_mode: "operator"
        k8s_tutum_cnpg_instances: 3
        k8s_tutum_cnpg_storage_size: "20Gi"
        k8s_tutum_master_key: "{{ vault_tutum_master_key }}"
        k8s_tutum_jwt_secret: "{{ vault_tutum_jwt_secret }}"
```

### OpenShift deployment

```yaml
- name: Generate OpenShift manifests
  hosts: localhost
  tasks:
    - name: Generate manifests
      ansible.builtin.include_role:
        name: tutum_pro.cicd.k8s.tutum_manifests
      vars:
        k8s_tutum_manifests_output_path: "./openshift-manifests"
        k8s_distribution: "openshift"
        k8s_tutum_manifests_ingress_enabled: true
        k8s_tutum_engine_route_host: "tutum.apps.example.com"
```

### CLI usage

```bash
# Generate with defaults
ansible-playbook tutum_pro.cicd.k8s.tutum_manifests \
  -e k8s_tutum_manifests_output_path=./manifests

# Generate with CNPG and operator
ansible-playbook tutum_pro.cicd.k8s.tutum_manifests \
  -e k8s_tutum_manifests_output_path=./manifests \
  -e k8s_tutum_manifests_db_mode=cnpg \
  -e k8s_tutum_manifests_injection_mode=operator

# Generate for OpenShift with Route
ansible-playbook tutum_pro.cicd.k8s.tutum_manifests \
  -e k8s_tutum_manifests_output_path=./manifests \
  -e k8s_distribution=openshift \
  -e k8s_tutum_manifests_ingress_enabled=true
```

## Applying Manifests

After generation, apply manifests using kustomize:

```bash
kubectl apply -k ./manifests
```

Or apply individually in order:

```bash
kubectl apply -f ./manifests/00-namespace.yml
kubectl apply -f ./manifests/1*.yml   # Database
kubectl apply -f ./manifests/2*.yml   # Engine
kubectl apply -f ./manifests/3*.yml   # CSI/Operator
```

## Role Variables

### Output Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_manifests_output_path` | `./manifests` | Directory for generated manifests |
| `k8s_tutum_manifests_create_dir` | `true` | Create output directory if not exists |
| `k8s_tutum_manifests_overwrite` | `false` | Overwrite existing files |

### Component Selection

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_manifests_db_mode` | `embedded` | Database mode: `embedded`, `cnpg`, `external` |
| `k8s_tutum_manifests_injection_mode` | `operator` | Injection mode: `csi`, `operator` |
| `k8s_tutum_manifests_ingress_enabled` | `false` | Generate Ingress/Route manifests |
| `k8s_distribution` | `standard` | K8s distribution: `standard`, `microk8s`, `k3s`, `rke2`, `openshift` |

### Namespace

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_namespace` | `tutum-system` | Namespace for Tutum components |
| `k8s_tutum_cnpg_namespace` | `pgdb` | Namespace for CNPG cluster |

### Component Versions

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_version` | `5.1.5` | Tutum Engine version |
| `k8s_tutum_csi_version` | `4.0.1` | CSI driver version |
| `k8s_tutum_operator_version` | `0.1.11` | Operator version |
| `k8s_tutum_postgres_version` | `15-alpine` | Embedded PostgreSQL version |
| `k8s_tutum_cnpg_operator_version` | `1.25.0` | CNPG operator version |
| `k8s_tutum_cnpg_postgres_version` | `16` | CNPG PostgreSQL version |

### Security Keys

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_master_key` | auto-generated | AES-256 master key (32 chars) |
| `k8s_tutum_jwt_secret` | auto-generated | JWT signing secret (32 chars) |

### Database Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_db_name` | `tutum` | Database name |
| `k8s_tutum_db_user` | `tutum` | Database user |
| `k8s_tutum_db_password` | `tutum` | Database password |

### Ingress/Route Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_tutum_engine_ingress_host` | `""` | Ingress hostname |
| `k8s_tutum_engine_ingress_path` | `/api` | Ingress path |
| `k8s_tutum_engine_route_host` | `""` | OpenShift Route hostname |
| `k8s_tutum_engine_route_termination` | `edge` | TLS termination: `edge`, `passthrough`, `reencrypt` |

## Generated Files

| File | Description |
|------|-------------|
| `00-namespace.yml` | Tutum namespace |
| `10-*.yml` | Database manifests (PostgreSQL or CNPG) |
| `20-engine-*.yml` | Tutum Engine manifests |
| `25-engine-ingress.yml` | Ingress (standard K8s) |
| `25-engine-route.yml` | Route (OpenShift) |
| `30-csi-*.yml` | CSI driver manifests |
| `30-operator-*.yml` | Operator manifests |
| `kustomization.yaml` | Kustomize configuration |

## License

MIT
