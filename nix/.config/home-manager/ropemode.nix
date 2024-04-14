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
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-mbjSLfcb41jhDMQ1+5cUDlelDEK4Rr1KckkcV0TdBHA=";
  };

  nativeBuildInputs = [
    setuptools
    setuptools-scm
    wheel
  ];

  propagatedBuildInputs  = [];
}
