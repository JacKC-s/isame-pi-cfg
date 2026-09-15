{ config, pkgs, lib, ... }:

# klipper + moonraker + mainsail, shared by rpi4/rpi5
{
  services.klipper = {
    enable = true;
    # no mcu attached yet - klippy stays "not connected" until this
    # points at a real /dev/serial/by-id/... and gets redeployed
    settings = {
      mcu = {
        serial = "/dev/serial/by-id/CHANGE_ME_no_mcu_attached";
      };
      printer = {
        kinematics = "cartesian";
        max_velocity = 300;
        max_accel = 3000;
        max_z_velocity = 5;
        max_z_accel = 100;
      };
    };
  };

  services.moonraker = {
    enable = true;
    settings = {
      authorization = {
        # whole LAN for now, tighten before this leaves a trusted network
        trusted_clients = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];
      };
    };
  };

  services.mainsail.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 7125 ];
}
