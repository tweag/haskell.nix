let
  sources = import (../nix/sources.nix) {};
  nixpkgs = import sources.nixpkgs-2009 {};
  args = '' --arg userDefaults "$HOME/.config/hix/hix.conf" --arg src ./.'';
in nixpkgs.symlinkJoin {
  name = "hix";
  paths = [
    (nixpkgs.writeScriptBin "hix-shell" ''
      nix-shell ${./..}/hix/project.nix ${args} -A shell "$@"
    '')
    (nixpkgs.writeScriptBin "hix-build" ''
      nix-build ${./..}/hix/project.nix ${args} "$@"
    '')
    (nixpkgs.writeScriptBin "hix-instantiate" ''
      nix-instantiate ${./..}/hix/project.nix ${args} "$@"
    '')
    (nixpkgs.writeScriptBin "hix-env" ''
      nix-env -f ${./..}/hix/project.nix ${args} "$@"
    '')
    (nixpkgs.writeScriptBin "hix" ''
      cmd=$1
      shift
      case $cmd in
      update)
        nix-env -iA hix -f https://github.com/input-output-hk/haskell.nix/tarball/master
        ;;
      build|dump-path|eval|log|path-info|run|search|show-derivation|sign-paths|verify|why-depends)
        nix $cmd -f ${./..}/hix/project.nix ${args} "$@"
        ;;
      repl)
        nix $cmd ${./..}/hix/project.nix ${args} "$@"
        ;;
      *)
        nix $cmd "$@"
        ;;
      esac
    '')
  ];
} // {
  project = import ./project.nix; 
}