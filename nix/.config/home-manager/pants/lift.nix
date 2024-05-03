{
  fetchFromGitHub,
  python3,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "lift";
  version = "v0.3.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "a-scie";
    repo = pname;
    rev = version;
    hash = "sha256-Blp2dmmajvGPxkaqkls3IB7untCopykvC6rx2PNVnvc=";
  };

  nativeBuildInputs = with python3.pkgs; [
    setuptools
  ];

  propagatedBuildInputs = with python3.pkgs; [
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
}
