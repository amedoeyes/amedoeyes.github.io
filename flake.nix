{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              biome
              elmPackages.elm
              elmPackages.elm-format
              elmPackages.elm-language-server
              elmPackages.elm-live
              typescript-go
              vscode-langservers-extracted
            ];
          };
        }
      );
    };
}
