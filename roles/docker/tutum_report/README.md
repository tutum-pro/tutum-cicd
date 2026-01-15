# tutum_pro.cicd.docker.tutum_report

Generates a version report of installed Tutum Docker components.

## Requirements

- Docker installed and running

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_cicd_version` | (auto-detected) | CI/CD collection version |
| `docker_tutum_plugin_image` | `tutumpro/tutum-csi-driver-docker` | Plugin Docker image name |

**Note:** This role does NOT define default versions for components. Version variables
(`docker_tutum_engine_version`, `docker_tutum_cli_version`, etc.) should be set in
your inventory or passed when running the playbook. This ensures a single source of
truth for version numbers across all roles.

## Example Playbook

```yaml
- hosts: docker_servers
  become: true
  vars:
    # Set expected versions for comparison
    docker_tutum_engine_version: "5.0.8"
    docker_tutum_cli_version: "0.2.1"
    docker_tutum_plugin_version: "3.0.0"
  roles:
    - role: tutum_pro.cicd.docker.tutum_report
```

## Output

The role outputs a report showing:
- Installed component versions
- Expected vs actual version comparison
- Container status

## License

MIT
