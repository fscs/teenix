{ pkgs, lib, ... }:
{
  security.pam.sshAgentAuth.enable = true;

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting 
    '';
  };

  services.openssh.settings.PrintMotd = true;
  users.motd = ''
     __         __
    /  \.-"""-./  \
    \    -   -    /
     |   o   o   |
     \  .-'''-.  /
      '-\__Y__/-'
         `---`

  '';

  environment = {
    enableAllTerminfo = true;

    shellAliases = rec {
      ls = "${lib.getExe pkgs.eza} -F --sort extension --group-directories-first --git --icons -Mo --hyperlink --git-repos-no-status --color-scale=size --no-permissions ";
      ll = ls + "-l ";
      la = ll + "-a ";
      l = ll;
      gls = ll + "--git-ignore ";
    };

    systemPackages = with pkgs; [
      bat
      btop
      duf
      file
      git
      jq
      psmisc
      ripgrep
      xcp
    ];
  };

  users.defaultUserShell = pkgs.fish;

  teenix.users = {
    teefax = {
      hosts = [
        "teefax"
        "testfax"
      ];
    };

    felix = {
      hosts = [
        "teefax"
        "testfax"
      ];
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCSzPwzWF8ETrEKZVrcldR5srYZB0debImh6qilNlH4va8jwVT835j4kTnwgDr/ODd5v0LagYiUVQqdC8gX/jQA9Ug9ju/NuPusyqro2g4w3r72zWFhIYlPWlJyxaP2sfUzUhnO0H2zFt/sEe8q7T+eDdHfKP+SIdeb9v9/oCAz0ZVUxCgkkK20hzhVHTXXMefjHq/zm69ygW+YpvWmvZ7liIDAaHL1/BzOtuMa3C8B5vP3FV5bh7MCSXyj5mIvPk7TG4e673fwaBYEB+2+B6traafSaSYlhHEm9H2CiRfEUa2NrBRHRv1fP4gM60350tUHLEJ8hM58LBymr3NfwxC00yODGfdaaWGxW4sxtlHw57Ev6uNvP2cN551NmdlRX7qKQKquyE4kUWHPDjJMKB8swj3F4/X6iAlGZIOW3ivcf+9fE+FUFA45MsbrijSWWnm/pOe2coP1KMvFNa6HMzCMImCAQPKpH5+LfT7eqfenDxgsJR5zm3LbrMJD6QhnBqPJsjH6gDzE17D5qctyMFy0DOad9+aVUWry1ymywSsjHuhMBcgQOgk3ZNdHIXQn5y6ejWaOJnWxZHFPKEeiwQK8LuE3cAj18p8r/rBnwhn7KHzlAgY0pgEZKrDSKIXDutFF9Y49hHyGpe3oI+oscBmH2xr0au/eNKlr/J85b9FdaQ=="
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtvtqwAan/ubiGOe01Vhda6fTlI8AP3PQQ4RsQ+GqPGjH5jVOT8WUm4a1Ed7kC26pesUgC/67wu2PhlqfhzagaPqDV+Yt/HaOSG7fB3PYLyewt66l1P/3X5gszZ5Z1NGcx0xj8sWB1Y88i9BKO3V3LbnEY/XXSgE4XxxMRlXJydt/5Hq8zodd8mXFJWWbNS+xoTM2fRcKn8Gq72qU+LTNDV8xmzLjMG/PxL/4lveKusvBMtK/V9eKkd/Mt9Wen/ICR0JlcNqxfkt+kVt+YXJhppLOiNDxVzdK88wACK1DMHxBSQjcSRC9/USicmal7hApxMB41BLqgbDmtT22Umyf1kSSicaN7+IfijoGuT084Tu5zc2YGFSAe9iRet1i4glXazrgdsk6I/3FQQc1c1eC8ni3j36/9V8FBIe7+GmL+czdR0zSnL1VMIEchps9YnVHNFOkrgMKOV84mm23Zrf7sXFme7I5oXRXXP50taqCfCUbK8uwT6S1FIZhvn23GFM3IllIH8wY7uLtpOB5TxPLmZJjgXXo8eRHqF1wnYbytU1V+MlTP6MaeWzZnOMhKEK5D9ouCTA9iYNi0cGbDJLldMcwYnd+2/kFd0p2iQcWUqebC1DnL44biNP0Hc9d8rF/jc88aotpTCVEosSTAn++b4aVdYP8TAGN5GxSWqKpnCQ== u0_a250@localhost"
      ];
    };

    robert = {
      hosts = [
        "teefax"
        "testfax"
      ];
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQWRxKckzxJINHlvYuv6GG7yihSd5nxdzrljY+MAH+l huq88dev@hhu.de"
      ];
    };

    tischgoblin = {
      hosts = [
        "teefax"
        "testfax"
      ];
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEO6W5W6mCbnmGYJhaBLePfgotqKe3XXXBuqSPTTYz1yddJjcqbahUID4vvFTtkjnD8KbGSkAPJBsb/7v0udTWZUr9Uf2E+nr7BDE1ai13Bd9LMyHAIWzAZ0M6wSLcUKxNLf3nSohcH+cZYuUjNAWm0Ek1PfapwN04rC0C+mijhT5cRK+I7eMN8S89pwHiYbZTjq9ApyQJi3/x/4812DqDCt6ugvgkYcw7o5GCfEBOTBd7l5uD8kvTa8FEECexDrjMHze747DBab+opj/1H4wSAoIUW8T3Xqi52iTC3f6asBPFpt8hIlq84Majb0gSf17Ru93jb2gGAK6MWIgJI4ZVjH9//tPFVBaH3bwDBi+LcFpoEizStVEq8Ljz5+DnfgMDc0kkLFwh57Ng/v9XjTnTvfrCc7usWH0NKS09x50VK6p58bIapj0sojgSbe/9b7duu8LWE4CPFRwurTtg7bh/3MV+aF0LgN5oPgBtAndwHVnuAjPG33PzYEv3TkCDee2u0MBjkyR4xkDHg31O8da+ABiX4PJX1lN2TsgJVfU0hlNmHQXJvYqzJD9fCWJSEOvFhS447v1W0zCfir21h2m7A+sZ8ezYOJhy6If5Q9yjub2zFdHemIPGVpRtz/D4uSZj++gt2c2P7Mp6OwBRaXwnAhO8n6Ry+mu5Yd7YIWWjRw== cardno:31_026_784"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbxDGg250fa1tE9HK4U1G3Uee2L7p5kA+V82RAIL89b yesmachine"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpq+pnhT8eedChvTk1uIWvKR2WXWRFcYPkzm4lR0XUk nix-on-droid"
      ];
    };

    gitlab = {
      hosts = [ "teefax" ];
      shell = pkgs.bash;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiu4iPkKfORYXnpTBiU+MQGPZ8jQ3a8BXxfmXoD1irlB5ej0r/GM034YcoxBG18ZoK0kf8zsLhfP8GkLr65XZBaRD29IBs0nAjm8oGo+ZMoETFbJj2ChZx/+fCUqKzCDOp8RcackQlBQ+u01HDtbwMHvIwx6pew7Z6n52A9pjSh7khEUSDTzh/wRzbN3lhaGWSmA3HFgR1TNTZT3r4lKq3A6+49OXD34NReAHIoAu7gkfpreS5icdYBS+B92O/coaOXiqtQWlLbseBoTHBaw5o/5pAyxpIUm3L98xTnGHKLz+KQUDTN6fRvLE2OZ9eKbakfRWYpg2J9i75AXhWzXWBCsylFDnP64ZO6IkBHQ5JSdIwwQOYuhZbIo+1nTnzCL1YXiy39b9aySBf1b9kvItIrSr1hpqVQuVX4Z8t5U5z3molSR4ylyzaS++ZQAXMBjSroc9EU/zq5Jiywj0c4jqzYN6O1ejGv/yo7BPw2HNJS16saAkmZ7kWmqXBNKPXXbs= teefax"
      ];
    };
  };
}
