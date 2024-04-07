# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#overriding-python-packages-overriding-python-packages
{nixpkgs ? import <nixpkgs>, ...}: let
  python = let
    packageOverrides = self: super: {
      pynvim = super.pynvim.overridePythonAttrs (old: rec {
        version = "0.5.0";
        src = nixpkgs.fetchPypi {
          pname = "pynvim";
          inherit version;
          hash = "sha256-6AoR9vXRlMake+pBNbkLVfrKJNo1RNp89KX3uo+wkhU=";
        };
      });
    };
  in
    python.override {
      inherit packageOverrides;
      self = python;
    };
in {
  python =
    python.withPackages
    (
      python-pkgs: [
        python-pkgs.pynvim
      ]
    );
}
