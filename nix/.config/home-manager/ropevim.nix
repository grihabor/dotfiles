{
  buildPythonPackage,
  fetchPypi,
  rope,
  ropemode,
  setuptools,
  wheel,
}:
buildPythonPackage rec {
  pname = "ropevim";
  version = "0.8.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-d5Xc9JvlT2FyfPt+W/w+I+9NwJwbZXIXMLH72v1iNyU=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    setuptools
    rope
    ropemode
  ];
}
