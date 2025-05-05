{ lib, config, ... }:
{
  options.teenix.services.scanner = {
    enable = lib.mkEnableOption "vsftpd";
    secretsFile = lib.teenix.mkSecretsFileOption "vsftpd";
  };

  config =
    let
      cfg = config.teenix.services.scanner;
    in
    lib.mkIf cfg.enable {
      sops.secrets = {
        scanner-pwd = {
          neededForUsers = true;
          sopsFile = cfg.secretsFile;
          key = "pwd";
          mode = "0444";
        };
        scanner-cert = {
          sopsFile = cfg.secretsFile;
          key = "cert";
          mode = "0444";
        };
        scanner-key = {
          sopsFile = cfg.secretsFile;
          key = "key";
          mode = "0444";
        };
      };

      users.users.scanner = {
        isNormalUser = true;
        createHome = false;
        hashedPasswordFile = config.sops.secrets.scanner-pwd.path;
      };

      services.vsftpd = {
        enable = true;
        localUsers = true;
        writeEnable = true;
        allowWriteableChroot = true;
        localRoot = "${config.teenix.persist.path}/scanner";
        extraConfig = ''
          listen_port=2121
          pasv_min_port=3000
          pasv_max_port=3100
          rsa_cert_file=${config.sops.secrets.scanner-cert.path}
          rsa_private_key_file=${config.sops.secrets.scanner-key.path}
          ssl_enable=YES
          anonymous_enable=NO
          local_umask=011
          file_open_mode=0777
        '';
      };
    };
}
