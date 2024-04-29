{
  scie-lift,
  lib,
  fetchFromGitHub,
  rustPlatform,
}: let
  scie-pants = rustPlatform.buildRustPackage rec {
    pname = "scie-pants";
    version = "0.11.0";

    src = fetchFromGitHub {
      owner = "pantsbuild";
      repo = pname;
      rev = version;
      hash = "sha256-+s5RBC3XSgb8omTbUNLywZnP6jSxZBKSS1BmXOjRF8M=";
    };

    cargoHash = "sha256-ywVmwtJT1rOsnT2kRKM1CSJZeh/N8sdGWZTCyUiTVRg=";

    meta = {
      description = "A fast line-oriented regex search tool, similar to ag and ack";
      homepage = "https://github.com/BurntSushi/ripgrep";
      license = lib.licenses.unlicense;
      maintainers = [];
    };
  };
in {
  # TODO
  # build binary sandwich via `cargo run -p package -- --dest-dir dist/ scie`
  # https://github.com/pantsbuild/scie-pants/blob/main/.github/workflows/release.yml#L59
  # or
  # build manually
  # https://github.com/pantsbuild/scie-pants/blob/main/package/src/main.rs#L157-L170
}
