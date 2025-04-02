# Allow overriding nixpkgs source, default to <nixpkgs> channel
{ pkgs ? import <nixpkgs> {} }:

let
  # Define the Go application build
  gateway-operator = pkgs.buildGoModule rec {
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
  };
in
{
  # Expose the Go build derivation
  inherit gateway-operator;

  # Define the Docker image build using the Go application
  dockerImage = pkgs.dockerTools.buildImage {
    name = "gateway-operator"; # Image name
    tag = "latest";   # Image tag

    # Use the compiled Go binary as the entrypoint
    config = {
      # The binary is located in the 'bin' directory of the Go build output
      Entrypoint = [ "${gateway-operator}/bin/${gateway-operator.pname}" ];
      # You might need to add Cmd = [ "--some-flag" ]; if your app needs arguments
    };

    # Copy necessary files into the image root filesystem
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [
        gateway-operator # Includes the binary in /bin
        pkgs.dockerTools.caCertificates # Standard CA certificates for TLS/HTTPS
        # Add other necessary files or directories here, e.g.:
        # ./config # If you need configuration files
        # ./migrations # If you have database migrations
      ];
      # Ensure pathsToLink creates necessary directories like /bin
      pathsToLink = [ "/bin" ];
    };
  };
}
# This part is now moved inside the 'let' block above and wrapped in the final attribute set.