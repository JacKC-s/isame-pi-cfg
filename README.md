# isame-pi-cfg

NixOS config for the printer stack - Klipper + Moonraker + Mainsail on a
Pi 4/5. Basically MainsailOS but declarative, so config changes are a git
commit instead of ssh-and-edit.

## Layout

```
flake.nix                 buildhost / rpi4 / rpi5 configs
hosts/
  buildhost/               the x86_64 dev vm, not a printer
  common-pi.nix             shared rpi4+rpi5 stuff
  rpi4.nix / rpi5.nix       board-specific + hostname
  secrets/                  agenix, see below
modules/
  mainsail-stack.nix        klipper/moonraker/mainsail
```

## Building

```bash
nix build .#nixosConfigurations.buildhost.config.system.build.toplevel
nix build --impure .#nixosConfigurations.rpi4.config.system.build.sdImage
```

`--impure` is for the secrets stuff below, not optional for the pi targets.

## Flashing

`result/sd-image/nixos-image-sd-card-*.img` -> Raspberry Pi Imager,
"Use custom". Uncompressed on purpose (`sdImage.compressImage = false`),
makes iterating faster.

## Updating

On the pi itself, once it's running:

```bash
sudo pull-config          # pulls main
sudo pull-config my-branch # pulls a specific branch instead
```

That's `nixos-rebuild switch --flake github:JacKC-s/isame-pi-cfg/<branch>#rpi4`
wrapped up (see `hosts/rpi4.nix`) - native build, on the pi, no vm needed.
Useful for testing a `save-config` branch on the pi before merging it.

Or build on the vm and push the result to the pi over ssh instead, if
you'd rather not build on the pi itself (e.g. building from local
uncommitted changes, or the pi's slow/busy):

```bash
nixos-rebuild switch --flake .#rpi4 --target-host root@<pi-ip> --build-host localhost
```

`--build-host localhost` means "build here, activate over there" - the vm
does the compiling (cross/emulated, same as `nix build` above), then pushes
the result to the pi's `<pi-ip>` and switches it in, all in one command.

Don't actually need a pre-built image from here to get started, either -
flash literally any generic NixOS aarch64 sd image, boot it with network,
run `sudo nixos-rebuild switch --flake github:JacKC-s/isame-pi-cfg#rpi4`
on it. Builds the whole stack natively on the pi, no qemu involved.

## Saving changes back

If you end up tweaking `/etc/nixos` directly on a pi and want it in the
repo without going through the vm:

```bash
sudo save-config
```

Asks for a name, commits everything under it, pushes as a branch (not
straight to main - review/merge it yourself when you're happy with it).
First run has nothing to push to yet, since the pi's never had write
access - it'll generate a deploy key and print out exactly what to add
and where:

```
https://github.com/JacKC-s/isame-pi-cfg/settings/keys
```

Add it there with write access, rerun `save-config`. Key's scoped to
this repo only, nothing else on the account.

## User scripts

Put shell scripts in `scripts/bin/`. Every regular, non-hidden file in that
directory becomes a command of the same name on both Pi images after a rebuild
and is also available read-only at `/etc/isame/scripts/<name>`. See
[`scripts/README.md`](scripts/README.md) for naming and dependency details.
Because the directory is version-controlled, cloning this repository retrieves
the scripts too.

## pi4-software

Default account, home dir is where klipper/moonraker expect their data
(`/home/pi4-software/printer_data`). Password lives encrypted
(`hosts/secrets/pi4-software-password.age`, agenix) instead of committed
in the clear.

Building this yourself needs your own key + secret:

```bash
nix-shell -p age mkpasswd --run '
  age-keygen -o /root/secrets/bootstrap-age-key.txt
  mkpasswd -m sha-512 "<password>" | \
    age -r "<pubkey from above>" -o hosts/secrets/pi4-software-password.age
'
```

then swap `bootstrap` in `hosts/secrets/secrets.nix` for the new pubkey.

Do this *after* `nixos-install` + reboot, not from the live ISO - the ISO's
filesystem is RAM only, the key's gone the second you reboot into the real
system. (Found out by actually testing this on a second VM from scratch.)

Once a pi's booted for real you can rekey against its actual ssh host key
instead of the bootstrap one (`ssh-to-age` it, add as a recipient,
re-encrypt) - not required, just tighter.

## status

Nothing flashed to real hardware yet, `rpi4`/`rpi5` are only VM-tested
(including a full from-scratch repro run on a second VM - installer,
fresh secrets, cold build, all of it). No mcu attached, so klipper sits
disconnected; moonraker/mainsail don't care and come up fine anyway.
