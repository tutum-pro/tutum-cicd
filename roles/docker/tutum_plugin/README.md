# tutum_pro.cicd.docker.tutum_plugin

Installs Tutum Docker Volume Plugin for certificate management.

## Requirements

- Docker installed and running
- Tutum Engine running and accessible
- Network connectivity to Docker Hub

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_plugin_version` | `3.0.0` | Plugin version |
| `docker_tutum_engine_url` | `localhost:9090` | Tutum Engine gRPC URL |
| `docker_tutum_volume_dir` | `/var/lib/tutum/volumes` | Volume mount directory |
| `docker_tutum_log_level` | `info` | Log level |
| `docker_tutum_plugin_state` | `present` | `present` or `absent` |
| `docker_tutum_plugin_remove_volumes` | `false` | Remove volumes on uninstall |

## Example Playbook

```yaml
- hosts: docker_servers
  become: true
  roles:
    - role: tutum_pro.cicd.docker.tutum_plugin
      vars:
        docker_tutum_engine_url: "localhost:9090"
```

## License

MIT
