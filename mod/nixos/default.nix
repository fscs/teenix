{ ... }: {
  imports = [
    ./services
    ./nixconfig.nix
    ./bootconfig.nix
    ./users.nix
  ];
}
