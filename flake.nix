{
  description = "A Niri shell illogical-impulse based - with some modifications..";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      quickshell,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux;
      pkgsFor = eachSystem (
        system: nixpkgs.legacyPackages.${system}.appendOverlays [ self.overlays.default ]
      );
    in
    {
      overlays.default = final: prev: {
        ii = final.callPackage ./nix/package.nix {
          quickshell = quickshell.packages.${final.system}.default;

          version =
            let
              mkDate =
                longDate:
                final.lib.concatStringsSep "-" [
                  (builtins.substring 0 4 longDate)
                  (builtins.substring 4 2 longDate)
                  (builtins.substring 6 2 longDate)
                ];
            in
            mkDate (self.lastModifiedDate or "19700101") + "_" + (self.shortRev or "dirty");
        };
      };

      packages = eachSystem (system: {
        default = pkgsFor.${system}.ii;
      });

      formatter = eachSystem (system: pkgsFor.${system}.nixfmt-rfc-style);
    };
}
