# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#overriding-python-packages-overriding-python-packages
final: prev: (let
  python = let
    packageOverrides = python-final: python-prev: {
      # TODO remove once this fix is released:
      # https://github.com/pex-tool/pex/commit/36dd2374569b5f3fbef54918e6ba3bd1ff852b61
      hatchling = python-prev.hatchling.overridePythonAttrs (old: rec {
        pname = "hatchling";
        version = "1.21.1";
        src = prev.fetchPypi {
          inherit pname version;
          hash = "sha256-u6RARToiTn1EeEV/oujYw2M3Zbr6Apdaa1O5v5F5gLw=";
        };
      });
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
