{
  lib,
  vaultwarden,
  git,
  ...
}:
vaultwarden.webvault.overrideAttrs (
  final: prev: {
    pname = "voltwarden-webvault";

    postPatch = ''
      pushd $PWD
      cd apps/web/src/images || exit

      # rm vaultwarden-password-manager-logo.svg
      # ln -s ${./vaultwarden-password-manager-logo.svg} vaultwarden-password-manager-logo.svg

      # rm vaultwarden-admin-console-logo.svg
      # ln -s ${./vaultwarden-admin-console-logo.svg} vaultwarden-admin-console-logo.svg

      # rm vaultwarden-icon.svg
      # ln -s ${./vaultwarden-icon.svg} vaultwarden-icon.svg

      # rm icon-{dark,white}.png
      # ln -s ${./icon.png} icon-dark.png
      # ln -s ${./icon.png} icon-white.png

      rm logo-{dark,white}@2x.png
      ln -s ${./logo-dark2x.png} logo-dark@2x.png
      ln -s ${./logo-white2x.png} logo-white@2x.png

      popd
    '';
  }
)
