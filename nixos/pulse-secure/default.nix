{
  pkgs,
  lib,
  ...
}: let
  start-pulse-vpn = pkgs.callPackage ./pulse-vpn.nix {};
in {
  environment.systemPackages = with pkgs; [
    openconnect
    start-pulse-vpn
  ];
}
