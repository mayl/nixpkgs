{ lib
, buildGoModule
, fetchFromGitHub
, ripgrep
, buf
, grpc-gateway
, protoc-gen-go
, protoc-gen-go-grpc
, makeWrapper
, sudo
, runtimeShell
, iproute2
, bridge-utils
, dnsmasq
}:
buildGoModule rec {
  pname = "ops"; version = "0.1.41";

  nativeBuildInputs = [ ripgrep buf grpc-gateway protoc-gen-go protoc-gen-go-grpc makeWrapper ];

  src = fetchFromGitHub {
    owner = "nanovms";
    repo = pname;
    rev = version;
    sha256 = "sha256-K4OcS/1/nUdMN+NUxQ6RM+dKLqQbQB3LIVmDIupeUyo=";
  };

  postUnpack = ''
    for f in $(rg --files-with-matches /bin/)
    do
      substituteInPlace $f --replace "/bin/" ""
    done
  '';

  proxyVendor = true; # Doesn't build otherwise

  vendorHash = "sha256-xrlvhPKN9PSlgltmNPPoGZ5/OeJUZc2gsv5QbYXsu4w=";

  # Some tests fail
  doCheck = false;
  doInstallCheck = true;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/nanovms/ops/lepton.Version=${version}"
  ];

  preBuild = ''
    export HOME=$(mktemp -d)
    make generate
  '';

  postInstall = ''
    wrapProgram $out/bin/ops --prefix PATH ${lib.makeBinPath [iproute2 sudo bridge-utils dnsmasq runtimeShell]}
  '';

  meta = with lib; {
    description = "Build and run nanos unikernels";
    homepage = "https://github.com/nanovms/ops";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ dit7ya ];
    mainProgram = "ops";
  };
}
