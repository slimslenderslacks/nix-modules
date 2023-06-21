{ flake-utils, gitignore, devshell }: { nixpkgs, dir }:
flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ devshell.overlays.default ];
    };
  in
  with pkgs; rec {
    # here's a good dev shell with all gems compiled
    devShells.default = pkgs.devshell.mkShell {
      name = "flask-example";
      packages = with pkgs; [
        python3
        poetry
      ];
    };

    packages.app = poetry2nix.mkPoetryApplication {
      projectDir = dir;
    };

    packages.default = pkgs.writeShellScriptBin "entrypoint" ''
      	  ${packages.app}/bin/app
    '';

  })

