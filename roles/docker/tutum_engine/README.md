# tutum_pro.cicd.docker.tutum_engine

Installs Tutum Engine on Docker. Supports both embedded PostgreSQL (via `tutum_postgres` role) and external PostgreSQL databases.

## Requirements

- Docker installed and running
- Network connectivity to Docker Hub
- PostgreSQL database (embedded via `tutum_postgres` role or external)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_engine_version` | `5.0.8` | Tutum Engine version |
| `docker_tutum_external_db_url` | `""` | External PostgreSQL URL. If set, embedded PostgreSQL is skipped |
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

## Database Modes

### Embedded PostgreSQL (default)

When `docker_tutum_external_db_url` is empty, the `tutum_postgres` role installs PostgreSQL as a Docker container. Database migrations are automatically applied.

```yaml
- hosts: docker_servers
  become: true
  roles:
    - role: tutum_pro.cicd.docker.tutum_postgres
    - role: tutum_pro.cicd.docker.tutum_engine
```

### External PostgreSQL

When `docker_tutum_external_db_url` is set, the role connects to an external PostgreSQL instance. Migrations are still applied automatically.

```yaml
- hosts: docker_servers
  become: true
  roles:
    - role: tutum_pro.cicd.docker.tutum_engine
      vars:
        docker_tutum_external_db_url: "postgres://tutum:password@db.example.com:5432/tutum?sslmode=require"
```

**Note:** When using external PostgreSQL, the `postgresql-client` package will be installed on the target host to run migrations.

## Example Playbook

```yaml
- hosts: docker_servers
  become: true
  roles:
    - role: tutum_pro.cicd.docker.tutum_engine
      vars:
        docker_tutum_engine_version: "5.0.8"
        docker_tutum_master_key: "YourSecure32CharacterKeyHere!!!"
```

## License

MIT
