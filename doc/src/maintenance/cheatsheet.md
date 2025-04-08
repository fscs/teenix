# Command Cheatsheet

<!-- toc -->

## Services

Der Service Name ist meistens am besten per `<TAB>` herauszufinden. (Außer bei journalctl, dessen completion ist etwas kaputt)

### Liste aller Services

Mit `/` kann man in dieser Liste auch suchen.

```
systemctl -atservice
```

### Status eines Service

```
systemctl status <service>
```

### Service Starten/Stoppen

```
sudo systemctl stop <service>
sudo systemctl start <service>
sudo systemctl restart <service>
```

### Logs

Das `-e` springt an das Ende des Logs (was man ja meistens auch möchte). Falls dies nicht gewünscht ist, das `-e` einfach weglassen

```
journalctl -xe
```

Um den Log kontinuierlich zu sehene (neue einträge werden sofort angezeigt)

```
journalctl -xf
```

### Logs eine spezifischen Services

```
journalctl -xeu <service>
```

Auch diese kann man kontinuierlich anzeigen lassen

```
journalctl -xfu <service>
```

## NixOS-Container

### Container auflisten

Reine Auflistung

```
nixos-container list
```

Etwas detailreicher, Machines ist ein anderes Wort für Container

```
machinectl
```

### Container Starten/Stoppen

```
sudo nixos-container stop <container>
sudo nixos-container start <container>
sudo nixos-container restart <container>
```

### In einen Container einloggen

```
sudo nixos-container root-login <container>
```

### Logs eines Containers

```
sudo journalctl -xeM <container>
```

(Oder im Grafana)

## Sops

### Secret Keys updaten

Synchronisiert alle secrets mit `.sops.yaml` und rotiert ihre encryption keys

```
find nixos/secrets -type f -exec sops updatekeys --yes {} \; -exec sops rotate -i {} \;
```
