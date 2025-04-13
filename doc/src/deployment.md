# Deploy A New Service

## Repository Struktur
Um einen neuen Service zu deployen sollte man unter mod/nixos/services eine Datei erstellen, 
welche den Service am besten über einen NixOS Container deployed.
Die wenigsten Services sollten auf Teefax selbst laufen. sollte der Service nicht 
in eine Datei sinnvoll strukturiert werden können, so sollte der service in einen
Ordner verschoben werden. Die Struktur in dem Ordner sollte z.B. wie folgt aussehen:
```
Servicename
| -> default.nix
| -> container.nix
```

## Deployen eines Beispiel Services
Wenn man die wie in Repository Struktur beschriebene Ordnerstruktur erstellt hat,
so werden die Dateien automatisch geladen und sind verfügbar. Um die Services 
konfigurierbar zu machen sollte man also umbeding auf Options setzen. Einige
Beispiel Options die wir fast immer haben sind:
- Enable (enable)
- Hostname (hostname)
- Environment File (secretFile)

```nix
options.teenix.services.vaultwarden = {
  enable = lib.mkEnableOption "setup vaultwarden";
  hostname = lib.teenix.mkHostnameOption;
  secretsFile = lib.teenix.mkSecretsFileOption "vaultwarden";
};
```

Die reguläre NixOS config kann nun in eien config block geschreieben werden.
```nix
config =
let
  opts = config.teenix.services.vaultwarden;
in
lib.mkIf opts.enable {
  ...
}
```

Wir verwenden Sops um Secrets zu verschlüsseln und zu verwalten. Um diese einzubinden,
muss das secret in die NixOS config eingebunden werden. [Hier Doku](https://github.com/Mic92/sops-nix)

**Wichtig**
Um die secrets für alle entschlüsselbar zu machen, muss gpgagent installiert sein und laufen. 
Des weiteren muss die [devSell](https://nixos.wiki/wiki/Development_environment_with_nix-shell)
genutz werden, damit alle Keys der User als auch die von Teefax geladen werden.

### NixOS Container
Um die Verwaltung der NixOS Container zu verbessern, haben wir ein eigenes Container Module
geschrieben. dieses verwaltet die IP Pools und sämtliche Grundfunktionen, die die meisten
unserer Container brauchen. Dies erspart Gehirnschmalz und Tipparbeit.
[Doku zum Modul](./modules/containers.md)


### Docker Container
Um Docker Dienste zu deployen ist einiges mehr an aufwand nötig. Hierzu muss
die `docker-compose.yml` in Nix Code umgewandelt werden. Ein tolles Tool dazu 
ist [compose2nix](https://github.com/aksiksi/compose2nix). Nun muss der gnerierte
Nix Code noch etwas modifiziert werden und die Secrets über sops eingefügt werden.
**Wichtig** keine Secrets in die nix File schreiben.

## Service accessible machen
Um von Aussen auf den Service zuzugreifen, muss der jeweilige Port im Container geöffnet werden:
```nix
teenix.containers.vaultwarden = {
  networking = {
    useResolvConf = true;
    ports.tcp = [ 8222 ];
  };
};
```

Der Service muss nun auch noch durch unsere Reverse Proxy [Traefik](https://doc.traefik.io/traefik/).  
Hierzu haben wir natürlich auch ein Modul Geschrieben. Dies
erlaubt uns, unsere Services einfach in Traefik einzubinden.
Der einfachste Fall ist ein Service ohne Middleware o.ä.  
[Doku zum Moul](./modules/Traefik.md)
