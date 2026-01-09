# tutum_pro.cicd.docker.tutum_cli

Installs Tutum Admin CLI container for certificate management operations.

## Requirements

- Docker installed and running
- Tutum Engine running and accessible
- Network connectivity to Docker Hub

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_cli_version` | `0.2.0` | CLI version |
| `docker_tutum_cli_container_name` | `tutum-admin-cli` | Container name |
| `docker_tutum_engine_url` | `localhost:9090` | Tutum Engine gRPC URL |
| `docker_tutum_cli_state` | `present` | `present` or `absent` |

## Example Playbook

```yaml
- hosts: docker_servers
  become: true
  roles:
    - role: tutum_pro.cicd.docker.tutum_cli
      vars:
        docker_tutum_engine_url: "localhost:9090"
```

## Usage

After installation, use the CLI via docker exec:

```bash
docker exec tutum-admin-cli tutum-admin-cli --help
docker exec tutum-admin-cli tutum-admin-cli cert list --server localhost:9090
docker exec tutum-admin-cli tutum-admin-cli namespace list --server localhost:9090
```

## License

MIT
