{ config, pkgs, lib, ... }:

{
  imports = [ ./common-pi.nix ];

  networking.hostName = lib.mkForce "mainsail-rpi4";

  # sudo pull-config [branch] - grabs a branch from github (main if none
  # given) and rebuilds in place. handy for testing a save-config branch.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "pull-config" ''
      branch="''${1:-main}"
      exec nixos-rebuild switch --flake "github:JacKC-s/isame-pi-cfg/$branch#rpi4" "''${@:2}"
    '')
  ];
}
