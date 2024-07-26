{
  lib,
  linkFarm,
  stdenv,
  fetchurl,
  deno,
}: {lockFile}: let
  denoLock = builtins.fromJSON (builtins.readFile lockFile);

  nativeCache = stdenv.mkDerivation {
    name = "deno-native-cache";
    buildCommand = ../build-deno-deps;
    __structuredAttrs = true;
    denoDeps = lib.flip lib.mapAttrsToList denoLock.remote (url: sha256: {
      inherit url;
      downloadPath = fetchurl {
        inherit url sha256;
        # "By default, esm.sh checks the User-Agent header to determine the build target." - https://esm.sh/#docs
        curlOptsList = ["--user-agent" "Deno/${deno.version}"];
      };
    });
  };

  npmRegistry = "registry.npmjs.org"; # TODO
  npmCacheSingleVersion = spec: info: let
    parts = builtins.match "(.+)@([^@]+)" spec;
    pname = builtins.elemAt parts 0;
    version = builtins.elemAt parts 1;
    baseName = lib.last (builtins.split "/" pname);
  in
    stdenv.mkDerivation {
      pname = "npm-${pname}";
      inherit version;
      passthru.npmPackageName = pname;
      src = fetchurl {
        url = "https://${npmRegistry}/${pname}/-/${baseName}-${version}.tgz";
        hash = info.integrity;
      };
      installPhase = ''
        cp -a . $out
      '';
    };
  npmCache = let
    packages = lib.mapAttrsToList npmCacheSingleVersion denoLock.npm.packages;
  in
    lib.flip lib.mapAttrsToList (lib.groupBy (pkg: pkg.npmPackageName) packages) (pname: versions:
      lib.map (pkg: {
        name = "${npmRegistry}/${pname}/${pkg.version}";
        path = pkg;
      })
      ++ {
        name = "${npmRegistry}/${pname}/registry.json";
        path = pkgs.writeText "${pname}-registry.json" (builtins.toJSON {
          name = pname;
          versions = lib.flip lib.map versions (pkg: {
            name = pkg.version;
            value = {
              dist = {
                tarball = "about:invalid";
                shasum = "0000000000000000000000000000000000000000";
                integrity = pkg.src.hash;
              };
              # TODO: dependencies, etc.? those and bin could be computed from package.json
              bin = null;
            };
          });
          dist-tags = {};
        });
      });
in
  assert denoLock.version == "2";
    linkFarm "deno-cache" {
      "deps" = nativeCache;
      "npm" = linkFarm "deno-cache-npm" npmCache;
    }
