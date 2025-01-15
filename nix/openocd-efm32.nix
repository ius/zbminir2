{ lib, fetchFromGitHub, openocd, autoreconfHook, ... }:
let
  patchSrc = fetchFromGitHub {
    owner = "knieriem";
    repo = "openocd-efm32-series2";
    rev = "fe1a6946455e4d7dc582df52eb0bc354775ed3b6";
    hash = "sha256-0KzRvqqN1FDWMYSOiQTNrJmC3h9tPvXl1CW+CB5ay7I=";
  };
in
  openocd.overrideAttrs (final: prev: {
    src  = fetchFromGitHub {
      owner = "openocd-org";
      repo = "openocd";
      rev = "2e60e2eca9d06dcb99a4adb81ebe435a72ab0c7fA";
      hash = "sha256-x5fTOKSpWja82Ufa77w5vEAM4Gp0eF8g0ETAwM/Ay9s=";
    };

    patchPhase = ''
      patch -Np1 < ${patchSrc}/efm32s2/adjust_openocd.patch
      cp ${patchSrc}/efm32s2/efm32s2.c src/flash/nor/
    '';

    nativeBuildInputs = prev.nativeBuildInputs ++ [ autoreconfHook ];
  })
