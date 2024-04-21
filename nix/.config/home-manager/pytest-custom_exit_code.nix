{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  wheel,
  pytest,
}:
buildPythonPackage rec {
  pname = "pytest-custom_exit_code";
  version = "0.3.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Uf//DuLB3cwSQuLdsqX9AkgnF+M6IybvMw46pDAkRjU=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [
    pytest
  ];
}
