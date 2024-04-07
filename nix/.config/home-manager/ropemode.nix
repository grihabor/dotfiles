{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
  wheel,
}:
buildPythonPackage rec {
  pname = "ropemode";
  version = "0.6.1";
  pyproject = false;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-mbjSLfcb41jhDMQ1+5cUDlelDEK4Rr1KckkcV0TdBHA=";
  };

  build-system = [
    setuptools
    setuptools-scm
    wheel
  ];

  dependencies = [];
}
