final: prev: { haskell-nix = prev.haskell-nix // { hix = {
  project =
    { src
    , userDefaults ? {}
    , subDir ? null
    , name ? null
    , nixpkgsPin ? null
    , compiler-nix-name ? null
    , projectFileName ? null
    , index-state ? null
    , configureArgs ? null
    , pkg-def-extras ? null
    , modules ? null
    , extra-hackages ? null
    , cabalProject ? null
    , cabalProjectLocal ? null
    , cabalProjectFreeze ? null
    , sha256map ? null
    , lookupSha256 ? null

    # Args passed to shellFor when not null
    , packages ? null
    , components ? null
    , additional ? null
    , withHoogle ? null
    , exactDeps ? null
    , tools ? null
    , packageSetupDeps ? null
    , enableDWARF ? null
    , ...}@commandArgs:
    let
      commandArgs' =
        builtins.listToAttrs (
          builtins.concatMap (
            name:
              if commandArgs.${name} == null
                then []
                else [{ inherit name; value = commandArgs.${name}; }]
        ) (builtins.attrNames commandArgs));
      defaultArgs = {
        subDir = "";
        name = "hix-project";
        compiler-nix-name = "ghc8104";
        tools = {
          cabal = "latest";
        };
      };
      importDefaults = src:
        if src == null || !(__pathExists src)
          then {}
          else import src;
      userDefaults = importDefaults (commandArgs.userDefaults or null);
      projectDefaults = importDefaults (toString (src.origSrcSubDir or src) + "/nix/hix.nix");
      args = 
           defaultArgs
        // userDefaults
        // projectDefaults
        // commandArgs'
        // {
          tools = defaultArgs.tools
            // userDefaults.tools or {}
            // projectDefaults.tools or {}
            // commandArgs.tools or {};
      };
      projectArgNames =
        [ "compiler-nix-name" "name" "projectFileName" "index-state" "configureArgs" "pkg-def-extras"
          "modules" "extra-hackages" "cabalProject" "cabalProjectLocal" "cabalProjectFreeze"
          "sha256map" "lookupSha256"
        ];
      projectdArgs = 
        builtins.listToAttrs (
          builtins.concatMap (
            name:
              if args ? ${name}
                then [{ inherit name; value = args.${name}; }]
                else [])
            projectArgNames
        );
      root =
        if __pathExists (toString (src.origSrcSubDir or src) + "/.git")
          then final.haskell-nix.haskellLib.cleanGit {
            name = args.name;
            src = args.src;
          }
          else src;
      projectFuncion =
        if !(args ? projectFileName) && __pathExists (
              toString (src.origSrcSubDir or src)
            + (if args.subDir == ""  then "" else "/" + args.subDir)
            + "/cabal.project")
          then final.haskell-nix.cabalProject'
          else final.haskell-nix.project';
      project = projectFuncion (projectdArgs // {
        src = final.haskell-nix.haskellLib.appendSubDir {
          src = root;
          inherit (args) subDir;
          includeSiblings = true;
        };
      });
      shellArgs = builtins.removeAttrs args (projectArgNames ++
        [ "src" "userDefaults" "subDir" "nixpkgsPin" "haskellNix" "nixpkgs" "nixpkgsArgs" "pkgs" ]);
    in project // {
      shell = project.shellFor shellArgs;
    };
}; }; }