{
  lib,
  vaultwarden,
  git,
}:
vaultwarden.webvault.overrideAttrs (
  final: prev: {
    pname = "voltwarden-webvault";
  
    postPatch = ''
      pushd $PWD
      cd ..
      
      ln -s ${vaultwarden.webvault.bw_web_builds}/patches .
      cp -sr --no-preserve=all ${vaultwarden.webvault.bw_web_builds}/resources .

      cd resources
      
      rm vaultwarden-password-manager-logo.svg
      ln -s ${./vaultwarden-password-manager-logo.svg} vaultwarden-password-manager-logo.svg

      rm vaultwarden-admin-console-logo.svg
      ln -s ${./vaultwarden-admin-console-logo.svg} vaultwarden-admin-console-logo.svg

      cd src/images
      
      rm icon-{dark,white}.png
      ln -s ${./icon.png} icon-dark.png
      ln -s ${./icon.png} icon-white.png

      rm logo-{dark,white}@2x.png
      ln -s ${./logo-dark2x.png} logo-dark@2x.png
      ln -s ${./logo-white2x.png} logo-white@2x.png

      popd
      PATH="${git}/bin:$PATH" VAULT_VERSION="${lib.removePrefix "web-" final.src.rev}" \
        bash ${vaultwarden.webvault.bw_web_builds}/scripts/apply_patches.sh 
    '';
  }
)
