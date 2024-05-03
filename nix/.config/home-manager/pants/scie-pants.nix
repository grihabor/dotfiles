{
  lib,
  cargo,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  scie-lift,
}: let
  pname = "scie-pants";
  version = "v0.11.0";
  src = fetchFromGitHub {
    owner = "pantsbuild";
    repo = pname;
    rev = version;
    hash = "sha256-UwhASnhBi4HjP1qiXJ0tjnQEOLmfBk2oOYNzDHLRKk4=";
  };
  scie-pants = rustPlatform.buildRustPackage rec {
    inherit pname version src;

    cargoHash = "sha256-Dii0U40575QjpdHJNw7nzabmqEYoAxXzxRUGfbQ21JA=";

    meta = {
      description = "A fast line-oriented regex search tool, similar to ag and ack";
      homepage = "https://github.com/BurntSushi/ripgrep";
      license = lib.licenses.unlicense;
      maintainers = [];
    };
  };
  scie-jump-src = fetchFromGitHub {
    owner = "a-scie";
    repo = pname;
    rev = version;
    hash = "sha256-6jg8lSoPtZAUO3oJuQ/Lf0LhDzxB446NhyFWfvRautI=";
  };
in
  stdenv.mkDerivation {
    name = "pants";
    src = src;

    buildInputs = [
      scie-pants
      cargo
    ];

    installPhase = ''
      ${scie-lift}/bin/science lift build --use-jump ${scie-jump-src} ./package/pbt.toml
    '';
  }
# TODO
# build binary sandwich via `cargo run -p package -- --dest-dir dist/ scie`
# https://github.com/pantsbuild/scie-pants/blob/main/.github/workflows/release.yml#L59
# or
# build manually
# https://github.com/pantsbuild/scie-pants/blob/main/package/src/main.rs#L157-L170
