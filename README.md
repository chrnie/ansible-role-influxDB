# InfluxDB Ansible Playbook

## Übersicht
 Dieses Playbook installiert und konfiguriert **InfluxDB 2.x**, legt Buckets mit Retention an,
 erzeugt pro Bucket einen **Read- und einen Write-Token**, sowie einen **v1-User mit Passwort**.
 Alle erzeugten Daten (Bucket-ID, Tokens, User, Passwörter) werden automatisch in
 `group_vars/all/vault.yml` gespeichert und verschlüsselt.

## Voraussetzungen
 - Ansible >= 2.12
 - Installiertes `community.general` Collection (für Random Passwords):
   ```bash
   ansible-galaxy collection install community.general
   ```
 - `ansible-vault` muss konfiguriert sein (Passwort-Datei oder Prompt).
 - InfluxDB-CLI (`influx`) ist auf dem Target Host verfügbar.

## TLS Zertifikats-Modi
Die Variable `influx_tls_mode` steuert, wie TLS-Zertifikate eingebunden werden:

- `system_sslcert`: Zertifikate liegen im System-Ordner, Gruppe `ssl-cert` erhält Leserechte.
- `system_acl`: Zertifikate liegen im System-Ordner, Leserechte werden per ACL für den InfluxDB-User gesetzt.
- `influx_copy`: Zertifikate werden nach `/etc/influxdb/tls/` kopiert und gehören dem InfluxDB-User.

Beispiel für die Auswahl im `defaults/main.yml`:
```yaml
influx_tls_mode: "system_sslcert"  # oder "system_acl", "influx_copy"
```

## Ausführung
 ```bash
 ansible-playbook site.yml --ask-vault-pass
 ```
 oder mit Passwort-Datei:
 ```bash
 ansible-playbook site.yml --vault-password-file ~/.vault_pass.txt
 ```

## Idempotenz
 - Buckets, Tokens und v1-User werden nur erstellt, wenn sie nicht existieren.
 - Bereits bestehende Einträge werden wiederverwendet.
 - Das Vault-File wird bei jedem Run aktualisiert, und neu verschlüsselt.

## group_vars/all/vault.yml Vorlage
 Damit der erste Run sauber funktioniert, sollte `group_vars/all/vault.yml`
 existieren und mit `ansible-vault create` angelegt werden:

 ```bash
 ansible-vault create group_vars/all/vault.yml
 ```

## Molecule Testumgebung
Die Rolle kann mit [Molecule](https://molecule.readthedocs.io/) auf verschiedenen Distributionen und für alle TLS-Modi getestet werden.

### Vorbereitung
- Stelle sicher, dass Docker installiert ist.
- Erzeuge die Snakeoil-Testzertifikate:
  ```bash
  bash create_snakeoil_certs.sh
  ```

### Testen
Wechsle in das gewünschte OS-Verzeichnis unter `molecule/` und starte die Tests:

```bash
cd molecule/rocky9
molecule test
```
Analog für `ubuntu`, `debian` und `arch`.

Jede Umgebung testet alle vierTLS-Modi (`system_sslcert`, `system_acl`, `influx_copy`, `no_tls`). Die Snakeoil-Zertifikate werden automatisch eingebunden.

Weitere Infos zu Molecule: https://molecule.readthedocs.io/
 ```

 Nach dem ersten erfolgreichen Playbook-Run sieht die Datei etwa so aus:
 ```yaml
 influxdb:
   metrics:
     id: "0a1b2c3d4e5f..."
     retention: "72h"
     read_token: "abcd1234..."
     write_token: "efgh5678..."
     v1_user: "v1user_metrics"
     v1_password: "randomPasswort123"
 ```

## Hinweise
 - Alle Secrets werden mit `ansible-vault` verschlüsselt.
 - Nutze `ansible-vault view group_vars/all/vault.yml`, um die Werte einzusehen.
 - Falls du mehrere Buckets verwaltest, erscheinen sie einfach als weitere Keys unter `influxdb:`.
 - Für ein sicheres Setup solltest du Passwörter **niemals** unverschlüsselt speichern.

