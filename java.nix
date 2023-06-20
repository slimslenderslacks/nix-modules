{ flake-utils, gitignore, devshell }: { nixpkgs, dir }:
flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs { inherit system; };
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
                    mv target/*.jar "$out"/lib
      '';
    };

    # default package is an entrypoint to run the jars
    packages.default = pkgs.writeShellScriptBin "entrypoint" ''
      export LD_LIBRARY_PATH=${pkgs.gcc-unwrapped.lib}/lib64
      ${pkgs.temurin-bin}/bin/java -cp ${packages.jars}/lib/deeplearning4j-example-sample-1.0.0-M2-bin.jar org.deeplearning4j.examples.sample.LeNetMNIST
    '';

    devShells.default = pkgs.mkShell
      {
        packages = [
          pkgs.maven
          pkgs.temurin-bin
        ];
      };
  }
)

