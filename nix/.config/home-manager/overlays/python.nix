# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#overriding-python-packages-overriding-python-packages
final: prev: (let
  python = let
    packageOverrides = python-final: python-prev: {
      pynvim = python-prev.pynvim.overridePythonAttrs (old: rec {
        pname = "pynvim";
        version = "0.5.0";
        src = prev.fetchPypi {
          inherit pname version;
          hash = "sha256-6AoR9vXRlMake+pBNbkLVfrKJNo1RNp89KX3uo+wkhU=";
        };
      });
    };
  in
    prev.python3.override {
      inherit packageOverrides;
      self = python;
    };
in {
  python3 = python;
})
