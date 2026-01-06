# External Project Using tutumpro.cicd Collection

This is an example of how to use the `tutumpro.cicd` Ansible collection
in your own project.

## Quick Start

1. **Install the collection**

   ```bash
   # From Ansible Galaxy (after publishing)
   ansible-galaxy collection install tutumpro.cicd

   # Or from Git
   ansible-galaxy collection install git+https://github.com/tutum/tutum-cicd.git

   # Or using requirements.yml
   ansible-galaxy collection install -r requirements.yml
   ```

2. **Configure your inventory**

   Edit `inventory/hosts.yml` with your target servers.

3. **Configure variables**

   Edit `inventory/group_vars/all.yml` with your settings.
   **Important**: Change security keys for production!

4. **Deploy**

   ```bash
   make deploy
   ```

## Available Make Targets

| Target | Description |
|--------|-------------|
| `deploy` | Install all Tutum Pro components |
| `deploy-engine` | Install only Tutum Engine |
| `deploy-plugin` | Install only Docker plugin |
| `deploy-cli` | Install only Admin CLI |
| `report` | Show version report |
| `uninstall` | Remove all components |
| `uninstall-data` | Remove all components and data |

## Using Roles Directly

You can also use the roles directly in your playbooks:

```yaml
- name: My Custom Deployment
  hosts: docker_servers
  become: true

  vars:
    tutum_engine_version: "3.3.5"
    tutum_master_key: "MySecure32CharacterKeyHere!!!!"
    tutum_log_level: "debug"

  roles:
    - role: tutumpro.cicd.docker.tutum_engine
    - role: tutumpro.cicd.docker.tutum_plugin
      vars:
        tutum_engine_url: "{{ ansible_host }}:9090"
```

## Available Variables

See `inventory/group_vars/all.yml` for all available configuration options.

## Future: Kubernetes Support

In the future, roles in `k8s` namespace will be available for Kubernetes deployments:

```yaml
roles:
  - role: tutumpro.cicd.k8s.tutum_engine
  - role: tutumpro.cicd.k8s.tutum_csi_driver
```
