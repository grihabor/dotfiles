# TODO
# 1. fetchFromGithub https://github.com/a-scie/lift
# 2. nox -e package
# https://github.com/a-scie/lift/blob/main/.github/workflows/release.yml#L66
# or
# 2. package manually
# https://github.com/a-scie/lift/blob/main/noxfile.py#L337-L358
{
  pex,
  stdenv,
  fetchFromGitHub,
  rsync,
  shiv,
  python3Packages,
}: let
  pname = "lift";
  version = "v0.3.4";
  src = fetchFromGitHub {
    owner = "a-scie";
    repo = pname;
    rev = version;
    hash = "sha256-Blp2dmmajvGPxkaqkls3IB7untCopykvC6rx2PNVnvc=";
  };

  liftPythonPackage = with python3Packages;
    buildPythonPackage {
      inherit pname version src;
      pyproject = true;
      nativeBuildInputs = [
        setuptools
      ];
      propagatedBuildInputs = [
        appdirs
        click
        click-didyoumean
        click-log
        filelock
        httpx
        packaging
        psutil
        tqdm
      ];
    };
in
  liftPythonPackage
#in
#  stdenv.mkDerivation {
#    inherit pname version src;
#
#    buildInputs = [
#    ];
#
#    buildPhase = let
#      prefix = "./venv/lib/python3.11/site-packages/";
#    in ''
#
#      mkdir -p ${prefix}
#      ${rsync}/bin/rsync -r ${liftPythonPackage}/lib/python3.11/site-packages/ ${prefix}
#      ${rsync}/bin/rsync -r ${python3Packages.appdirs}/lib/python3.11/site-packages/ ${prefix}
#      # click
#      # click-log
#      # click_didyoumean
#      # filelock
#      # httpx
#      # packaging
#      # psutil
#      # tqdm
#
#
#
#    '';
#
#    installPhase = ''
#      # https://github.com/a-scie/lift/blob/v0.3.4/noxfile.py#L287-L298
#      ${shiv}/bin/shiv -p '/usr/bin/env python3.11' -c science --site-packages ./lib/python3.11/site-packages/ --reproducible -o $out
#    '';
#  }
