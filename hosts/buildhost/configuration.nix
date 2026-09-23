{ config, pkgs, lib, ... }:

# just the dev vm, printer stack is elsewhere (hosts/pi4.nix / pi5.nix)
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/motd.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  # aarch64 builds eat ram, only 3.8G here
  swapDevices = [ { device = "/swapfile"; size = 4096; } ];

  # so this can cross-build the pi configs under qemu
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "isame-buildhost";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # no password committed here - this used to be a plaintext
  # `initialPassword` baked into the repo, which is exactly the kind of
  # thing this whole agenix setup exists to avoid doing. set one
  # yourself after first boot, in your own terminal: `passwd`
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "26.05";
}
