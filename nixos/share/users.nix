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

  teenix.users =
    let
      allHosts = [
        "teefax"
        "verleihnix"
      ];
    in
    {
      felix = {
        hosts = allHosts;
        sshKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCSzPwzWF8ETrEKZVrcldR5srYZB0debImh6qilNlH4va8jwVT835j4kTnwgDr/ODd5v0LagYiUVQqdC8gX/jQA9Ug9ju/NuPusyqro2g4w3r72zWFhIYlPWlJyxaP2sfUzUhnO0H2zFt/sEe8q7T+eDdHfKP+SIdeb9v9/oCAz0ZVUxCgkkK20hzhVHTXXMefjHq/zm69ygW+YpvWmvZ7liIDAaHL1/BzOtuMa3C8B5vP3FV5bh7MCSXyj5mIvPk7TG4e673fwaBYEB+2+B6traafSaSYlhHEm9H2CiRfEUa2NrBRHRv1fP4gM60350tUHLEJ8hM58LBymr3NfwxC00yODGfdaaWGxW4sxtlHw57Ev6uNvP2cN551NmdlRX7qKQKquyE4kUWHPDjJMKB8swj3F4/X6iAlGZIOW3ivcf+9fE+FUFA45MsbrijSWWnm/pOe2coP1KMvFNa6HMzCMImCAQPKpH5+LfT7eqfenDxgsJR5zm3LbrMJD6QhnBqPJsjH6gDzE17D5qctyMFy0DOad9+aVUWry1ymywSsjHuhMBcgQOgk3ZNdHIXQn5y6ejWaOJnWxZHFPKEeiwQK8LuE3cAj18p8r/rBnwhn7KHzlAgY0pgEZKrDSKIXDutFF9Y49hHyGpe3oI+oscBmH2xr0au/eNKlr/J85b9FdaQ=="
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtvtqwAan/ubiGOe01Vhda6fTlI8AP3PQQ4RsQ+GqPGjH5jVOT8WUm4a1Ed7kC26pesUgC/67wu2PhlqfhzagaPqDV+Yt/HaOSG7fB3PYLyewt66l1P/3X5gszZ5Z1NGcx0xj8sWB1Y88i9BKO3V3LbnEY/XXSgE4XxxMRlXJydt/5Hq8zodd8mXFJWWbNS+xoTM2fRcKn8Gq72qU+LTNDV8xmzLjMG/PxL/4lveKusvBMtK/V9eKkd/Mt9Wen/ICR0JlcNqxfkt+kVt+YXJhppLOiNDxVzdK88wACK1DMHxBSQjcSRC9/USicmal7hApxMB41BLqgbDmtT22Umyf1kSSicaN7+IfijoGuT084Tu5zc2YGFSAe9iRet1i4glXazrgdsk6I/3FQQc1c1eC8ni3j36/9V8FBIe7+GmL+czdR0zSnL1VMIEchps9YnVHNFOkrgMKOV84mm23Zrf7sXFme7I5oXRXXP50taqCfCUbK8uwT6S1FIZhvn23GFM3IllIH8wY7uLtpOB5TxPLmZJjgXXo8eRHqF1wnYbytU1V+MlTP6MaeWzZnOMhKEK5D9ouCTA9iYNi0cGbDJLldMcwYnd+2/kFd0p2iQcWUqebC1DnL44biNP0Hc9d8rF/jc88aotpTCVEosSTAn++b4aVdYP8TAGN5GxSWqKpnCQ== u0_a250@localhost"
        ];
      };

      jonas = {
        hosts = allHosts;
        sshKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtxP7ouSpUZNPHJJOCRp8cpk1Ruf7BZQnNNwMNb+y2fNkg/2TDcuMAGr+joYGm5ayiZnlOCbgPSEhfR5JGDsa2Oz+AsKFtGUX03pZ0J3TgZfiz+yPrxFMsS4mNn/Yud12qDUC2VqEZ1DCu3XIYleXb2K9ZKjpsdgCHoFE90p+G98wJC2ifoDg94P955aYtU4JfMLJBbZV2zfYOToqAQPKHgLlQ6rfg4UdMYnt5N13BGZ/Jx0PXxbgWvFBwvvW1WKqYa2TpSfE2h9awpDX7JeptrGJji/JLfNnNJD7ASsSbzMsQcv3zDig7s6yPugfrq/3d6OsTmSkeH75cIeOibDS7qtC2TGziOLIMIgNOzf8eZ3Fy6XAzyug3zH7MjZjhQdQs4NodCbJOUqMpYXL1BY807GpNdcYPUVTyx9Docb2PcSycQikHa11MU4MxsnPU1APqhrd+zaDZE/dpCfD/C385v1IlGKqWX1n7AE2idFIGhR+mN+SOWui/2a0hdBeVNSE= yim04bib@hhu.de"
        ];
      };

      robert = {
        hosts = allHosts;
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQWRxKckzxJINHlvYuv6GG7yihSd5nxdzrljY+MAH+l huq88dev@hhu.de"
        ];
      };

      arthur = {
        hosts = allHosts;
        sshKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnc79sOiR6BgFqtKZaS5E6jM0vx3Vdzpe1PxbXTVouMDrzhLkobk1Aphmmu0ars8teyZlRhY+SabWu5LqhNmSQmgokd/N+rZeDa4AzfBvd/6I/6jAryT0sD+WYEF62PLuKKQif8XLF/aVNLsC2UMynnmqNmLVzfPBcy4KSElEEXIqsnQiwsK+TG2IuFpmz3sQ3Hta1AKk3g3HcBRc8CZZqhZOhL4C3HHgmIE7TQWao0roMHZIlFVhkflbCi4UHEVzM5MD1U+IoxgRE1Wf9jaezhfooDa7lknvCfoI9G7Y78UgdF9hQNtyue1MYQRbemephNMuRPNR+t9GfGOJvdvUSk4suy8IgaLUCueXRp0wphAFaQ754hfTEV/s+7hiIKwEvgqsI07G/BAqq72qY6i86fg5jO4ZzN7esJ8hSJDadCXoOWxPeUaVgEHiTzlLXm8B6aiv/QvdD6HSdtz57tePPzRqcK50k5E85lWiPJVKiCKUuY+Hqh6NxZbWHZAdQrGxUsrlJIFZXFq95Ixiqwvx18ALsarW0zsVivYqB59jOqRn6Pqe6h2HwNYoOZzJ0zfS5hX+O2VXhQY5h5oxapdfqTj8yps23eQMBndkJ6yESmXFCdgBxU02OlsKxS1wkwiNLUchmKVTItoP0ObvFva6MctzlLe1WtIbrkfbidlhRAQ== cardno:31_026_784"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC54HLl7/XL/aURKHbyxIWH6lcFsTkNRlkcsE0J1XFhq5aqK5w1gJYm4Yldyoj2VvE2g6rD/7mg2Qu4rs/xnJaYnG5txTrJegr0UCy98fiDfXl/4fym/ceiXMk27s4lRLyy+riyotGiRL4+Tgs+lxtTed7v2R9kR2aYNwitWVnq4m0CTCk8q501wlN5taRz2ppPXnqYNfEQD7D/YQm4SGhkXBsvWSociaLkXqnmVHcPcKCd0aKNEupYfiPtLEtpXwwNHgvODS6glThecpJaMHoa3zBelvoNGT+KdWl9WJY2Mia+k6xje8qsMTxHjlIjDTXivptJ9jP9ctAFXvLivGI2IRmwdddBAF8xWStOccp+lcbTTarmin77ov34iRF01anc4Ij8WGQIYVYvE7P7OTGU2Mgo+TXB4trpyHXtfVZZKpADSArS89Fclb2YobbjITDNEPuSdfUiw4rt9K835aybKNlH1fhe0p9UNFCakjLd2yxrtOWoR4/7JiqtDOG4lt+WtmmTABUuGDfADeNKgNK7hpWL3paAvZhWygiyG4v8AQ1A4LAtBstDn/NWLJ1vtU6ddY5akcAQagiyB0CmpmWA4K70FQFfcC/VQCpLQoJUVM97siWxbEyY0Gif6pcooTOzBQqJqa6DQZTYCAhmOnGzkL6S+4zeZT6KOyBhjRzzqQ== cardno:26_384_138"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpq+pnhT8eedChvTk1uIWvKR2WXWRFcYPkzm4lR0XUk nix-on-droid"
        ];
      };

      gitlab = {
        hosts = allHosts;
        shell = pkgs.bash;
        sshKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiu4iPkKfORYXnpTBiU+MQGPZ8jQ3a8BXxfmXoD1irlB5ej0r/GM034YcoxBG18ZoK0kf8zsLhfP8GkLr65XZBaRD29IBs0nAjm8oGo+ZMoETFbJj2ChZx/+fCUqKzCDOp8RcackQlBQ+u01HDtbwMHvIwx6pew7Z6n52A9pjSh7khEUSDTzh/wRzbN3lhaGWSmA3HFgR1TNTZT3r4lKq3A6+49OXD34NReAHIoAu7gkfpreS5icdYBS+B92O/coaOXiqtQWlLbseBoTHBaw5o/5pAyxpIUm3L98xTnGHKLz+KQUDTN6fRvLE2OZ9eKbakfRWYpg2J9i75AXhWzXWBCsylFDnP64ZO6IkBHQ5JSdIwwQOYuhZbIo+1nTnzCL1YXiy39b9aySBf1b9kvItIrSr1hpqVQuVX4Z8t5U5z3molSR4ylyzaS++ZQAXMBjSroc9EU/zq5Jiywj0c4jqzYN6O1ejGv/yo7BPw2HNJS16saAkmZ7kWmqXBNKPXXbs= teefax"
        ];
      };
    };
}
