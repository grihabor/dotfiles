{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  nativeBuildInputs = let
    pex = pkgs.callPackage ./pex.nix {};
    scie-jump = pkgs.callPackage ./scie-jump.nix {};
    scie-lift = pkgs.callPackage ./scie-lift.nix {};
    scie-pants = pkgs.callPackage ./scie-pants.nix {inherit scie-lift;};
  in [
    scie-jump
    scie-lift
    scie-pants
    pkgs.nix-index
    pkgs.which
    pkgs.xxd
  ];
}
