{ config, pkgs, lib, ... }:

{
  imports = [
    ./common.nix
    ../modules/printer-stack.nix
    (import ../modules/deploy.nix { board = "pi4"; })
  ];

  networking.hostName = "isame-pi4";
}
