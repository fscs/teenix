{ inputs
, outputs
, config
, pkgs
, lib
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../locale.nix

    inputs.sops.nixosModules.sops
    inputs.nix-tun.nixosModules.nix-tun

    outputs.nixosModules.teenix
  ];

  environment.systemPackages = [
    pkgs.git
    pkgs.kitty
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  networking = {
    nameservers = [ "134.99.128.2" ];
    defaultGateway = {
      address = "134.99.147.225";
      interface = "ens160";
    };
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "ens160";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };

  networking.interfaces.ens160 = {
    ipv4 = {
      addresses = [
        {
          address = "134.99.147.245";
          prefixLength = 27;
        }
      ];
    };
  };
  networking.firewall.checkReversePath = false;

  virtualisation.vmware.guest.enable = true;

  networking.firewall.logRefusedConnections = true;

  teenix.nixconfig.enable = true;
  teenix.nixconfig.allowUnfree = true;
  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  networking.hostName = "testfax";

  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;

  sops.secrets.traefik = {
    format = "binary";
    mode = "444";
    sopsFile = ../secrets/traefik;
  };
  teenix.services.traefik.enable = true;
  teenix.services.traefik.staticConfigPath = ../secrets/traefik_static;
  teenix.services.traefik.dashboardUrl = "traefik.minecraft.fsphy.de";
  teenix.services.traefik.letsencryptMail = "fscs@hhu.de";
  teenix.services.traefik.logging.enable = true;

  teenix.services.traefik.entrypoints = {
    web = {
      port = 80;
      http = {
        redirections = {
          entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
      };
    };
    websecure = {
      port = 443;
    };
    ping = {
      port = 8082;
    };
    metrics = {
      port = 120;
    };
  } //
  (builtins.foldl'
    lib.trivial.mergeAttrs
    { }
    (builtins.map (i: { "turn_port_udp_${builtins.toString i}" = { port = i; }; })
      (lib.range 30000 30010)));

  # Services
  nix-tun.storage.persist.enable = true;


  teenix.services.node_exporter = {
    enable = true;
  };


  security.pam.sshAgentAuth.enable = true;

  teenix.users = {
    teefax = {
      shell = pkgs.fish;
      setSopsPassword = false;
    };

    felix = {
      shell = pkgs.fish;
      setSopsPassword = false;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCSzPwzWF8ETrEKZVrcldR5srYZB0debImh6qilNlH4va8jwVT835j4kTnwgDr/ODd5v0LagYiUVQqdC8gX/jQA9Ug9ju/NuPusyqro2g4w3r72zWFhIYlPWlJyxaP2sfUzUhnO0H2zFt/sEe8q7T+eDdHfKP+SIdeb9v9/oCAz0ZVUxCgkkK20hzhVHTXXMefjHq/zm69ygW+YpvWmvZ7liIDAaHL1/BzOtuMa3C8B5vP3FV5bh7MCSXyj5mIvPk7TG4e673fwaBYEB+2+B6traafSaSYlhHEm9H2CiRfEUa2NrBRHRv1fP4gM60350tUHLEJ8hM58LBymr3NfwxC00yODGfdaaWGxW4sxtlHw57Ev6uNvP2cN551NmdlRX7qKQKquyE4kUWHPDjJMKB8swj3F4/X6iAlGZIOW3ivcf+9fE+FUFA45MsbrijSWWnm/pOe2coP1KMvFNa6HMzCMImCAQPKpH5+LfT7eqfenDxgsJR5zm3LbrMJD6QhnBqPJsjH6gDzE17D5qctyMFy0DOad9+aVUWry1ymywSsjHuhMBcgQOgk3ZNdHIXQn5y6ejWaOJnWxZHFPKEeiwQK8LuE3cAj18p8r/rBnwhn7KHzlAgY0pgEZKrDSKIXDutFF9Y49hHyGpe3oI+oscBmH2xr0au/eNKlr/J85b9FdaQ=="
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtvtqwAan/ubiGOe01Vhda6fTlI8AP3PQQ4RsQ+GqPGjH5jVOT8WUm4a1Ed7kC26pesUgC/67wu2PhlqfhzagaPqDV+Yt/HaOSG7fB3PYLyewt66l1P/3X5gszZ5Z1NGcx0xj8sWB1Y88i9BKO3V3LbnEY/XXSgE4XxxMRlXJydt/5Hq8zodd8mXFJWWbNS+xoTM2fRcKn8Gq72qU+LTNDV8xmzLjMG/PxL/4lveKusvBMtK/V9eKkd/Mt9Wen/ICR0JlcNqxfkt+kVt+YXJhppLOiNDxVzdK88wACK1DMHxBSQjcSRC9/USicmal7hApxMB41BLqgbDmtT22Umyf1kSSicaN7+IfijoGuT084Tu5zc2YGFSAe9iRet1i4glXazrgdsk6I/3FQQc1c1eC8ni3j36/9V8FBIe7+GmL+czdR0zSnL1VMIEchps9YnVHNFOkrgMKOV84mm23Zrf7sXFme7I5oXRXXP50taqCfCUbK8uwT6S1FIZhvn23GFM3IllIH8wY7uLtpOB5TxPLmZJjgXXo8eRHqF1wnYbytU1V+MlTP6MaeWzZnOMhKEK5D9ouCTA9iYNi0cGbDJLldMcwYnd+2/kFd0p2iQcWUqebC1DnL44biNP0Hc9d8rF/jc88aotpTCVEosSTAn++b4aVdYP8TAGN5GxSWqKpnCQ== u0_a250@localhost"
      ];
    };

    tischgoblin = {
      shell = pkgs.fish;
      setSopsPassword = false;
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAoWrXcbe0HbxOHRqbeSofUoYez8l5ydvTfpop0I5gD notuser@nixos"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbxDGg250fa1tE9HK4U1G3Uee2L7p5kA+V82RAIL89b yesmachine"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpq+pnhT8eedChvTk1uIWvKR2WXWRFcYPkzm4lR0XUk nix-on-droid"
      ];
    };

    gitlab = {
      shell = pkgs.bash;
      setSopsPassword = false;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiu4iPkKfORYXnpTBiU+MQGPZ8jQ3a8BXxfmXoD1irlB5ej0r/GM034YcoxBG18ZoK0kf8zsLhfP8GkLr65XZBaRD29IBs0nAjm8oGo+ZMoETFbJj2ChZx/+fCUqKzCDOp8RcackQlBQ+u01HDtbwMHvIwx6pew7Z6n52A9pjSh7khEUSDTzh/wRzbN3lhaGWSmA3HFgR1TNTZT3r4lKq3A6+49OXD34NReAHIoAu7gkfpreS5icdYBS+B92O/coaOXiqtQWlLbseBoTHBaw5o/5pAyxpIUm3L98xTnGHKLz+KQUDTN6fRvLE2OZ9eKbakfRWYpg2J9i75AXhWzXWBCsylFDnP64ZO6IkBHQ5JSdIwwQOYuhZbIo+1nTnzCL1YXiy39b9aySBf1b9kvItIrSr1hpqVQuVX4Z8t5U5z3molSR4ylyzaS++ZQAXMBjSroc9EU/zq5Jiywj0c4jqzYN6O1ejGv/yo7BPw2HNJS16saAkmZ7kWmqXBNKPXXbs= teefax"
      ];
    };
  };

  system.stateVersion = "23.11";
}
