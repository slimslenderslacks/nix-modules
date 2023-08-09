{ flake-utils, gitignore, devshell, gomod2nix}: { nixpkgs, dir, name, version, package-overlay}:
flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs
      {
        inherit system;
        overlays = [ gomod2nix.overlays.default devshell.overlays.default ];
      };
  in
  rec {

    devShells.default = pkgs.devshell.mkShell
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

    packages = package-overlay pkgs rec {
      app = pkgs.buildGoApplication {
        pname = name;
        version = version;
        src = dir;
        pwd = dir;
        CGO_ENABLED = 0;
        modules = (dir + /gomod2nix.toml);
      };

      docker = pkgs.dockerTools.buildImage {
        name = "docker-pod";
        tag = "latest";
        config = {
          Cmd = [ "${app}/bin/${name}" ];
        };
      };

      default-linux = app.overrideAttrs (old: old // { GOOS = "linux"; GOARCH = "arm64"; });

      docker-arm64 = pkgs.dockerTools.buildImage {
        name = "docker-pod";
        tag = "latest";
        config = {
          Cmd = [ "${default-linux}/bin/linux_arm64/${name}" ];
        };
      };
    };

  }
)


