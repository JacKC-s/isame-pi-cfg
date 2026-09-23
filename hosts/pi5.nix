{ config, pkgs, lib, ... }:

{
  imports = [
    ./common.nix
    ../modules/printer-stack.nix
    (import ../modules/deploy.nix { board = "pi5"; })
  ];

  networking.hostName = "isame-pi5";
}
