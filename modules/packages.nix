# packages.txt at the repo root is a flat list of nixpkgs attribute
# names, one per line, installed on both boards. handy for "I just need
# this one thing" without opening an editor.
#
# `nix profile install nixpkgs#foo` works too for a quick one-off test,
# but it lives only on that one sd card and won't survive a reflash -
# once you know you want it kept, add the name here and save-config.
{ pkgs, lib, ... }:
let
  names = lib.filter (n: n != "") (lib.splitString "\n" (builtins.readFile ../packages.txt));
in
{
  environment.systemPackages = map (n: pkgs.${n}) names;
}
