{
  description = "doom-d - TODO Add a description of your new project";

  inputs = {
    # Base dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    # Development (devenv and treefmt dependencies)
    treefmt-nix.url = "github:numtide/treefmt-nix";
    devenv.url = "github:cachix/devenv";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Project specific dependencies
  };

  # Here you can add additional binary cache substituers that you trust.
  # There are also some sensible default caches commented out that you
  # might consider using.
  nixConfig = {
    extra-trusted-public-keys = [
      # "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      # "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    extra-substituters = [
      # "https://devenv.cachix.org"
      # "https://cache.nixos.org"
      # "https://nix-community.cachix.org/"
    ];
  };

  outputs = inputs @ {flake-parts, ...}: let
    inherit (inputs) nixpkgs;
    inherit (lib.doom-d) mapModules flatten;

    # You should ideally use relative paths in each individual part from ./parts,
    # however, if needed you can use the `projectPath` variable that is passed
    # to every flakeModule to properly anchor your absolute paths.
    projectPath = ./.;

    # We extend the base <nixpkgs> library with our own custom helpers as well
    # as override any of the nixpkgs default functions that we'd like
    # to override. This instance is then passed to every part in ./parts so that
    # you can use it in your custom modules
    lib = nixpkgs.lib.extend (self: _super: {
      doom-d = import ./nix/lib {
        inherit inputs projectPath;
        pkgs = nixpkgs;
        lib = self;
      };
    });
    specialArgs = {inherit lib projectPath;};
  in
    flake-parts.lib.mkFlake {inherit inputs specialArgs;} {
      # We recursively traverse all of the flakeModules in ./parts and import only
      # the final modules, meaning that you can have an arbitrary nested structure
      # that suffices your needs. For example
      #
      # - ./nix/parts
      #   - modules/
      #     - nixos/
      #       - myNixosModule1.nix
      #       - myNixosModule2.nix
      #       - default.nix
      #     - home-manager/
      #       - myHomeModule1.nix
      #       - myHomeModule2.nix
      #       - default.nix
      #     - sharedModules.nix
      #    - pkgs/
      #      - myPackage1.nix
      #      - myPackage2.nix
      #      - default.nix
      #    - mySimpleModule.nix
      imports = flatten (mapModules ./nix/parts (x: x));

      # We use the default `systems` defined by the `nix-systems` flake, if you
      # need any additional systems, simply add them in the following manner
      #
      # `systems = (import inputs.systems) ++ [ "armv7l-linux" ];`
      systems = import inputs.systems;
      flake.lib = lib.doom-d;

      # Since the official flakes output schema is unfortunately very limited
      # you can enable the debug mode if you need to inspect certain outputs
      # of your flake. Simply
      #
      # 1. uncomment the following line
      # 2. hop into a repl from the project root - `nix repl`
      # 3. load the flake - `:lf .`
      #
      # After that you can inspect the flake from the root attribute `debug.flake`
      # debug = true;
    };
}
