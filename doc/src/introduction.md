# Einführung

Zunächst die Basics. Wir haben 2 Server

- Teefax, unser Hauptserver
- Testfax, unser Testserver (wo wir leider zu wenig testen)

Auf beiden diesen Server läuft [NixOS](https://nixos.org/). Teenix ist die Konfiguration die diese NixOS Systeme beschreibt.

## Übersicht

- Teenix ist (offensichtlich) deklarativ. Wir möchten imperativen Zustand möglichst vermeiden.
- Teenix setzt nicht auf docker, sondern auf [NixOS Container](https://nixos.wiki/wiki/NixOS_Containers). Diese können vollständig aus nix heraus konfiguriert werden und verhalten sich effektiv wie eine NixOS Maschine. Einige Services laufen trotzdem noch in docker, das wollen wir aber langfristig komplett abschaffen.
- Teenix ist "impernanent". Das heißt, das standardmässig alle Dateien bei einem Reboot gelöscht werden. Es ist jedoch möglich Dateien/Ordner als "persistent" zu markieren, diese liegen dann unter `/persist`. Der Vorteil davon ist das das Dateisystem standardmässig aufgeräumt bleibt und sich nicht Müll über Ratsgenerationen ansammelt, von dem niemand weiß ob er noch gebraucht wird.

## Dateistruktur

Keine vollständige Auflistung, dient nur der groben Übersicht

```
├─ doc          - ein mdbook, die dokumentation die du gerade liest
├─ lib          - erweiterung der nixpkgs lib, verfügbar unter lib.teenix
├┬ mod          - das herz von teenix, hier liegen module die zwischen den verschiedenen hosts
││                unterschiedlich konfiguriert werden können.
│└─┬ nixos
│  └── services - die module für all unsere services
├┬ nixos        - konfigurationen der einzelnen hosts
│└─┬ keys       -
│  ├ secrets    - sops secrets
│  ├ teefax     - die konfiguration von teefax
│  ├ testfax    - die konfiguration von testfax
│  └ share      - geteilte konfiguration, sollte in jedem host unbedingt importiert werden
├─ pkgs         - eigene packages
├─ flake.nix    - der "einstieg" in die konfiguration
├─ overlays.nix - nixpkgs overlays
└─ .sops.yaml   - konfigurationsdatei für sops, nur wer hier eingetragen ist kann die secrets lesen
```
