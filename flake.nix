{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    juuso.url = "github:jhvst/nix-config";
    nixvim.url = "github:nix-community/nixvim";
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
        };
      };

      devenv.shells.default = {
        packages = with pkgs; [ lean4 ];
      };

    };
    flake = { };
  };
}