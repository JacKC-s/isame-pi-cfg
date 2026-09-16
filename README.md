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

## Building without a VM

None of this actually needs NixOS - a NixOS VM is just what we happened
to build the first images on. Plain Nix on any real Linux (including
WSL) builds the `rpi4`/`rpi5` targets directly, given two things: Nix
itself, and aarch64 emulation so an x86_64 machine can cross-build for
the Pi. Windows itself can't run Nix at all (no POSIX layer for it to
sit on), so on Windows this means WSL specifically, not the raw host.

One-time setup on Ubuntu/Debian-based WSL or Linux:

```bash
sudo apt install -y qemu-user-binfmt
mkdir -p ~/.config/nix
echo 'extra-platforms = aarch64-linux' >> ~/.config/nix/nix.conf
```

(`qemu-user-binfmt` registers the aarch64 interpreter with the kernel;
the `nix.conf` line is what actually tells Nix it's allowed to build
that platform locally. User-level config on purpose - no need to touch
`/etc/nix/nix.conf` or run anything else as root.)

Then generate a bootstrap key at `$HOME/secrets/bootstrap-age-key.txt`
(see "First-time setup" under pi4-software below) and build same as
anywhere else:

```bash
nix build --impure .#nixosConfigurations.rpi4.config.system.build.sdImage
```

Other distros: swap `qemu-user-binfmt` for whatever package provides
`binfmt_misc` registration for `qemu-aarch64` (e.g. `qemu-user-static` on
distros where that's still the real package name, not a virtual one).

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

### First-time setup

You need your own bootstrap key - the one any existing image was built
with only exists on the machine that built it, never in this repo. Goes
at `$HOME/secrets/bootstrap-age-key.txt` (works whether that's `/root` on
a VM or a regular user's home on WSL/Linux - see "Building without a VM"
below):

```bash
mkdir -p ~/secrets
nix-shell -p age --run 'age-keygen -o ~/secrets/bootstrap-age-key.txt'
```

Do this *after* `nixos-install` + reboot, not from the live ISO - the
ISO's filesystem is RAM only, the key's gone the second you reboot into
the real system. (Found out by actually testing this on a second VM from
scratch.) Then swap `bootstrap` in `hosts/secrets/secrets.nix` for the
pubkey it printed, and roll the secret (below) to generate the actual
encrypted file.

### Rotating the secret

Run this **yourself, in your own terminal** - not by asking an AI
assistant to run it for you, even this repo's own. Anything typed
through an automated tool call ends up in that tool's conversation
history, which defeats the entire point of rotating a secret. One
command, on whatever machine holds
`$HOME/secrets/bootstrap-age-key.txt` (a pi, the build vm, or your own
WSL/Linux machine):

```bash
nix-shell -p age mkpasswd --run '
  age_pub=$(grep "public key" ~/secrets/bootstrap-age-key.txt | cut -d" " -f4)
  mkpasswd -m sha-512 | age -r "$age_pub" -o hosts/secrets/pi4-software-password.age
'
```

`mkpasswd -m sha-512` with no password argument prompts for one with
hidden input, same as `passwd` - nothing typed here ever touches a
command line, shell history, or a log. Then `save-config` as usual to
commit and push it.

Rotate whenever the password's been typed anywhere it shouldn't have
been (shell history, a screen someone saw, a chat with anyone, human or
otherwise) - or just on a normal schedule. Old commits keep the old
encrypted secret in history, but without the private half of whichever
bootstrap key it was encrypted against, that ciphertext is useless to
anyone who doesn't already have it.

Once a pi's booted for real you can rekey against its actual ssh host key
instead of the bootstrap one (`ssh-to-age` it, add as a recipient,
re-encrypt) - not required, just tighter.

## status

Nothing flashed to real hardware yet, `rpi4`/`rpi5` are only VM-tested
(including a full from-scratch repro run on a second VM - installer,
fresh secrets, cold build, all of it). No mcu attached, so klipper sits
disconnected; moonraker/mainsail don't care and come up fine anyway.
