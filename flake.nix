{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # TODO: where should this go?
      legacyPackages.makeDenoCache = pkgs.callPackage ./nix/make-deno-cache.nix {};

      packages.npm-example = self.legacyPackages.${system}.makeDenoCache {
        lockFile = ./examples/npm/deno.lock;
      };

      devShells.default = devshell.legacyPackages.${system}.mkShell {
        motd = "";

        packages = [
          pkgs.deno
          pkgs.nil
          self.formatter.${system}
        ];
      };

      formatter = pkgs.alejandra;
    });
}
