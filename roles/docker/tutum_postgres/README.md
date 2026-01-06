# tutum_pro.cicd.docker.tutum_postgres

Installs PostgreSQL database for Tutum Engine on Docker.

## Requirements

- Docker installed and running
- Network connectivity to Docker Hub

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_tutum_postgres_version` | `15-alpine` | PostgreSQL version |
| `docker_tutum_postgres_container_name` | `tutum-postgres` | Container name |
| `docker_tutum_db_name` | `tutum` | Database name |
| `docker_tutum_db_user` | `tutum` | Database user |
| `docker_tutum_db_password` | `tutum` | Database password |
| `docker_tutum_db_port` | `5432` | PostgreSQL port |
| `docker_tutum_postgres_state` | `present` | `present` or `absent` |
| `docker_tutum_postgres_remove_data` | `false` | Remove data on uninstall |

## Example Playbook

```yaml
- hosts: docker_servers
  become: true
  roles:
    - role: tutum_pro.cicd.docker.tutum_postgres
      vars:
        docker_tutum_db_password: "secure-password"
```

## License

MIT
