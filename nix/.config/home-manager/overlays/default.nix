{
  pkgs ?
    import <nixpkgs> {
      overlays = [
        (import ./python.nix)
      ];
    },
}: {
  inherit (pkgs) ruff python;
}
