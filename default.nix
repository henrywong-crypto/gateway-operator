let
  # Pin nixpkgs to a specific revision for reproducibility
  nixpkgs = builtins.fetchTarball {
    # Example: Fetch the nixos-24.05 stable branch
    url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixpkgs-unstable.tar.gz";
    # You can get this hash by running:
    # nix-prefetch-url --unpack <url>
    # Or by trying to build and copying the expected hash from the error message.
    sha256 = "sha256:1bimkzs7q9yqfvw9h4wgs3v2izvc7ya8qyy2v850ac5r548l022z"; # Placeholder, user needs to fetch this
  };
  pkgs = import nixpkgs {};
in
pkgs.buildGoModule rec {
  pname = "gateway-operator";
  version = "1.5.1"; # From VERSION file

  # Use the local source directory
  src = ./.;

  # vendorHash is calculated from go.sum and go.mod
  # You can get this hash by running:
  # nix-build -A gateway-operator.vendorSha256
  # Or by trying to build the package and copying the expected hash from the error message.
  vendorHash = "sha256-na+vukcDQJ6AtCfIjaY4Ep98E39nTYTvNdzmBtduS80="; # Placeholder, user needs to fetch this

  # Module path from go.mod: github.com/kong/gateway-operator
  # buildGoModule automatically uses the path relative to modRoot
  modRoot = ".";
  subPackages = [ "cmd" ]; # Build the main package in cmd/

  # Standard flags to strip debug info and symbols for smaller binary size
  ldflags = [ "-s" "-w" ];

  meta = with pkgs.lib; {
    description = "Kubernetes operator for managing Kong Gateway deployments";
    homepage = "https://github.com/kong/gateway-operator";
    license = licenses.asl20; # Apache License 2.0 from LICENSE file
    maintainers = with maintainers; [ ]; # User can add maintainers if desired
    mainProgram = "gateway-operator"; # Assuming the binary name matches pname
  };
}