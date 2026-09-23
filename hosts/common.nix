{ config, pkgs, lib, ... }:

# shared by pi4 + pi5, board stuff lives in nixos-hardware modules,
# printer stack is in modules/printer-stack.nix
{
  imports = [
    ../modules/packages.nix
    ../modules/user-scripts.nix
    ../modules/motd.nix
  ];

  hardware.enableRedistributableFirmware = true;

  networking.networkmanager.enable = true;

  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # decrypt key baked into the image (path here, key itself is not in
  # the repo - lives at $HOME/secrets/bootstrap-age-key.txt on whatever
  # builds this, so it works whether that's root on a vm or a regular
  # user on wsl/linux). works from first boot, no ssh-host-key timing
  # issue. can rekey against a board's real host key later, not
  # required. see docs/SECRETS.md for the whole story.
  environment.etc."age/bootstrap-key.txt" = {
    source = builtins.toPath (builtins.getEnv "HOME" + "/secrets/bootstrap-age-key.txt");
    mode = "0400";
  };
  age.identityPaths = [ "/etc/age/bootstrap-key.txt" ];
  age.secrets.pi4-software-password.file = ../secrets/pi4-software-password.age;

  users.users.pi4-software = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dialout" "video" ];
    hashedPasswordFile = config.age.secrets.pi4-software-password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUxpJ0Htx3neSCBMFJxv2iJNPu7s5GFKRJAqRwRDzvE pi4-software@isame-pi-cfg-bootstrap"
    ];
  };

  # no zfs filesystems here, but the sd-image installer module pulls in
  # a zfs option whose true default prints a warning on every eval
  # regardless - silence it rather than leave it dangling
  boot.zfs.forceImportRoot = false;

  sdImage.compressImage = false;

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
