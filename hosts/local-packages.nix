# reads local-packages.txt so save-config can just append/sort a plain
# list instead of having to edit nix syntax
{ pkgs, lib, ... }:
let
  names = lib.filter (n: n != "") (lib.splitString "\n" (builtins.readFile ./local-packages.txt));
in
{
  environment.systemPackages = map (n: pkgs.${n}) names;
}
