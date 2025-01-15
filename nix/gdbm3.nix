{
  lib,
  fetchurl,
  stdenv,
  testers,
  updateAutotoolsGnuConfigScriptsHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gdbm";
  version = "1.8.3";

  src = fetchurl {
    url = "mirror://gnu/gdbm/gdbm-${finalAttrs.version}.tar.gz";
    hash = "sha256-zDQDOKLii0AFirnrU1SiHVP4ihWC6iG6C7GFw3ooHck=";
  };

  nativeBuildInputs = [ updateAutotoolsGnuConfigScriptsHook ];

  configureFlags = [ (lib.enableFeature true "libgdbm-compat") ];

  setOutputFlags = false; # --docdir is not recognized

  doCheck = true;

  enableParallelBuilding = true;

  patchPhase = ''
    substituteInPlace Makefile.in \
      --replace-quiet '-o $(BINOWN) -g $(BINGRP)' "" \
      --replace-quiet '$(srcdir)/mkinstalldirs' "mkdir -p"
  '';

  installTargets = [
    "install-compat"
    "install"
  ];

  # create symlinks for compatibility
  postInstall = ''
    install -dm755 ''${!outputDev}/include/gdbm
    pushd ''${!outputDev}/include/gdbm
    ln -s ../dbm.h dbm.h
    ln -s ../gdbm.h gdbm.h
    ln -s ../ndbm.h ndbm.h
    popd
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "gdbmtool --version";
    };
  };
})
