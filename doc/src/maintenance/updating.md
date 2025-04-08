# Updating

## Schritt 1

Update eines spezifischen Inputs (z.B. nur die Fachschafts Website). Die Namen der Inputs stehen entweder in der `flake.nix` oder einfach per `<TAB>` completion.

```
nix flake update <input>
```

Vollständiges Update. Wahrhscheinlich nicht so ganz trivial, hier sollte man sich auf jeden Fall darauf einstellen danach noch etwas zu debuggen.

```
nix flake update
```

Manche Services (wie z.B. `nextcloud`) haben die `package` option gesetzt so das sie nicht immer automatisch
geupdatet werden.

## Schritt 2

Überprüfen ob alles noch da ist und funktioniert. Besondere Kandidaten sind hier:

- Nextcloud
- Traefik (obwohl das ziemlich offensichtlich ist, weil gar nichts mehr geht)
