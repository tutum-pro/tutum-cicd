# tutum_pro.cicd.docker.tutum_report

Generates a version report of installed Tutum Docker components.

## Requirements

- Docker installed and running

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_engine_version` | `3.3.5` | Expected Engine version |
| `docker_tutum_cli_version` | `0.1.76` | Expected CLI version |
| `docker_tutum_plugin_version` | `2.1.6` | Expected Plugin version |
| `docker_tutum_postgres_version` | `15-alpine` | Expected PostgreSQL version |

## Example Playbook

```yaml
- hosts: docker_servers
  become: true
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
