{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    juuso.url = "github:jhvst/nix-config";
    nixvim.url = "github:nix-community/nixvim";
    lean4.url = "github:leanprover/lean4/v4.18.0";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ ... }: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ inputs.devenv.flakeModule ];
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

      devenv.shells.default = {
        packages = with pkgs; [ lean4 ]
          ++ inputs'.lean4.devShells.default.buildInputs;
      };

    };
    flake = { };
  };
}