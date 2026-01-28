{
  description = "Custom Emacs builds with platform-specific optimizations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, emacs-overlay }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [
          emacs-overlay.overlays.default
          self.overlays.default
        ];
      };

    in
    {
      overlays.default = import ./overlay.nix;

      overlays.emacs-overlay = emacs-overlay.overlays.default;

      nixosModules.default = { ... }: {
        nixpkgs.overlays = [
          emacs-overlay.overlays.default
          self.overlays.default
        ];
      };

      darwinModules.default = { ... }: {
        nixpkgs.overlays = [
          emacs-overlay.overlays.default
          self.overlays.default
        ];
      };

      homeManagerModules.default = { ... }: {
        nixpkgs.overlays = [
          emacs-overlay.overlays.default
          self.overlays.default
        ];
      };

      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.my-emacs-with-packages;
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.my-emacs-with-packages
            ];
          };
        }
      );
    };
}
