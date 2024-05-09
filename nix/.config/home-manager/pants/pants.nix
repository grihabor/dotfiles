{
  lib,
  fetchFromGitHub,
  python39,
  rustPlatform,
  stdenv,
  cargo,
  protobuf,
  rust-bin,
  makeRustPlatform,
  rustVersion ? "1.75.0",
}: let
  cargo = rust-bin.stable.${rustVersion}.default;
  rustc = rust-bin.stable.${rustVersion}.default;
  rustPlatform = makeRustPlatform {
    inherit cargo rustc;
  };
  version = "2.20.0";
  revision = "release_${version}";
  src = fetchFromGitHub {
    owner = "pantsbuild";
    repo = "pants";
    rev = revision;
    hash = "sha256-tzpeYxzDfHbDkGAOCXjQfaLf6834c34zJS3DwahSMwI=";
  };
  pants_engine = stdenv.mkDerivation rec {
    inherit src version;
    pname = "pants-engine";

    cargoDeps = rustPlatform.importCargoLock {
      # curl -L -o pants-cargo.lock https://raw.githubusercontent.com/pantsbuild/pants/release_2.20.0/src/rust/engine/Cargo.lock
      lockFile = ./pants-cargo.lock;
      outputHashes = {
        "console-0.15.7" = "sha256-EsUtBySVj2aoGOPBteDKCY7PCehJoqEJXpjOyQlpCf4=";
        "deepsize-0.2.0" = "sha256-E73xdzYfpJASps3yz6sjL48Kimy44F2LvxndWzgV3dU=";
        "globset-0.4.10" = "sha256-1ucpIHxISBqjvKBAea7o2wSddWiIQr6tBiInk4kg0P0=";
        "indicatif-0.17.7" = "sha256-GxQM+y5zL1KW5HmN9UcuS3xNNiZC8neMCyGIoOMleLs=";
        "lmdb-rkv-0.14.0" = "sha256-yj0+3wRQkAyp5EYOe2WQeUt1D/3cXZK0XrH6qcxhaWw=";
        "notify-5.0.0-pre.15" = "sha256-LG6e3dSIqQcHbNA/uYSVJwn/vgcAH0noHK4x3QQdqVI=";
        "prodash-16.0.0" = "sha256-Dkn4BmsF1SnSDAoqW5QkjdzGHEq41y7S20Q/DkRCpVQ=";
      };
    };

    sourceRoot = "${src.name}/src/rust/engine";

    nativeBuildInputs = [
      python39
      protobuf
      rustPlatform.cargoSetupHook
    ];

    buildPhase = ''
      export CARGO_BUILD_RUSTC=${rustc}/bin/rustc

      # https://github.com/pantsbuild/pants/blob/release_2.20.0/src/rust/engine/.cargo/config#L4
      export RUSTFLAGS="--cfg tokio_unstable"

      # https://github.com/pantsbuild/pants/blob/release_2.20.0/src/rust/engine/BUILD#L32
      ${cargo}/bin/cargo build \
        --features=extension-module \
        --release \
        -p engine \
        -p client
    '';

    installPhase = ''

      mkdir -p $out/lib/
      cp target/release/libengine.so $out/lib/native_engine.so

      mkdir -p $out/bin/
      cp target/release/pants $out/bin/native_client
    '';
  };
in
  with python39.pkgs;
    buildPythonApplication {
      inherit version src;
      pname = "pants";
      pyproject = true;

      build-system = [
        setuptools
      ];
      # curl -L -O https://raw.githubusercontent.com/pantsbuild/pants/release_2.20.0/3rdparty/python/requirements.txt

      configurePhase = ''
        cat > pyproject.toml << EOF
        [build-system]
        requires = ["setuptools"]
        build-backend = "setuptools.build_meta"

        [project]
        name = "pants"
        version = "$version"

        [tool.setuptools.packages.find]
        where = ["src/python"]
        include = ["pants", "pants.*"]
        namespaces = false

        EOF
      '';
    }
