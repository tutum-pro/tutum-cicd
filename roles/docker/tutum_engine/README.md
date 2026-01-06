# tutum_pro.cicd.docker.tutum_engine

Installs Tutum Engine with PostgreSQL database on Docker.

## Requirements

- Docker installed and running
- Network connectivity to Docker Hub

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_engine_version` | `3.3.5` | Tutum Engine version |
| `docker_tutum_postgres_version` | `15-alpine` | PostgreSQL version |
| `docker_tutum_db_name` | `tutum` | Database name |
| `docker_tutum_db_user` | `tutum` | Database user |
| `docker_tutum_db_password` | `tutum` | Database password |
| `docker_tutum_master_key` | (generated) | 32-char AES-256 encryption key |
| `docker_tutum_jwt_secret` | (generated) | 32-char JWT secret |
| `docker_tutum_rest_port` | `8080` | REST API port |
| `docker_tutum_grpc_port` | `9090` | gRPC API port |
| `docker_tutum_log_level` | `info` | Log level |
| `docker_tutum_engine_state` | `present` | `present` or `absent` |
| `docker_tutum_engine_remove_data` | `false` | Remove data on uninstall |

## Example Playbook

```yaml
- hosts: docker_servers
  become: true
  roles:
    - role: tutum_pro.cicd.docker.tutum_engine
      vars:
        docker_tutum_engine_version: "3.3.5"
        docker_tutum_master_key: "YourSecure32CharacterKeyHere!!!"
```

## License

MIT
