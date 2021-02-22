{ src
, userDefaults ? {}
, nxipkgs ? null
, nixpkgsPin ? null
, pkgs ? null
, ...}@commandArgs:
let
  sources = import ../nix/sources.nix;
  commandArgs' =
    builtins.listToAttrs (
      builtins.concatMap (
        name:
          if commandArgs.${name} == null
            then []
            else [{ inherit name; value = commandArgs.${name}; }]
    ) (builtins.attrNames commandArgs));
  defaultArgs = {
    nixpkgsPin = "nixpkgs-unstable";
  };
  importDefaults = src:
    if src == null || !(__pathExists src)
      then {}
      else import src;
  userDefaults = importDefaults (commandArgs.userDefaults or null);
  projectDefaults = importDefaults (toString (src.origSrcSubDir or src) + "/nix/hix.nix");
  args = {
    haskellNix = import ./.. {};
    nixpkgs = args.haskellNix.sources.${args.nixpkgsPin};
    inherit (args.haskellNix) nixpkgsArgs;
    pkgs = import args.nixpkgs args.nixpkgsArgs;
  } // defaultArgs
    // userDefaults
    // projectDefaults
    // commandArgs';
in args.pkgs.haskell-nix.hix.project commandArgs
