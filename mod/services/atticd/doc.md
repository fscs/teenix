# Attic

Ein Nix Binary Cache. Hier liegen selbst geschriebene Projekte von uns in gebauter Form, damit eins das nicht immer selbst machen muss.

## Administration

Um Attic zu konfigurieren braucht eins einen Access Token. Diese sollten immer nur on-demand erstellt werden.

Dazu muss eins im `atticd` container den Token erstellen

```
atticd-atticadm make-token --sub admin --validity "1 hour" --create-cache \* --pull \* --push \* --delete  \* --configure-cache \* --configure-cache-retention \* --destroy-cache \*
```

Im Output steht jetzt eine komische Fehlermeldung, aber auch der Access Token.

Dann lokal eine nix-shell mit `attic-client` öffnen und sich einloggen

```
attic login fscs https://attic.hhu-fscs.de DER_TOKEN
```
