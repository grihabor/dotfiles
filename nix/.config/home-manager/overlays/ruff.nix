final: prev: {
  ruff = prev.ruff.overrideAttrs (old: rec {
    version = "0.1.6";

    src = prev.fetchFromGitHub {
      owner = "astral-sh";
      repo = "ruff";
      rev = "refs/tags/v${version}";
      hash = "sha256-EX1tXe8KlwjrohzgzKDeJP0PjfKw8+lnQ7eg9PAUAfQ=";
    };

    cargoHash = "sha256-ueWSBYXcdaxagjFjxfsImulOs0zVVqGHmfXp4pQLaMM=";
  });
}
