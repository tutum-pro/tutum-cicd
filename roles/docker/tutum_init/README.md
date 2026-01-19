# docker_tutum_init

Rola generująca pliki instalacyjne dla Tutum Platform (playbook i inventory).

## Opis

Rola `docker_tutum_init` automatycznie generuje:
- Plik inventory (`docker.ini`) z konfiguracją hostów
- Playbook instalacyjny (`tutum-install.yml`) z wszystkimi rolami Tutum

## Wymagania

- Ansible >= 2.14
- Kolekcja `tutum_pro.cicd`

## Użycie

Rolę uruchamia się bezpośrednio z linii poleceń:

```bash
# Podstawowe użycie (generuje pliki z domyślnymi ustawieniami)
ansible localhost -m include_role -a name=tutum_pro.cicd.docker.tutum_init

# Z niestandardowymi zmiennymi
ansible localhost -m include_role -a name=tutum_pro.cicd.docker.tutum_init \
  -e docker_tutum_init_target_host=192.168.1.100 \
  -e docker_tutum_init_ansible_connection=ssh

# Z zewnętrzną bazą danych
ansible localhost -m include_role -a name=tutum_pro.cicd.docker.tutum_init \
  -e docker_tutum_init_db_mode=external \
  -e 'docker_tutum_init_external_db_url=postgresql://user:pass@db.example.com:5432/tutum'

# Nadpisanie istniejących plików
ansible localhost -m include_role -a name=tutum_pro.cicd.docker.tutum_init \
  -e docker_tutum_init_overwrite=true

# Niestandardowe ścieżki
ansible localhost -m include_role -a name=tutum_pro.cicd.docker.tutum_init \
  -e docker_tutum_init_inventory_path=environments/prod \
  -e docker_tutum_init_playbook_file=deploy-tutum.yml
```

## Zmienne roli

### Ścieżki plików

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `docker_tutum_init_inventory_path` | `inventory/` | Katalog dla pliku inventory |
| `docker_tutum_init_inventory_file` | `docker.ini` | Nazwa pliku inventory |
| `docker_tutum_init_playbook_file` | `tutum-install.yml` | Nazwa playbooka |
| `docker_tutum_init_overwrite` | `false` | Nadpisz istniejące pliki |

### Konfiguracja hostów

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `docker_tutum_init_target_host` | `localhost` | Host docelowy (IP lub DNS) |
| `docker_tutum_init_target_hostname` | `""` | Nazwa hosta w inventory (domyślnie: target_host) |
| `docker_tutum_init_ansible_connection` | `local` | Typ połączenia: `local` lub `ssh` |
| `docker_tutum_init_ansible_python_interpreter` | `auto` | Interpreter Python (`auto` = autodetekcja) |
| `docker_tutum_init_ansible_user` | `""` | Użytkownik SSH (dla zdalnych hostów) |
| `docker_tutum_init_ansible_ssh_key` | `""` | Ścieżka do klucza SSH |
| `docker_tutum_init_ansible_ssh_pass` | `""` | Hasło SSH (użyj ansible-vault w produkcji) |
| `docker_tutum_init_ansible_become_password` | `""` | Hasło sudo (użyj ansible-vault w produkcji) |

### Wersje komponentów

Te zmienne używają tych samych nazw co inne role (single source of truth):

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `docker_tutum_engine_version` | `5.0.8` | Wersja Tutum Engine |
| `docker_tutum_plugin_version` | `3.0.0` | Wersja Docker Plugin |
| `docker_tutum_cli_version` | `0.2.1` | Wersja Admin CLI |
| `docker_tutum_postgres_version` | `15-alpine` | Wersja PostgreSQL |

### Baza danych

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `docker_tutum_init_db_mode` | `embedded` | Tryb bazy: `embedded` lub `external` |
| `docker_tutum_init_external_db_url` | `""` | URL zewnętrznej bazy (dla trybu external) |
| `docker_tutum_init_db_name` | `tutum` | Nazwa bazy (embedded) |
| `docker_tutum_init_db_user` | `tutum` | Użytkownik bazy (embedded) |
| `docker_tutum_init_db_password` | `tutum` | Hasło bazy (embedded) |
| `docker_tutum_init_db_port` | `5432` | Port bazy danych |

### Porty API

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `docker_tutum_init_rest_port` | `8080` | Port REST API |
| `docker_tutum_init_grpc_port` | `9090` | Port gRPC API |

### Bezpieczeństwo

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `docker_tutum_init_master_key` | `""` | Klucz główny (puste = auto-generowany) |
| `docker_tutum_init_jwt_secret` | `""` | Sekret JWT (puste = auto-generowany) |

### Sudo

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `docker_tutum_init_become` | `true` | Użyj sudo w wygenerowanym playboo |

## Autodetekcja interpretera Python

Rola automatycznie wykrywa ścieżkę do interpretera Python używanego przez Ansible i zapisuje ją w wygenerowanym inventory. Zapewnia to kompatybilność z wirtualnymi środowiskami i niestandardowymi instalacjami Pythona.

Aby użyć konkretnego interpretera:

```bash
ansible localhost -m include_role -a name=tutum_pro.cicd.docker.tutum_init \
  -e docker_tutum_init_ansible_python_interpreter=/path/to/python3
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

# Z hasłem sudo
ansible-playbook -i inventory/docker.ini tutum-install.yml --ask-become-pass

# Z hasłem SSH
ansible-playbook -i inventory/docker.ini tutum-install.yml --ask-pass

# Z Ansible Vault (produkcja)
ansible-playbook -i inventory/docker.ini tutum-install.yml --ask-vault-pass
```

## Licencja

Proprietary - Tutum Pro

## Autor

Tutum Pro Team
