{
  lib,
  config,
  ...
}:
{
  options.teenix.services.openssh.enable = lib.mkEnableOption "enable openssh";

  config = lib.mkIf config.teenix.services.openssh.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
    users.users."teefax".openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqlr0nKMcn6rZE0hn8RyzfgT75IxKwzgPn59WH1TSdskJNwRJh5UEDKtHA3eSxguWVdJqSDtbDeO7D6pofqPxMarhCoQwa79056e2LtDYVrABTQPabRSTreHDbMekj6RsxdHAg2BFayutEVwHHRKBuyK3DQd5hu4P3DM9t3c5Zd4XEUY4wB0N2EYy56/kw7uUM49dCX10GLSFVivVyUmb3IpFLmOt7s5I64JpsU5NGG4VdrsRJlG2U2q8f3PWf8tIhqONtR+wa7AYOKKGmBBuq7I1qX3lE7+sgxUc9CFfHVC8+OLclnCizlJaiqXIN+K35URyrqxY5Wf7POeSfhewB florian@yubikey" # content of authorized_keys file
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDF5vhkEdRPrHHLgCMxm0oSrHU+uPM9W45Kdd/BKGreRp5vAA70vG3xEjzGdzIlhF0/qOZisA3MpjnMhW3l+uogTzuD3vDZdgT/pgoZEy2CIGIp9kbK5pQHhEhMbWi5NS5o8F095ZZRjBwRE1le9GmBZbYj3VUHSVaRxv+gZpSdqKBo9Arvr4L/lyTdpYgGEHUParWX+UtkBXSd0mO91h6XM8hEqLJv+ufbgA4az0O8sNTz2Uh+k3kN2sQn11O3ekGk4M9fpDP9+C17C9fbMpMATbFazl5pWnPqgLPrvNCs8dkKEJCRPgTgXHYaOppZ7hprJvMpOYW/IYyYo/1T2j6ELZJ7apMJNlOhWqVDnM5DGSIf65oNGZLiAupq1X+s6IoSEZOcAuWfTlJgRySdNgh/BSiKvmKG0nK8/z2ERN0/shE9/FT7pMyEfxHzNdl4PMvpPKZkucX1z4Pb3DtR684WRxD94lj5Nqh/3CH0EeLMJPwyFsOBNdsitqZGLHpGbOLZ3VDdjbOl2Qjgyl/VwzhAWNYUpyxZj3ZpFlHyDE0y38idXG7L0679THKzE62ZAnPdHHTP5RdWtRUqpPyO/nVXErOr8j55oO27C6jD0n5L4tU3QgSpjMOvomk9hbPzKEEuDGG++gSj9JoVHyAMtkWiYuamxR1UY1PlYBskC/q77Q== openpgp:0xB802445D"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVGapwmgI9ZL7tf6YrcZP2T+rnmrnCgelOybl7yk60QvVhfc1ikOjagkXpXj28wX0JXMKS+1qiIJEz5SkSbhMl67wz2DXzxGx5Xe1WOZltsY7RAg4gbDh71cUxaeYB0J9geXr1HITDbcvb8r5VO910pB5bUtYGUzcWG2wY+brU4pq6rGc9IGjNuQ7kl3q4Rk4ZjUjI5VarBQrLlXWbn5COlhasvdnAd05zVN2J+868Jkxzy9DKjy6svPQqnzL40nP1oZYKQNmTxtsl+V+ScBXnZFjjxA7eoTbQ8M3kZS8FKu3V+Cn6of7BCV+kE4lMsXyhZLDKlyqwYjAkBsXYvAqGeovOH9bI2FX/iQBDOBQUlnBFxGXEZOpSs9/6EDF0V6mEw9mwkGrrXE5HnBjghuZtaWSmHRZZ/wL5gyKSmDOk0+vrUTWeldQ1Wj+l4qVPpRB5vBA6Riga7pEcqE8h7IgtqMiQXA+pSy2pVA1cRaRmJ57FMMuaLfLKDhgPLoRougVZF12aPdN13tuwy8H8Py0ARKPFY1P2GfmPzB0t1fEScfT1dgenSDCb0XJU//zvbOmf/AF0ZSAD2Y7LHcaXTDtOTblYPsm5FNmPvt4XW9mh8pweqIKh6xrkZa84yN8Jj7pIueXUMaXQjN/DzAm7M6uTTCzkRZmC7L3lSyN23oIjnw== openpgp:0xB98F83E7"
    ];

    networking.firewall = {
      enable = true;
    };
  };
}
