{ flake-utils, gitignore, devshell, gomod2nix}: { nixpkgs, dir }:
flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs
      {
        inherit system;
        overlays = [ gomod2nix.overlays.default devshell.overlays.default ];
      };
  in
  rec {

    devShells.default = pkgs.mkShell
      {
        commands = [
          {
            name = "update-gomod2nix";
            help = "update gomod2nix.toml";
            command = "gomod2nix";
          }
        ];

        packages = with pkgs; [
          go
          gotools
          golangci-lint
          gopls
          gopkgs
          go-outline
          gomod2nix.packages.${system}.default
          (clojure.override { jdk = temurin-bin; })
          clojure-lsp
          temurin-bin
          neovim
        ];
      };

    packages = rec {
      app = pkgs.buildGoApplication {
        pname = "babashka-pod-docker";
        version = "0.0.1";
        src = ./.;
        pwd = ./.;
        CGO_ENABLED = 0;
        modules = ./gomod2nix.toml;
      };

      docker = pkgs.dockerTools.buildImage {
        name = "docker-pod";
        tag = "latest";
        config = {
          Cmd = [ "${app}/bin/babashka-pod-docker" ];
        };
      };

      default-linux = app.overrideAttrs (old: old // { GOOS = "linux"; GOARCH = "arm64"; });

      default = pkgs.writeShellScriptBin "entrypoint" ''
        	    ${app}/bin/babashka-pod-docker
        	  '';

      docker-arm64 = pkgs.dockerTools.buildImage {
        name = "docker-pod";
        tag = "latest";
        config = {
          Cmd = [ "${default-linux}/bin/linux_arm64/babashka-pod-docker" ];
        };
      };
    };

  }
)


