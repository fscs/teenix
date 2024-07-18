{ ... }: {
  imports = [
    ./openssh.nix
    ./nextcloud.nix
    ./fscshhu.nix
    ./keycloak.nix
    ./matrix.nix
    ./traefik.nix
  ];
}
