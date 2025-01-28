with import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/branch-off-24.11.tar.gz";
  sha256 = "1gx0hihb7kcddv5h0k7dysp2xhf1ny0aalxhjbpj2lmvj7h9g80a";
}) {};
let
  slc = pkgs.callPackage ./slc.nix {};

  openocd-efm32 = pkgs.callPackage ./openocd-efm32.nix {};

  simplicity-commander = pkgs.callPackage ./simplicity_commander.nix {};

  # fetchzip to make sure we grab git lfs artifacts
  simplicity-sdk = pkgs.fetchzip {
    url = "https://github.com/SiliconLabs/simplicity_sdk/releases/download/v2024.12.0/gecko-sdk.zip";
    hash = "sha256-qlmzxtNGsKzXnIe38MBbxkAXECCh69ne1gNiQzyg9tE=";
    stripRoot = false;
  };
in
with pkgs;
mkShell {
  packages = [
    gcc-arm-embedded
    cmake
    ninja
    picocom
    rlwrap
    openocd-efm32
    python3Packages.universal-silabs-flasher

    slc
    simplicity-commander
  ];
  shellHook = ''
    export ARM_GCC_DIR=${gcc-arm-embedded}
    export SIMPLICITY_SDK=${simplicity-sdk}
    alias zb-uart="picocom -b 115200 --imap lfcrlf --omap delbs"
  '';
}
