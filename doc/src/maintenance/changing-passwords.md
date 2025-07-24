# Passwörter rotieren

Jedes Jahr kommt der tolle Moment wo der Rat sich neu konstituiert und alle Passwörter rotiert werden sollten.

Mir ist bewusst das sich all das ein bisschen overkill anfühlt. Aber in diesem Fall ist Vorsicht besser als Nachsicht

Diese Doku hat Lücken, ist aber besser als nichts

## SSH Zugang entfernen

User von Menschen die keinen Zugang mehr haben, sollten aus `nixos/share/users.nix` entfernt werden.

## Sops Secret Keys updaten

ACHTUNG: Vor diesem Schritt sollten Tokens und Passwörter von Diensten geändert werden, siehe unten.

Keys von Menschen die nicht mehr Zugang haben sollten aus `nixos/keys/users/` gelöscht werden und ihr Eintrag aus `.sops.yaml` entfernt werden.

Anschließend sollten alle Keys mit

```
find nixos/secrets -type f -exec sops updatekeys --yes {} \; -exec sops rotate -i {} \;
```

rotiert und updated werden. Es ist zu beachten das das rotieren nur etwas bringt wenn auch ihr Inhalt verändert wird. Neue/Alte User sollten natürlich trozdem hinzugefügt/entfernt werden damit sie (nicht weiterhin) auf neue Secrets Zugang haben.

## OAuth Secrets anpassen

Kein eigener Schritt, wird von Schritten weiter unten referenziert.

1. In Authentik in die Admin Ansicht gehen
2. Unter Applications auf Provider gehen
3. Den gewünschten Provider auswählen
4. Ein neues Secret mit `nix run nixpkgs#pwgen 128 1` generieren
5. Im Provider dies unter Edit Client Secret eintragen
6. Das Secret im entsprechenden Service eintragen (von wo auf mich referenziert wurde)
7. Speichern

## Dienste mit Config Files

### Attic

#### `nixos/secrets/attic.yml`

Den JWT neu generieren mit

```
nix run nixpkgs#openssl -- genrsa -traditional 4096 | base64 -w0
```

und dann das Secret anpassen.

Außerdem müssen Access Tokens ausgetauscht werden:

#### Tokens neu generieren und austauschen

##### Github

Den Token generieren(im atticd container) mit

```
atticd-atticadm make-token --sub "fscs" --validity "1y" --pull "fscs-public" --push "fscs-public"
```

Den resultierenden Token [hier](https://github.com/organizations/fscs/settings/secrets/actions/ATTIC_TOKEN) einfügen

### Authentik

#### `nixos/secrets/authentik.yml`

Der Admin Token mit dem Authentik Cookies signiert sollte abgeändert werden.

```
nix run nixpkgs#pwgen 128 1
```

und dann im secret austauschen.

### Campus Guesser

#### `nixos/secrets/campus-guesser-server.yml`

Das OAuth Secret für den `campus-guesser-oauth` Provider muss angepasst werden. Siehe [hier](#oauth-secrets-anpassen)

### Inphima Discord Bot

#### `nixos/secrets/discord-inphima-bot.yml`

Discord Bots sind doof. Beten das eins [hier](https://discord.com/developers/applications/807762216991850516/bot) Zugriff hat und den Token zurücksetzen. Dann im Secret eintragen

### fscs.hhu.de

#### `nixos/secrets/fscshhude.yml`

Das OAuth Secret für den `FSCS Website` Provider muss angepasst werden. Siehe [hier](#oauth-secrets-anpassen)

Außerdem muss der Signing Key angepasst werden, `nix run nixpkgs#pwgen 128 1` drauf werfen.

### Gitlab Runner

#### `nixos/secrets/gitlab_runner.yml`

Leider müssen alle Runner gelöscht und wieder neu erstellt werden.

Alle Runner brauchen bei `Tags`, `nix` eingetragen. Sonst muss nichts eingetragen werden. Sobald der Runner erstellt wurde kann der Token unter `Step 1` kopiert werden.

Der `fscs` Namespace hat 3 Runner

Der `phynix` Namespace hat 1 Runner

### Immich

#### `nixos/secrets/immich.yml`

Das OAuth Secret für den `immich` Provider muss angepasst werden. Siehe [hier](#oauth-secrets-anpassen)

### Matrix

Hier hatte ich Angst irgendwas anzufassen.

### Nextcloud

Hier hatte ich Angst irgendwas anzufassen. Das Admin Pass zu ändern bringt auch nichts.

### Root Passwörter

#### `nixos/secrets/passwords.yml`

Neu generieren mit

```
bash -c 'pw="$(nix run nixpkgs#pwgen 128 1)"; echo Passwort: $pw; echo -n "Hash: " ;echo -n $pw | mkpasswd -s'
```

Die erste Zeile ist das Klartext Passwort, die zweite Zeile ist die gehashte Version die im Secret eingetragen werden sollte. Der Klartext sollte im Vaultwarden hinterlegt werden.

### Wordpress Seiten

Hier könnte eins das MySql Passwort ändern, das kann eins aber auch lassen. Ist eh nicht exposed.

### Scanner

#### `nixos/secrets/passwords.yml`

Passwort neu generieren, wie bei den Root Passwörtern auch. Dann im Drucker neu eintragen. Weil die Druckertastatur so Arsch ist, das Passwort etwas kürzer

```
bash -c 'pw="$(nix run nixpkgs#pwgen 32 1)"; echo Passwort: $pw; echo -n "Hash: " ;echo -n $pw | mkpasswd -s'
```

### Vaultwarden

#### `nixos/secrets/vaultwarden.yml`

Den Admin Token neu generieren und in Vaultwarden umändern

```
bash -c 'pw="$(nix run nixpkgs#pwgen 64 1)"; echo Passwort: $pw; echo "Hash: " ; echo -n $pw | nix run nixpkgs#libargon2 -- "$(nix run nixpkgs#openssl -- rand -base64 32)" -e -id -k 65540 -t 3 -p 4'
```

#### Nutzer und Berechtigungen

In der Admin Console sollten Menschen die keine Rechte mehr haben entfernt werden. Bei allen anderen muss überprüft werden ob sie noch Zugang zu ihren Collections haben sollten.
