{ flake-utils, gitignore, devshell }: { nixpkgs, dir, main-class }:
flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ devshell.overlays.default ];
    };
    maven = with pkgs; (buildMaven (dir + /project-info.json));
    src = dir;
  in
  rec {

    # package to represent a local .m2 repo
    packages.repo = maven.repo;

    # package to run the maven plugin that will transform pom.xml to a project-info.xml
    packages.create-project-info = pkgs.writeShellScriptBin "app" ''
      ${pkgs.maven}/bin/mvn org.nixos.mvn2nix:mvn2nix-maven-plugin:mvn2nix
    '';

    # package to create the jars for this app
    packages.jars = pkgs.stdenv.mkDerivation {
      name = "${maven.info.project.artifactId}-${maven.info.project.version}";

      src = builtins.filterSource
        (path: type:
          (toString path) != (toString (src + "/target")) && (toString path)
          != (toString (src + "/.git")))
        src;

      buildInputs = [
        pkgs.maven
        pkgs.gcc-unwrapped.lib
      ];

      buildPhase = "mvn --offline --settings ${maven.settings} compile";

      installPhase = ''
                    mvn --offline --settings ${maven.settings} package
        	        mkdir -p "$out"/lib
                    mvn --offline --settings ${maven.settings} dependency:build-classpath -Dmdep.outputFile=$out/lib/classpath.txt
                    mv target/*.jar "$out"/lib
      '';
    };

    # default package is an entrypoint to run the jars
    packages.default = pkgs.writeShellScriptBin "entrypoint" ''
      export LD_LIBRARY_PATH=${pkgs.gcc-unwrapped.lib}/lib64

      ${pkgs.temurin-bin}/bin/java -cp ${packages.jars}/lib/${maven.info.project.artifactId}-${maven.info.project.version}.jar:"$(< ${packages.jars}/lib/classpath.txt)" ${main-class}
    '';

    devShells.default = pkgs.devshell.mkShell
      {
        packages = [
          pkgs.maven
          pkgs.temurin-bin
        ];
        commands = [
          {
            name = "update-deps";
            help = "Update maven deps";
            command = ''
              nix run .#create-project-info;
            '';
          }
        ];
      };
  }
)

