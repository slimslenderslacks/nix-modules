{ flake-utils, gitignore, devshell, nix-filter }: { nixpkgs, dir, name, version }:
flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ devshell.overlays.default ];
    };
    gems = pkgs.bundlerEnv {
      name = "gems-for-github-linguist";
      gemdir = dir;
    };
  in
  {
    # here's a good dev shell with all gems compiled
    devShells.default = pkgs.devshell.mkShell {
      packages = with pkgs; [
        bundix
        openssl
        gems
        gems.wrappedRuby
      ];
      commands = [
        {
          name = "update-deps";
          help = "Update ruby gems";
          command = ''
            bundlix
          '';
        }
      ];

    };

    # this package includes our ruby application with pre-compiled gems
    packages.default = pkgs.stdenv.mkDerivation {
      inherit version;
      pname = name;
      src = nix-filter.lib {
        root = dir;
        include = [ (nix-filter.lib.matchExt "rb") ];
      };
      buildInputs = [ gems pkgs.ruby ];
      installPhase = ''
        mkdir -p $out/{bin,share}
        cp -r ./*.rb $out/share
        bin=$out/bin/entrypoint
        cat > $bin <<EOF
          #!/bin/sh -e
          exec ${gems}/bin/bundle exec ${pkgs.ruby}/bin/ruby $out/share/main.rb "\$@"
        EOF
        chmod +x $bin
      '';
      meta = {
        mainProgram = "entrypoint";
      };
    };

    # if we just want to distribute a binary from another gem (no ruby code of our own), this would do it!
    packages.just-app = pkgs.bundlerApp {
      pname = "github-linguist";
      gemdir = dir;
      exes = [ "github-linguist" ];
    };
  })

