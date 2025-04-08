{
  config,
  lib,
  inputs,
  ...
}:
let
  opts = config.teenix.persist;
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
      type = lib.types.str;
      default = "/persist";
      description = ''
        The root directory for all of non generated persistent storage, except /nix and /boot.
      '';
    };
    subvolumes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              owner = lib.mkOption {
                type = lib.types.str;
                default = "root";
                description = ''
                  The owner of the subvolume
                '';
              };
              group = lib.mkOption {
                type = lib.types.str;
                default = "root";
                description = ''
                  The group of the subvolume
                '';
              };
              mode = lib.mkOption {
                type = lib.types.str;
                default = "0755";
                description = "The mode of the subvolume, default is 0755";
              };
              backup = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether this subvolume should be backuped, default is true";
              };
              bindMountDirectories = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Should all directories inside this subvolume be bind-mounted to their respective paths in / (according to their name).
                '';
              };
              path = lib.mkOption {
                type = lib.types.str;
                default = "${config.teenix.persist.path}/${name}";
                description = "Path this subvolume will be mounted at";
              };
              directories = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule (
                    { ... }:
                    {
                      options = {
                        owner = lib.mkOption {
                          type = lib.types.str;
                          default = "root";
                        };
                        group = lib.mkOption {
                          type = lib.types.str;
                          default = "root";
                        };
                        mode = lib.mkOption {
                          type = lib.types.str;
                          default = "0755";
                        };
                      };
                    }
                  )
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

  config = lib.mkIf opts.enable {
    # Default Persistent Subvolumes, these are normally needed for all Systems
    teenix.persist.subvolumes = {
      system = {
        backup = false;
        directories = {
          # The System Log should be persistent accross Reboots
          "/var/log" = { };
          "/var/lib/nixos" = { }; # For Correct User Mapping
          "/var/lib/systemd/coredump" = { };
          "/etc/NetworkManager/system-connections/" = lib.mkIf config.networking.networkmanager.enable {
            mode = "0700";
          };
        };
        bindMountDirectories = true;
      };
      # Storage for the SSH Host Keys - Are not part of the backup
      ssh-keys = {
        backup = false;
      };
    };

    # Generates the Directories inside the impermanence module
    systemd.tmpfiles.rules = builtins.concatLists (
      lib.attrsets.mapAttrsToList (
        name: value:
        [
          "v '${opts.path}/${name}' ${value.mode} ${value.owner} ${value.group} -"
          (lib.mkIf value.backup "d '${opts.path}/${name}/.snapshots' ${value.mode} ${value.owner} ${value.group} -")
        ]
        ++ lib.attrsets.mapAttrsToList (
          n: v: "d '${opts.path}/${name}/${n}' ${v.mode} ${v.owner} ${v.group} -"
        ) value.directories
      ) opts.subvolumes
    );

    environment.persistence = lib.mapAttrs' (name: value: {
      name = value.path;
      value = {
        hideMounts = true;
        directories = lib.mapAttrsToList (name: value: {
          directory = name;
          user = value.owner;
          group = value.group;
          mode = value.mode;
        }) value.directories;
        files = [
        ];
      };
    }) (lib.attrsets.filterAttrs (name: value: value.bindMountDirectories) opts.subvolumes);

    # Automatically snapshots the Persistent Subvolumes
    services.btrbk.instances.btrbk = {

      onCalendar = "hourly";
      settings = {
        snapshot_preserve = "6h 7d 1w 1m";
        snapshot_preserve_min = "6h";
        timestamp_format = "long-iso";

        volume = lib.attrsets.mapAttrs' (name: value: {
          name = "${opts.path}/${name}";
          value = {
            subvolume = "${opts.path}/${name}";
            snapshot_dir = ".snapshots";
          };
        }) (lib.attrsets.filterAttrs (name: value: value.backup) opts.subvolumes);
      };
    };

    # Exists always because it is needed for SOPS and openssh
    services.openssh.hostKeys = [
      {
        bits = 4096;
        openSSHFormat = true;
        path = "${opts.path}/ssh-keys/ssh_host_rsa_key";
        rounds = 100;
        type = "rsa";
      }
      {
        comment = "key comment";
        path = "${opts.path}/ssh-keys/ssh_host_ed25519_key";
        rounds = 100;
        type = "ed25519";
      }
    ];
  };
}
