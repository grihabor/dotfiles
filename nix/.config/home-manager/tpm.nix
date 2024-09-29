{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  name = "tpm";
  src = fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "99469c4a9b1ccf77fade25842dc7bafbc8ce9946";
    hash = "sha256-hW8mfwB8F9ZkTQ72WQp/1fy8KL1IIYMZBtZYIwZdMQc=";
  };
  phases = ["unpackPhase" "installPhase"];
  installPhase = ''
    cp -r $src $out
  '';
}
