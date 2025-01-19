{ lib, ... }:
{
  imports = lib.teenix.importAllChildren ./.;
}
