{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "doppler";
  version = "3.37.0";

  src = fetchFromGitHub {
    owner = "dopplerhq";
    repo = "cli";
    rev = version;
    sha256 = "sha256-GrrjfuDor92535yzoxAudlI4vUrCittsdQeXxuUwNww=";
  };

  vendorSha256 = "sha256-VPxHxNtDeP5CFDMTeMsZYED9ZGWMquJdeupeCVldY/E=";

  ldflags = [ "-X github.com/DopplerHQ/cli/pkg/version.ProgramVersion=v${version}" ];

  postInstall = ''
    mv $out/bin/cli $out/bin/doppler
  '';

  meta = with lib; {
    homepage = "https://doppler.com";
    description = "The official CLI for interacting with your Doppler Enclave secrets and configuation";
    license = licenses.asl20;
    maintainers = with maintainers; [ lucperkins ];
  };
}
