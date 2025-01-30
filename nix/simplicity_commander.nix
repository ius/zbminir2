{ stdenv, fetchzip, lib, zlib, glib, dbus, krb5, systemd, udev, autoPatchelfHook, ...}:

stdenv.mkDerivation {
  pname = "simplicity-commander";
  version = "1v17p0b1771";

  src = fetchzip {
    url = "https://r2.pargon.nl/SimplicityCommander-Linux_1v17p0b1771.zip";
    hash = "sha256-eFWHgrmkOgP77pn1vaOFVNqVkbHPHKBvE6yNDPTdhRM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    glib
    dbus.lib
    krb5
    systemd
  ];

  appendRunpaths = [
    "${udev}/lib"
  ];

  unpackPhase = ''
    mkdir "$out"

    tar -C "$out" -xf $src/Commander-cli_linux_x86_64_$version.tar.bz
  '';

  postInstall = ''
    mkdir "$out/bin"
    for t in commander-cli edge siling; do
      ln -s "$out/commander-cli/$t" "$out/bin/$t"
    done
  '';
}
