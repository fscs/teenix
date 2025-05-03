# Teenix Containers

Wie bereits erwähnt benutzt Teenix sehr viele NixOS Container. Um uns die Arbeit etwas einfacher zu machen haben wir uns ein eigenes Modul geschrieben was die `containers` und `teenix.persist` Optionen "wrapped" um häufige Konfigurationen umzusetzen.

<!-- toc -->

## Überblick

Diese Defaults sind:

- Den Container Autostarten
- Das Dateisystem des Containers ephemeral (nicht-persistent) zu machen
- Dem Container ein eigenes Netzwerk Interface zu geben und diesem IPs zuzuordnen
- Das Journal (Logs) des Containers in `/var/log/containers` verfügbar zu machen

Auf Bedarf kann auch:

- Dem Container DNS Zugriff gewährt werden (standardmässig ist das nämlich nicht der Fall)
- Ein Subvolume in `/persist/<container-name>` für persistente Daten erstellt werden
- Standard Ordner von Datenbanken (postgres, mysql) dorthin mounten
- Die "data dir" des containers dorthin gemounted werden (`/var/lib/<container-name>`)
- TCP/UDP Ports in der Firewall des Containers geöffnet werden
- Sops Secrets/Templates an den Container weitergereicht werden (damit der Container die Schlüssel nicht kennt)
