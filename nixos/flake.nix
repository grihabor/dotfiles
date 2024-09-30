{
  description = "A simple NixOS flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.nix-alien.url = "github:thiagokokada/nix-alien";

  outputs = {
    self,
    nixpkgs,
    nix-alien,
    ...
  } @ inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ({system, ...}: {
          environment.systemPackages = with nix-alien.packages.${system}; [
            nix-alien
          ];
          # Optional, needed for `nix-alien-ld`
          programs.nix-ld.enable = true;
        })
      ];
    };
  };
}
