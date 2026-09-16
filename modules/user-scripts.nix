{ pkgs, lib, ... }:

# Every regular, non-hidden file in ../scripts/bin becomes a command in the
# system profile.  Add a script there, rebuild, and it is available to every
# user on PATH as well as read-only at /etc/isame/scripts/<name>.
let
  scriptsDir = ../scripts/bin;
  entries = builtins.readDir scriptsDir;
  scriptNames = lib.filter
    (name: entries.${name} == "regular" && !(lib.hasPrefix "." name))
    (builtins.attrNames entries);
in
{
  environment.systemPackages = map
    (name: pkgs.writeShellScriptBin name (builtins.readFile (scriptsDir + "/${name}")))
    scriptNames;

  environment.etc."isame/scripts".source = scriptsDir;
}
