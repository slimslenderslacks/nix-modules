{
  description = "Node.js application flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gomod2nix.url = "github:nix-community/gomod2nix";
    nix-filter.url = "github:numtide/nix-filter";
  };
  outputs = { self, flake-utils, devshell, gitignore, gomod2nix, nix-filter, ... }:
    {
      node-project = import ./node.nix {
        inherit flake-utils devshell gitignore;
      };
      java-project = import ./java.nix {
        inherit flake-utils devshell gitignore;
      };
      golang-project = import ./golang.nix {
        inherit flake-utils devshell gitignore gomod2nix;
      };
      ruby-project = import ./ruby.nix {
        inherit flake-utils devshell gitignore nix-filter;
      };
      python-project = import ./python.nix {
        inherit flake-utils devshell gitignore;
      };

    };
}
