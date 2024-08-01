{ ... }: {
  imports = [
    ./openssh.nix
    ./nextcloud.nix
    ./fscshhu.nix
    ./keycloak.nix
    ./matrix.nix
    ./traefik.nix
    ./element-web.nix
    ./pretix.nix
    ./prometheus.nix
    ./authentik.nix
  ];
}
