{
  stdenv,
  fetchFromGitHub ,
}:
stdenv.mkDerivation {
  name = "complete-alias";
  src = fetchFromGitHub {
    owner = "cykerway";
    repo = "complete-alias";
    rev = "7f2555c2fe7a1f248ed2d4301e46c8eebcbbc4e2";
    hash = "sha256-yohvfmfUbjGkIoX4GF8pBH+7gGRzFkyx0WXOlj+Neag=";
  };
  phases = ["unpackPhase" "installPhase"];
  installPhase = ''
    mkdir -p $out
    cp $src/complete_alias $out/complete_alias
  '';
}
