{
  teenix.docs.modules.authentik = {
    title = "Authentik";
    description = "Ein SSO (Single Sign On) Provider mit vielen Anbindungsmöglichkeiten. Ein universeller Login für alle Dienste";
    optionNamespace = [
      "teenix"
      "services"
      "authentik"
    ];
  };

  # setup the authentik binary cache
  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}
