{
  description = "Home Manager configuration of grihabor";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pants-nix = {
      url = "github:grihabor/pants-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    pants-nix,
    rust-overlay,
    ...
  }: let
    system = "x86_64-linux";
    pkgs =
      (
        nixpkgs
        .legacyPackages
        .${system}
        .extend (rust-overlay.overlays.default)
      )
      .extend (import ./overlays/python.nix);
    pants-bin = pants-nix;
  in {
    homeConfigurations."grihabor" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      # Specify your home configuration modules here, for example,
      # the path to your home.nix.
      modules = [
        # {home.packages = [pants-bin.packages.${system}."release_2.20.0"];}
        ./home.nix
        ./home-tpm.nix
      ];

      # Optionally use extraSpecialArgs
      # to pass through arguments to home.nix
    };
  };
}
