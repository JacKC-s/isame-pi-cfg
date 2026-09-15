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

  outputs = { self, nixpkgs, nixos-hardware, agenix, ... }: {
    nixosConfigurations = {
      # dev/build box, not a printer
      buildhost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/buildhost/hardware-configuration.nix
          ./hosts/buildhost/configuration.nix
        ];
      };

      rpi4 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          agenix.nixosModules.default
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel.nix"
          ./modules/mainsail-stack.nix
          ./hosts/rpi4.nix
        ];
      };

      rpi5 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-5
          agenix.nixosModules.default
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel.nix"
          ./modules/mainsail-stack.nix
          ./hosts/rpi5.nix
        ];
      };
    };
  };
}
