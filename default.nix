{
  pkgs ? import <nixpkgs> {overlays = []; configuration = {};},
  lib ? pkgs.lib,
}: let
  fetchNixpkgs = {
    rev,
    hash,
  }: pkgs.fetchFromGitHub {
    name = "nixpkgs-${rev}";
    owner = "NixOS";
    repo = "nixpkgs";
    inherit rev hash;
  };

  patchNixpkgs = nixpkgs: patches:
    pkgs.runCommandLocal "${nixpkgs.name}-patched" {src = nixpkgs;} ''
      cp -r "$src" "$out"
      cd "$out"
      chmod -R +w .
      for p in ${lib.escapeShellArgs patches}; do
          ${pkgs.gnupatch}/bin/patch -p1 --no-backup-if-mismatch <"$p"
      done
    '';

  workingCommit = {
    rev = "9e6465a6975ea07eb71eed0345954c68c12d3f6c";
    hash = "sha256-Lvxr3t5FRM9yNuHJCwvVjnxT+/5h3zOt6bzQemifXCI=";
  };
  brokenCommit = {
    rev = "f3160e4c2f381527bc98cf456bf2446fc480ef42";
    hash = "sha256-rCnw+CE2g0+0jnbvKs9BIYKF2w3C5w15xpwDq6ueO1M=";
  };

  fixPatches = map pkgs.fetchpatch [
    # nixos/hyperv-guest: remove the now useless videoMode option
    {
      url = "https://github.com/NixOS/nixpkgs/commit/b20e6abfaf51eec59a154672344d0184e48840da.patch";
      hash = "sha256-pZ/a0io31ilpZgg7slZb0EyFKqMsAwglHbouozsi/HA";
    }
    # linux/common-config: disable FB_HYPERV when DRM_HYPERV is available
    {
      url = "https://github.com/NixOS/nixpkgs/pull/372743/commits/c00e9ebd9d2a931518b2346bf25b7648c49c8344.patch";
      hash = "sha256-vnucnjBNXJ0IQRlRqU8rP4pGx8p7KtRNWEs0tibcD2U=";
    }
  ];

  buildHypervImage = tag: nixpkgs: extraConfig: let
    pkgs = import nixpkgs {overlays = []; configuration = {};};
    inherit (pkgs) nixos-generators;
    args = {
      inherit nixpkgs;
      configuration = {config, pkgs, ...}: {
        imports = [./configuration.nix extraConfig];
        hyperv.vmDerivationName = "nixos-hyperv-372743-${tag}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
        hyperv.vmFileName = "nixos-372743-${tag}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.vhdx";
      };
      formatConfig = "${nixos-generators}/share/nixos-generator/formats/hyperv.nix";
    };
  in
    (import "${nixos-generators}/share/nixos-generator/nixos-generate.nix" args).config.system.build.hypervImage;

  workingNixpkgs = fetchNixpkgs workingCommit;
  brokenNixpkgs = fetchNixpkgs brokenCommit;
  fixedNixpkgs = patchNixpkgs brokenNixpkgs fixPatches;

in {
  working = buildHypervImage "working" workingNixpkgs {};
  broken = buildHypervImage "broken" brokenNixpkgs {};
  broken-xserver-disabled = buildHypervImage "broken-no-x" brokenNixpkgs ({lib, ...}: {services.xserver.enable = lib.mkForce false;});
  fixed = buildHypervImage "fixed" fixedNixpkgs {};
  fixed-xserver-disabled = buildHypervImage "fixed-no-x" fixedNixpkgs ({lib, ...}: {services.xserver.enable = lib.mkForce false;});
}
