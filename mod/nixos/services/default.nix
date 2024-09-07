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
    ./fscs-intern-bot
    # ./inphimade
    ./traefik.nix
  ];
}
