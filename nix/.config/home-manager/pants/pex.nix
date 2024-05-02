{
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonApplication rec {
  pname = "pex";
  version = "2.2.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-g5D9v1CZ70viP0C/9lWwJvterJ2KH3oUCKRsxEr9Neg=";
  };

  nativeBuildInputs = with python3Packages; [
    hatchling
  ];
}
