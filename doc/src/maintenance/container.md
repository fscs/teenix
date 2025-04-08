# Container und Services

Hier eine kurze Einführung in Container und Systemd Services.

<!-- toc -->

## Systemd Services

Eine systemd Instanz verwaltet (unter anderem) mehrere Services. Diese bestehen aus einem einzelnen 
Prozess, einer einzelnen Komponente.  
Der Webserver unserer Fachschaftswebsite ist ein Service, die dazugehörige Datenbank ein weiterer. 
Die Services sind nicht sonderlich isoliert voneinander, sie reden z.B. mit dem selben Netzwerk 
Interface und teilen sich ein Dateisystem.

## Container

Container hingegen sind stärker voneinander isoliert, sie sind quasi ein eigenes System.
Sie haben ein eigenes Dateisystem und ein eigens Netzwerk Interface. Unter anderem haben sie 
auch eine eigene Systemd Instanz.  

Sie fassen quasi Komponenten zusammen. Um wieder die Fachschaftswebsite als Beispiel zu nehmen:  
Es gibt einen Container `fscshhude` der diese als ganzes repräsentiert. Innerhalb dessen läuft der
Webserver und die Datenbank, von außen gesehen interessiert uns das aber nicht. Wir können es von
außen auch nicht (ohne weiteres) feststellen, den das "äußere" systemd weiß nicht was das "innere"
systemd tut.

### Netzwerk

Jedem Container wird automatisch eine eigene IP zugeordnet, außerhalb ist diese `192.18.<id>.11` 
und innerhalb `192.168.<id>.10`.

### Dateisystem

Unsere Container sind "ephemeral", das heißt das das Dateisystem nicht über Container Neustarts
persistent ist. Natürlich brauchen sie trotzdem persistente Daten, wir möchten aber entscheiden
können welche das sind. Auf dem Host hat jeder Container seinen eigenen Ordner unter `/persist` wo
diese Daten liegen. Damit diese im Container zu sehen sind werden sie in den Container gemountet,
z.B. `/persist/vaultwarden/data` nach `/var/lib/vaultwarden`

