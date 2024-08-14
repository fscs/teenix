{ ... }: {
  imports = [
    ./authentik
    ./element-web
    ./fscshhude
    ./keycloak
    ./matrix
    ./nextcloud
    ./openssh.nix
    ./pretix
    ./prometheus
    ./passbolt
    ./traefik.nix
  ];
}
