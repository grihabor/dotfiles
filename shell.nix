 let
   nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
   pkgs = import nixpkgs { config = {}; overlays = []; };
 in

 pkgs.mkShellNoCC {
   packages = with pkgs; [
     yaml-language-server
     neovim
     cowsay
     lolcat
   ];

   GREETING = "Neovim is ready!";

   shellHook = ''
     echo $GREETING | cowsay | lolcat
   '';
 }
