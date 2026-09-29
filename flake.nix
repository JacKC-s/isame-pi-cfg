{
  description = "isame printer config - klipper/moonraker/mainsail on nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, agenix, ... }:
    let
      # what shows up in the boot menu / `nixos-rebuild list-generations`
      # for each board, instead of the meaningless default (a generation
      # number plus a raw nixpkgs commit hash). self.shortRev is the repo's
      # own commit, set by nix from git itself - no runtime script needed,
      # this one's knowable at build time, unlike the motd's branch/ip.
      # falls back to "dirty" when building from an uncommitted tree,
      # since shortRev doesn't exist for one (nothing to hash yet).
      label = board: "isame-${board}-${self.shortRev or "dirty"}";
    in
    {
      nixosConfigurations = {
        # dev/build box, not a printer
        buildhost = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/buildhost/hardware-configuration.nix
            ./hosts/buildhost/configuration.nix
            { system.nixos.label = label "buildhost"; }
          ];
        };

        pi4 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-4
            agenix.nixosModules.default
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel.nix"
            ./hosts/pi4.nix
            { system.nixos.label = label "pi4"; }
          ];
        };

        pi5 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-5
            agenix.nixosModules.default
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel.nix"
            ./hosts/pi5.nix
            { system.nixos.label = label "pi5"; }
          ];
        };
      };
    };
}
