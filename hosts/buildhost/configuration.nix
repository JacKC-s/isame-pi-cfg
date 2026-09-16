{ config, pkgs, lib, ... }:

# just the dev vm, printer stack is elsewhere (rpi4.nix / rpi5.nix)
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  # aarch64 builds eat ram, only 3.8G here
  swapDevices = [ { device = "/swapfile"; size = 4096; } ];

  # so this can cross-build the pi configs under qemu
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "mainsail-buildhost";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  users.users.root.initialPassword = "diddy123";

  # same banners as the pi targets, mostly here so they're actually
  # visible somewhere without real hardware - this vm just builds,
  # never boots rpi4/rpi5 itself
  services.getty.helpLine = lib.mkAfter ''

    In-Space Additive Manufacturing Experience
  '';

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

  programs.bash.interactiveShellInit = ''
    branch="$(${pkgs.git}/bin/git -C /etc/nixos symbolic-ref --short -q HEAD)"
    [ -n "$branch" ] || branch="unknown"
    echo
    echo "  In-Space Additive Manufacturing Experience"
    echo "  Configuration: $branch"
    echo "  https://github.com/JacKC-s/isame-pi-cfg/tree/$branch"
    echo
  '';

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "26.05";
}
