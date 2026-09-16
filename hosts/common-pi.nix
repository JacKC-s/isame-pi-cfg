{ config, pkgs, lib, ... }:

# shared by rpi4 + rpi5, board stuff lives in nixos-hardware modules,
# printer stack is in mainsail-stack.nix
{
  imports = [ ./local-packages.nix ];

  hardware.enableRedistributableFirmware = true;

  networking.networkmanager.enable = true;
  networking.hostName = "mainsail-pi";

  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # console banner, shown at every boot before login, same place as the
  # "Welcome to NixOS" line (/etc/issue). the static bit lives here...
  services.getty.helpLine = lib.mkAfter ''

    In-Space Additive Manufacturing Experience
  '';

  # ...and the dynamic bit (branch, since agetty can't shell out to git
  # itself) gets written to /run/issue.d at boot instead - agetty's
  # issue-file search path already includes that dir and concatenates it
  # after /etc/issue, so this just shows up appended to the banner above
  systemd.services.isame-issue-branch = {
    description = "write current branch into the pre-login banner";
    wantedBy = [ "multi-user.target" ];
    before = [ "getty.target" "getty-pre.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /run/issue.d
      branch="$(${pkgs.git}/bin/git -C /etc/nixos symbolic-ref --short -q HEAD)"
      [ -n "$branch" ] || branch="unknown"
      {
        echo "Configuration: $branch"
        echo "https://github.com/JacKC-s/isame-pi-cfg/tree/$branch"
        echo
      } > /run/issue.d/50-isame-branch.issue
    '';
  };

  # this one's live too - shell startup, same branch check, shown again
  # once you're actually logged in
  programs.bash.interactiveShellInit = ''
    branch="$(${pkgs.git}/bin/git -C /etc/nixos symbolic-ref --short -q HEAD)"
    [ -n "$branch" ] || branch="unknown"
    echo
    echo "  In-Space Additive Manufacturing Experience"
    echo "  Configuration: $branch"
    echo "  https://github.com/JacKC-s/isame-pi-cfg/tree/$branch"
    echo
  '';

  # decrypt key baked into the image (path here, key itself is not in
  # the repo - lives at /root/secrets/bootstrap-age-key.txt on whatever
  # builds this). works from first boot, no ssh-host-key timing issue.
  # can rekey against a Pi's real host key later, not required though.
  environment.etc."age/bootstrap-key.txt" = {
    source = /root/secrets/bootstrap-age-key.txt;
    mode = "0400";
  };
  age.identityPaths = [ "/etc/age/bootstrap-key.txt" ];
  age.secrets.pi4-software-password.file = ./secrets/pi4-software-password.age;

  users.users.pi4-software = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dialout" "video" ];
    hashedPasswordFile = config.age.secrets.pi4-software-password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUxpJ0Htx3neSCBMFJxv2iJNPu7s5GFKRJAqRwRDzvE pi4-software@isame-pi-cfg-bootstrap"
    ];
  };

  # sudo save-config - commit+push /etc/nixos to a new branch, named
  # interactively. generates its own deploy key on first run and tells
  # you where to add it on github (write-scoped to this repo only).
  environment.systemPackages = [
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

      # sweep in anything installed via `nix profile install` since last time
      ${pkgs.nix}/bin/nix profile list --json --extra-experimental-features 'nix-command flakes' 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.elements[].attrPath | sub("^(legacyPackages|packages)\\.[^.]+\\."; "")' \
        >> hosts/local-packages.txt
      sort -u -o hosts/local-packages.txt hosts/local-packages.txt

      read -p "snapshot name: " name
      [ -n "$name" ] || { echo "need a name"; exit 1; }

      git add -A
      git checkout -b "$name" 2>/dev/null || git checkout "$name"
      git commit -m "$name" || echo "nothing changed, pushing anyway"
      GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes" git push -u origin "$name"
    '')
  ];

  sdImage.compressImage = false;

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
