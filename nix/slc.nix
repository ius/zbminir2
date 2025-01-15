{
  stdenv,
  fetchzip,
  lib,
  zlib,
  sqlite,
  jdk17_headless,
  writeText,
  writeTextDir,
  makeWrapper,
  autoPatchelfHook,
  libxcrypt-legacy,
  libuuid,
  readline70,
  ncurses5,
  symlinkJoin,
  xz,
  bzip2,
  callPackage,
}:

let
  readline70_compat63 = symlinkJoin {
    name = "readline70_compat63";
    paths = [ readline70 ];
    postBuild = ''
      ln -s $out/lib/libreadline.so $out/lib/libreadline.so.6
    '';
  };

  libgdbm3 = callPackage ./gdbm3.nix {};

  zap-chip = callPackage ./zap-chip/package.nix {};

  apack = (writeTextDir "apack.json" (
    builtins.replaceStrings ["@zap@"] ["../../../${zap-chip}/bin"] (
      builtins.readFile ./apack.json
    )
  ));
in
stdenv.mkDerivation {
  pname = "slc-cli";
  version = "5.10.0.0";

  src = fetchzip {
    url = "https://www.silabs.com/documents/login/software/slc_cli_linux.zip";
    hash = "sha256-Lsv+v8V5CwqggavQanL6LCBLG7y4NPeBB5bf9rRH7Oc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    jdk17_headless
    zlib
    sqlite
    libxcrypt-legacy
    libuuid
    ncurses5
    readline70_compat63
    xz
    bzip2
    libgdbm3
  ];

  setupHook = writeText "setup-hook" ''
    addToSearchPath PATH @out@/bin/slc-cli
  '';

  installPhase = ''
    runHook preInstall

    mkdir "$out"
    cp -ra $src/* "$out"

    runHook postInstall
  '';

  autoPatchelfLibs = [
    "${lib.makeLibraryPath [ jdk17_headless ]}/openjdk/lib/server/libjvm.so"
  ];

  postFixup = ''
    wrapProgram "$out/bin/slc-cli/slc-cli" \
      --prefix PATH : ${lib.makeBinPath [ jdk17_headless ]} \
      --set STUDIO_ADAPTER_PACK_PATH "${apack}"
  '';
}
