# pull-config / save-config - the two ends of "config changes are a
# git commit instead of ssh-and-edit". board is baked in per-host since
# the flake output name is fixed per board (pi4/pi5), not something
# worth detecting at runtime. usage: import this with the board name,
# e.g. `(import ../modules/deploy.nix { board = "pi4"; })`.
{ board }:
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
    # sudo pull-config [branch] - grabs a branch from github (main if
    # none given) and rebuilds in place. handy for testing a
    # save-config branch on the board before merging it.
    (pkgs.writeShellScriptBin "pull-config" ''
      set -e
      branch="''${1:-main}"
      exec nixos-rebuild switch --flake "github:JacKC-s/isame-pi-cfg/$branch#${board}" "''${@:2}"
    '')

    # sudo save-config - commit+push /etc/nixos to a new branch, named
    # interactively. generates its own deploy key on first run and
    # tells you where to add it on github (write-scoped to this repo
    # only, nothing else on the account).
    (pkgs.writeShellScriptBin "save-config" ''
      set -e
      cd /etc/nixos
      key=/root/.ssh/isame-pi-cfg-deploy

      if [ ! -f "$key" ]; then
        echo "no deploy key yet, generating one"
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -C "$(hostname)-deploy" -f "$key"
        echo
        echo "add this as a deploy key (with write access) at:"
        echo "  https://github.com/JacKC-s/isame-pi-cfg/settings/keys"
        echo
        cat "$key.pub"
        echo
        echo "then run save-config again"
        exit 1
      fi

      git remote get-url origin >/dev/null 2>&1 || \
        git remote add origin git@github.com:JacKC-s/isame-pi-cfg.git

      read -p "snapshot name: " name
      [ -n "$name" ] || { echo "need a name"; exit 1; }

      git add -A
      git checkout -b "$name" 2>/dev/null || git checkout "$name"
      git commit -m "$name" || echo "nothing changed, pushing anyway"
      GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes" git push -u origin "$name"
    '')
  ];
}
