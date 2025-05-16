{
  pkgs,
  lib,
  config,
  ...
}:
let
  dbServices = lib.filterAttrs (
    _: v: v ? database && v.database != null && v.database.name != null && v.database.username != null
  ) config.teenix.ha;

  # Then map to list safely, assuming all dbServices have database set
  databases = lib.mapAttrsToList (_: v: {
    name = v.database.name;
    username = v.database.username;
  }) dbServices;

  pgbouncerDatabases = lib.listToAttrs (
    lib.map (db: {
      name = db.name;
      value = "host=127.0.0.1 port=5432";
    }) databases
  );
  databasesSet = lib.mapAttrs (name: v: {
    name = v.database.name;
    username = v.database.username;
  }) dbServices;
in
{
  options.teenix.ha = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          hostname = lib.mkOption {
            type = lib.types.str;
            description = "The hostname of the server.";
          };
          port = lib.mkOption {
            type = lib.types.number;
            description = "The port of the service.";
          };
          database = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Optional database name to auto-create and expose via PgBouncer.";
                  };
                  username = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Owner of the database (will also be created if missing).";
                  };
                };
              }
            );
            default = null;
            description = "Database configuration (name & owner).";
          };
        };
      }
    );
    description = "High-availability configuration for Teenix.";
  };

  config = lib.mkIf config.teenix.meta.ha.enable {
    teenix.services.traefik.httpServices =
      let
        ipPoolOf =
          name:
          lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
            lib.attrNames config.teenix.meta.services
          );
      in
      lib.mapAttrs' (name: v: {
        name = name;
        value = {
          router.rule = "Host(`${v.hostname}`)";
          healthCheck.enable = true;
          servers = [
            "http://192.18.${toString (ipPoolOf name)}.11:${toString v.port}"
            "http://192.168.${toString (ipPoolOf name)}.11:${toString v.port}"
          ];
        };
      }) config.teenix.ha;

    # Nur wenn Datenbanken existieren PgBouncer konfigurieren
    # Only add PgBouncer databases if any configured
    services.pgbouncer.databases = pgbouncerDatabases;

    sops.secrets =
      lib.recursiveUpdate
        {
          patroni-postgres-password = {
            sopsFile = config.teenix.meta.ha.sopsFile;
            key = "postgres-password";
            owner = "pgbouncer";
            mode = "0400";
          };
        }
        (
          lib.listToAttrs (
            lib.map (db: {
              name = "postgres-${db.name}-password";
              value = {
                sopsFile = config.teenix.meta.ha.sopsFile;
                key = "postgres-${db.name}-password";
                owner = "pgbouncer";
                mode = "0400";
              };
            }) databases
          )
        );

    sops.templates.pgpassword.content = ''
      PGPASSWORD=${config.sops.placeholder.patroni-postgres-password}
      ${lib.concatStringsSep "\n" (
        lib.map (db: ''
          PGPASS_${db.username}=${config.sops.placeholder."postgres-${db.name}-password"}
        '') databases
      )}
    '';

    # Only create users and DBs if there's at least one configured database
    systemd.services.createDatabases = lib.mkIf (builtins.length databases > 0) {
      description = "Ensure all configured databases and users exist";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "pgbouncer";
        EnvironmentFile = "${config.sops.templates.pgpassword.path}";
      };
      script = ''
        set -e

        export PGPASSWORD=$PGPASSWORD

        ${lib.concatStringsSep "\n" (
          lib.map (db: ''
            /bin/sh -c 'echo Ensuring user exists: ${db.username} with password $PGPASS_${db.username}'

            if ! ${pkgs.postgresql}/bin/psql -h /run/pgbouncer -p 6432 -U patroni -d postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '${db.username}';" | grep -q 1; then
              echo "Creating user ${db.username} with password from env"
              ${pkgs.postgresql}/bin/psql -h /run/pgbouncer -p 6432 -U patroni -d postgres -c "CREATE ROLE \"${db.username}\" LOGIN PASSWORD '$PGPASS_${db.username}';"
            else
              echo "User ${db.username} already exists."
            fi

            echo "Ensuring database exists: ${db.name} with owner ${db.username}"
            if ! ${pkgs.postgresql}/bin/psql -h /run/pgbouncer -p 6432 -U patroni -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${db.name}';" | grep -q 1; then
              ${pkgs.postgresql}/bin/psql -h /run/pgbouncer -p 6432 -U patroni -d postgres -c "CREATE DATABASE \"${db.name}\" OWNER \"${db.username}\";"
            else
              echo "Database ${db.name} already exists."
            fi
          '') databases
        )}
      '';

    };

  };
}
