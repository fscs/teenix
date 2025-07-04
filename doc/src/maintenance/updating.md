# Updating

Es gibt 2 Größenordnungen von Updates:
- Update eines spezifischen Inputs (z.B. nur die Fachschafts Website)
    - meist trivial (außer bei `nixpkgs` aus offensichtlichen Gründen)
    - kann meistens mal kurz nebenbei geschehen
- Update aller Inputs
    - hier gehen meistens Dinge kaputt
    - man sollte Zeit zum troubleshooten mitbringen

## Update eines einzelnen Inputs

Die Namen der Inputs stehen entweder in der `flake.nix` oder einfach per `<TAB>` completion.

```
nix flake update <input>
```

und dann deployen.

## Update aller Inputs

```
nix flake update
```

und dann deployen.

## Nach einem Update

Gucken ob alles noch funktioniert.

- Auf [status.phynix-hhu.de](https://status.phynix-hhu.de). Ist manchmal etwas hinterher, also direkt nach einem Update vielleicht nicht zuverlässig
- Im Grafana Dashboard unter traefik gibt es eine live Aufschlüsselung
- Nextcloud? 
    - funktioniert Nexcloud Office noch? Gibt es [hier](https://nextcloud.phynix-hhu.de/apps/files/files/2513698?dir=%2FInformatik&openfile=true) ein Preview?
- [Nawi Website](https://fsnawi.de)? Die Healthchecken wir nicht
- Matrix
    - [Federation Tester](https://federationtester.matrix.org/#inphima.de)
    - Einfach mal nen Client öffnen und irgendwie "test" in Server Admin interna schreiben

## Troubleshooting

### Too many open Files

In die Ecke setzen und weinen. Dann Arthur schreiben, dey kommt dazu und weint mit.
