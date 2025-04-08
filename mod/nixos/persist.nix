{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.teenix.persist;

  t = lib.types;

  defaultToString = default: x: toString (lib.defaultTo default x);
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.teenix.persist = {
    enable = lib.mkEnableOption ''
      A wrapper arround impermanence and btrbk. Expects a btrfs filesystem with the following layout:
      - /root <- The actual root mounted at /
      - /nix <- The root for all things nix. Mounted at /nix
      - /persist <- The root of all other persistent storage, mounted at /persist

      *Note*: For systems that use more than one (logical) drive, simply mount more
    '';
    path = lib.mkOption {
      type = t.nonEmptyStr;
      default = "/persist";
      description = ''
        The root directory for all of non generated persistent storage, except /nix and /boot.
      '';
    };
    subvolumes = lib.mkOption {
      type = t.attrsOf (
        t.submodule (
          { name, ... }:
          {
            options = {
              owner = lib.mkOption {
                type = t.nullOr (t.either t.int t.nonEmptyStr);
                default = "root";
                description = ''
                  The owner of the subvolume. If set to null, the owner will not be enforced
                '';
              };
              group = lib.mkOption {
                type = t.nullOr (t.either t.int t.nonEmptyStr);
                default = "root";
                description = ''
                  The group of the subvolume. If set to null, the group will not be enforced
                '';
              };
              mode = lib.mkOption {
                type = t.nullOr t.nonEmptyStr;
                default = "0755";
                description = "The mode of the subvolume, default is 0755. If set to null, the mode will not be enforced";
              };
              backup = lib.mkOption {
                type = t.bool;
                default = true;
                description = "Whether this subvolume should be backuped, default is true";
              };
              bindMountDirectories = lib.mkOption {
                type = t.bool;
                default = false;
                description = ''
                  Should all directories inside this subvolume be bind-mounted to their respective paths in / (according to their name).
                '';
              };
              path = lib.mkOption {
                type = t.nonEmptyStr;
                default = "${config.teenix.persist.path}/${name}";
                readOnly = true;
                description = "Path this subvolume will be mounted at";
              };
              directories = lib.mkOption {
                type = t.attrsOf (
                  t.submodule {
                    options = {
                      owner = lib.mkOption {
                        type = t.nullOr (t.either t.int t.nonEmptyStr);
                        description = "Owner for this directory. If set to null, the owner will not be enforced";
                        default = "root";
                      };
                      group = lib.mkOption {
                        type = t.nullOr (t.either t.int t.nonEmptyStr);
                        description = "Group for this directory. If set to null, the group will not be enforced";
                        default = "root";
                      };
                      mode = lib.mkOption {
                        type = t.nullOr t.nonEmptyStr;
                        description = "Mode for this directory. If set to null, the mode will not be enforced";
                        default = "0755";
                      };
                    };
                  }
                );
                default = { };
                description = ''
                  Directories that should be created per default inside the subvolume
                '';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Subvolumes that should be persistent.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Default Persistent Subvolumes, these are normally needed for all Systems
    teenix.persist.subvolumes = {
      system = {
        backup = false;
        directories = {
          # The System Log should be persistent accross Reboots
          "/var/log" = { };
          "/var/lib/nixos" = { }; # For Correct User Mapping
          "/var/lib/systemd/coredump" = { };
        };
        bindMountDirectories = true;
      };
      # Storage for the SSH Host Keys - Are not part of the backup
      ssh-keys.backup = false;
    };

    # Generates the Directories inside the impermanence module
    systemd.tmpfiles.rules = lib.concatLists (
      lib.attrsets.mapAttrsToList (
        name: value:
        [
          "v ${cfg.path}/${name} ${defaultToString ":0755" value.mode} ${defaultToString ":root" value.owner} ${defaultToString ":root" value.group} -"
          (lib.mkIf value.backup "d ${value.path}/.snapshots ${value.mode} ${value.owner} ${value.group} -")
        ]
        ++ lib.attrsets.mapAttrsToList (
          n: v:
          "d '${value.path}/${n}' ${defaultToString ":0755" value.mode} ${defaultToString ":root" value.owner} ${defaultToString ":root" value.group} -"
        ) value.directories
      ) cfg.subvolumes
    );

    environment.persistence = lib.mapAttrs' (name: value: {
      name = value.path;
      value = {
        hideMounts = true;
        directories = lib.mapAttrsToList (name: value: {
          directory = name;
          user = defaultToString "root" value.owner;
          group = lib.defaultTo "root" value.group;
          mode = lib.defaultTo "0755" value.mode;
        }) value.directories;
      };
    }) (lib.attrsets.filterAttrs (name: value: value.bindMountDirectories) cfg.subvolumes);

    # Automatically snapshots the Persistent Subvolumes
    services.btrbk.instances.btrbk = {
      onCalendar = "hourly";
      settings = {
        snapshot_preserve = "6h 7d 1w 1m";
        snapshot_preserve_min = "6h";
        timestamp_format = "long-iso";

        volume = lib.attrsets.mapAttrs' (name: value: {
          name = value.path;
          value = {
            subvolume = value.path;
            snapshot_dir = ".snapshots";
          };
        }) (lib.attrsets.filterAttrs (name: value: value.backup) cfg.subvolumes);
      };
    };

    # Exists always because it is needed for SOPS and openssh
    services.openssh.hostKeys = [
      {
        bits = 4096;
        openSSHFormat = true;
        path = "${cfg.path}/ssh-keys/ssh_host_rsa_key";
        rounds = 100;
        type = "rsa";
      }
      {
        comment = "key comment";
        path = "${cfg.path}/ssh-keys/ssh_host_ed25519_key";
        rounds = 100;
        type = "ed25519";
      }
    ];
  };
}
