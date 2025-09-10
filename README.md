
# InfluxDB Ansible Playbook

## Overview
This playbook installs and configures **InfluxDB 2.x**, creates buckets with retention, generates a **read and write token** for each bucket, and a **v1 user with password**. All generated data (bucket ID, tokens, user, passwords) are automatically stored and encrypted in `group_vars/all/vault.yml`.

## Requirements
- Ansible >= 2.12
- Installed `community.general` collection (for random passwords):
  ```bash
  ansible-galaxy collection install community.general
  ```
- `ansible-vault` must be configured (password file or prompt).
- InfluxDB CLI (`influx`) must be available on the target host.

## TLS Certificate Modes
The variable `influx_tls_mode` controls how TLS certificates are integrated:

- `system_sslcert`: Certificates are in the system folder, group `ssl-cert` gets read access.
- `system_acl`: Certificates are in the system folder, read access is set via ACL for the InfluxDB user.
- `influx_copy`: Certificates are copied to `/etc/influxdb/tls/` and owned by the InfluxDB user.

Example selection in `defaults/main.yml`:
```yaml
influx_tls_mode: "system_sslcert"  # or "system_acl", "influx_copy"
```

## Usage
```bash
ansible-playbook site.yml --ask-vault-pass
```
or with password file:
```bash
ansible-playbook site.yml --vault-password-file ~/.vault_pass.txt
```

## Idempotency
- Buckets, tokens, and v1 users are only created if they do not exist.
- Existing entries are reused.
- The vault file is updated and re-encrypted on every run.

## group_vars/all/vault.yml Template
To ensure the first run works cleanly, `group_vars/all/vault.yml` should exist and be created with `ansible-vault create`:

```bash
ansible-vault create group_vars/all/vault.yml
```

## Molecule Test Environment
The role can be tested with [Molecule](https://molecule.readthedocs.io/) on various distributions and for all TLS modes.

### Preparation
- Make sure Docker is installed.
- Generate the snakeoil test certificates:
  ```bash
  bash create_snakeoil_certs.sh
  ```

### Testing
Change to the desired OS directory under `molecule/` and start the tests:

```bash
cd molecule/rocky9
molecule test
```
Analogously for `ubuntu`, `debian`, and `arch`.

Each environment tests all four TLS modes (`system_sslcert`, `system_acl`, `influx_copy`, `no_tls`). The snakeoil certificates are automatically included.

More info on Molecule: https://molecule.readthedocs.io/

After the first successful playbook run, the file will look like this:
```yaml
influxdb:
  metrics:
    id: "0a1b2c3d4e5f..."
    retention: "72h"
    read_token: "abcd1234..."
    write_token: "efgh5678..."
    v1_user: "v1user_metrics"
    v1_password: "randomPassword123"
```

## Notes
- All secrets are encrypted with `ansible-vault`.
- Use `ansible-vault view group_vars/all/vault.yml` to view the values.
- If you manage multiple buckets, they will appear as additional keys under `influxdb:`.
- For a secure setup, you should **never** store passwords unencrypted.

