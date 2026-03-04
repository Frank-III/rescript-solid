{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # JS/TS
            bun

            # OCaml LSP & editor tooling
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat

            # OCaml build (opam 5.2.0+ox has ppxlib+ox for ReScript AST compat)
            opam
            pkg-config
          ];

          shellHook = ''
            eval $(opam env --switch=5.2.0+ox --set-switch 2>/dev/null)
            echo "OCaml $(ocaml -vnum) + ocaml-lsp ready"
          '';
        };
      });
    };
}
