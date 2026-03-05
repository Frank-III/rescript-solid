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

            # OCaml build (prefer local switch 5.3.0 for PPX tooling)
            opam
            pkg-config
          ];

          shellHook = ''
            if opam switch list --short | grep -q '^5.3.0$'; then
              eval $(opam env --switch=5.3.0 --set-switch 2>/dev/null)
            else
              echo "Missing opam switch 5.3.0. Run: opam switch create 5.3.0 ocaml-base-compiler.5.3.0 && opam install -y dune ppxlib.0.34.0"
            fi
            echo "OCaml $(ocaml -vnum) + ocaml-lsp ready"
          '';
        };
      });
    };
}
