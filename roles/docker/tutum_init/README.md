# tutum_init

Rola generująca pliki instalacyjne dla Tutum Platform (playbook i inventory).

## Opis

Rola `tutum_init` automatycznie generuje:
- Plik inventory (`docker.ini`) z konfiguracją hostów
- Playbook instalacyjny (`tutum-install.yml`) z wszystkimi rolami Tutum

## Wymagania

- Ansible >= 2.14
- Kolekcja `tutum_pro.cicd`

## Zmienne roli

### Ścieżki plików

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `tutum_init_inventory_path` | `inventory/` | Katalog dla pliku inventory |
| `tutum_init_inventory_file` | `docker.ini` | Nazwa pliku inventory |
| `tutum_init_playbook_file` | `tutum-install.yml` | Nazwa playbooka |
| `tutum_init_overwrite` | `false` | Nadpisz istniejące pliki |

### Konfiguracja hostów

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `tutum_init_target_host` | `localhost` | Host docelowy |
| `tutum_init_ansible_connection` | `local` | Typ połączenia Ansible |
| `tutum_init_ansible_python_interpreter` | `/usr/bin/python3` | Interpreter Python |

### Wersje komponentów

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `tutum_init_engine_version` | `3.3.5` | Wersja Tutum Engine |
| `tutum_init_plugin_version` | `2.1.6` | Wersja Docker Plugin |
| `tutum_init_cli_version` | `0.1.76` | Wersja Admin CLI |
| `tutum_init_postgres_version` | `15-alpine` | Wersja PostgreSQL |

### Baza danych

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `tutum_init_db_mode` | `embedded` | Tryb bazy: `embedded` lub `external` |
| `tutum_init_external_db_url` | `""` | URL zewnętrznej bazy (dla trybu external) |
| `tutum_init_db_name` | `tutum` | Nazwa bazy (embedded) |
| `tutum_init_db_user` | `tutum` | Użytkownik bazy (embedded) |
| `tutum_init_db_password` | `tutum` | Hasło bazy (embedded) |
| `tutum_init_db_port` | `5432` | Port bazy danych |

### Porty API

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `tutum_init_rest_port` | `8080` | Port REST API |
| `tutum_init_grpc_port` | `9090` | Port gRPC API |

### Bezpieczeństwo

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `tutum_init_master_key` | `""` | Klucz główny (puste = auto-generowany) |
| `tutum_init_jwt_secret` | `""` | Sekret JWT (puste = auto-generowany) |

## Przykłady użycia

### Podstawowe użycie (localhost)

```yaml
- name: Generate Tutum installation files
  hosts: localhost
  connection: local
  roles:
    - role: tutum_pro.cicd.docker.tutum_init
```

### Zdalna instalacja

```yaml
- name: Generate Tutum installation files
  hosts: localhost
  connection: local
  roles:
    - role: tutum_pro.cicd.docker.tutum_init
      tutum_init_target_host: "192.168.1.100"
      tutum_init_ansible_connection: "ssh"
```

### Z zewnętrzną bazą danych

```yaml
- name: Generate Tutum installation files
  hosts: localhost
  connection: local
  roles:
    - role: tutum_pro.cicd.docker.tutum_init
      tutum_init_db_mode: "external"
      tutum_init_external_db_url: "postgresql://user:pass@db.example.com:5432/tutum"
```

### Niestandardowe ścieżki

```yaml
- name: Generate Tutum installation files
  hosts: localhost
  connection: local
  roles:
    - role: tutum_pro.cicd.docker.tutum_init
      tutum_init_inventory_path: "environments/production"
      tutum_init_inventory_file: "hosts.ini"
      tutum_init_playbook_file: "deploy-tutum.yml"
```

## Wygenerowane pliki

Po uruchomieniu roli zostaną utworzone:

1. **Inventory** (`inventory/docker.ini`):
   ```ini
   [docker_servers]
   localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
   ```

2. **Playbook** (`tutum-install.yml`):
   - Instalacja PostgreSQL (jeśli tryb embedded)
   - Instalacja Tutum Engine
   - Instalacja Docker Plugin
   - Instalacja Admin CLI

## Instalacja Tutum Platform

Po wygenerowaniu plików:

```bash
# Instalacja
ansible-playbook -i inventory/docker.ini tutum-install.yml

# Z Ansible Vault (produkcja)
ansible-playbook -i inventory/docker.ini tutum-install.yml --ask-vault-pass
```

## Licencja

Proprietary - Tutum Pro

## Autor

Tutum Pro Team
