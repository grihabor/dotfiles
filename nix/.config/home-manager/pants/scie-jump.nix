{
  lib,
  stdenv,
  xxd,
  fetchFromGitHub,
  rustPlatform,
}: let
  scie-jump = rustPlatform.buildRustPackage rec {
    pname = "jump";
    version = "v1.0.0";
    src = fetchFromGitHub {
      owner = "a-scie";
      repo = pname;
      rev = version;
      hash = "sha256-6jg8lSoPtZAUO3oJuQ/Lf0LhDzxB446NhyFWfvRautI=";
    };

    cargoLock = {
      lockFile = ./scie-jump-cargo.lock;
      outputHashes = {
        "dotenvs-0.1.0" = "sha256-NnnD4W0SSa/6Ty9w+VHgN7amaG6ng61M6Lhg4wHP+9s=";
      };
    };
    cargoHash = "";

    meta = {
      description = "A Self Contained Interpreted Executable Launcher";
      homepage = "https://github.com/a-scie/jump";
    };
  };
in
  stdenv.mkDerivation {
    pname = "scie-jump";
    version = scie-jump.version;

    buildInputs = [
      scie-jump
    ];

    src = builtins.filterSource (path: type: false) ./.;

    # https://github.com/a-scie/jump/blob/v1.0.0/package/src/main.rs#L24-L52
    installPhase = ''
      BINARY=${scie-jump}/bin/scie-jump

      # https://github.com/a-scie/jump/blob/v1.0.0/package/src/main.rs#L47
      SIZE=$(stat --printf="%s" $BINARY)
      TOTAL=$((SIZE+8))
      printf "0: %.8x" $TOTAL |
          sed -E 's/0: (..)(..)(..)(..)/0: \4\3\2\1/' |
          ${xxd}/bin/xxd -r -g0 >size.bin
      echo "total size:"
      ${xxd}/bin/xxd size.bin

      # https://github.com/a-scie/jump/blob/v1.0.0/jump/src/jump.rs#L9
      printf "\x19\x72\x4a\x53" >magic.bin
      echo "magic:"
      ${xxd}/bin/xxd magic.bin

      mkdir -p $out/bin
      cat $BINARY size.bin magic.bin > $out/bin/jump
      chmod +x $out/bin/jump
    '';

    fixupPhase = "true";
  }
