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
    ./helfendentool
    ./prometheus
    ./passbolt
    ./discord-intern-bot
    ./inphimade
    ./nawi
    ./mete
    ./sydent
    ./sliding-sync
    ./traefik.nix
    ./campus-guesser-server
    ./node_exporter
    ./gitlab-runner.nix
  ];
}
