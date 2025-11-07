{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    juuso.url = "github:jhvst/nix-config";
    nixvim.url = "github:nix-community/nixvim";
  };

  outputs = inputs@{ ... }: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ ];
    systems = inputs.nixpkgs.lib.systems.flakeExposed;
    perSystem = { pkgs, system, inputs', ... }: {

      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.juuso.overlays.default ];
      };

      packages.neovim = inputs'.nixvim.legacyPackages.makeNixvimWithModule {
        inherit pkgs;
        module = {
          imports = [ inputs.juuso.outputs.nixosModules.neovim ];
          dependencies.lean.enable = true;
          plugins.lean.enable = true;
          plugins.lsp.servers.leanls.enable = true;
          plugins.cmp.settings = {
            sources =
              [
                { name = "latex_symbols"; }
              ];
          };
        };
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          lean4
        ];
      };

    };
  };
}
