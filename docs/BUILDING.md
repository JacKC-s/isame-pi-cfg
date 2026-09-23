# Building

```bash
nix build .#nixosConfigurations.buildhost.config.system.build.toplevel
nix build --impure .#nixosConfigurations.pi4.config.system.build.sdImage
```

`--impure` is for the secrets stuff, see [SECRETS.md](SECRETS.md) - not
optional for the board targets.

## Without a VM

None of this actually needs NixOS - a NixOS VM is just what the first
images got built on. Plain Nix on any real Linux (including WSL) builds
the `pi4`/`pi5` targets directly, given two things: Nix itself, and
aarch64 emulation so an x86_64 machine can cross-build for the board.
Windows itself can't run Nix at all (no POSIX layer for it to sit on),
so on Windows this means WSL specifically, not the raw host.

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

If the daemon logs back `ignoring the client-specified setting
'extra-platforms', because it is a restricted setting and you are not
a trusted user` the first time you build, your user isn't in the
daemon's trusted list, so the per-user `nix.conf` line above gets
silently dropped. Either put `extra-platforms` in `/etc/nix/nix.conf`
instead (system-wide, always trusted) or add yourself:

```bash
echo "trusted-users = root $(whoami)" | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

Then generate a bootstrap key (see [SECRETS.md](SECRETS.md)) and build
same as anywhere else:

```bash
nix build --impure .#nixosConfigurations.pi4.config.system.build.sdImage
```

Other distros: swap `qemu-user-binfmt` for whatever package provides
`binfmt_misc` registration for `qemu-aarch64` (e.g. `qemu-user-static`
on distros where that's still the real package name, not a virtual
one).

## Flashing

`result/sd-image/nixos-image-sd-card-*.img` -> Raspberry Pi Imager,
"Use custom". Uncompressed on purpose (`sdImage.compressImage =
false`), makes iterating faster.

## Updating a board that's already running

On the board itself:

```bash
sudo pull-config          # pulls main
sudo pull-config my-branch # pulls a specific branch instead
```

That's `nixos-rebuild switch --flake github:JacKC-s/isame-pi-cfg/<branch>#pi4`
wrapped up (see `modules/deploy.nix`) - native build, on the board, no
vm needed. Useful for testing a `save-config` branch there before
merging it. Native aarch64 build on the board itself is slow if it's a
Pi 4 with 1-2GB of RAM - budget real time for it, or use the
build-elsewhere path below instead.

Or build somewhere else (the vm, WSL, whatever's running this repo)
and push the result to the board over ssh, if you'd rather not build
on the board itself - this is the normal way to do it day to day,
honestly, since the board's slow and usually busy running the actual
printer stack:

```bash
nixos-rebuild switch --flake .#pi4 --target-host root@<board-ip>
```

`--target-host` alone builds locally (cross/emulated, same as `nix
build` above) and only copies the finished closure to `<board-ip>` to
activate it. The board does no evaluating and no compiling, just
unpacks what it's handed and switches - which is the whole point,
since evaluating on a memory-constrained board is what makes it choke
and freeze in the first place.

Don't add `--build-host localhost` on top of that expecting it to mean
"build on this machine" - it doesn't. `--build-host` always means "ssh
to this host and build there," even when the host is `localhost`, so
it'll try to ssh into your own box and fail with `connect to host
localhost port 22: Connection refused` unless you happen to be running
an sshd on the machine you're already sitting at. Leave it out entirely
when the build machine and the machine you're typing on are the same
one - that's the default, no flag needed.

Test before committing to it, same idea as anywhere else in NixOS -
`nixos-rebuild test --target-host root@<board-ip>` activates without
touching the boot default, so a bad config just needs a reboot to go
back to whatever was already there. Swap in `switch` once it looks
right.

Don't actually need a pre-built image to get started from scratch,
either - flash literally any generic NixOS aarch64 sd image, boot it
with network, run
`sudo nixos-rebuild switch --flake github:JacKC-s/isame-pi-cfg#pi4` on
it. Builds the whole stack natively on the board, no qemu involved,
just slow for the reason above.

## Saving changes back

If you end up tweaking `/etc/nixos` directly on a board and want it in
the repo without going through the vm:

```bash
sudo save-config
```

Asks for a name, commits everything under it, pushes as a branch (not
straight to main - review/merge it yourself when you're happy with
it). First run has nothing to push to yet, since the board's never had
write access - it'll generate a deploy key and print out exactly what
to add and where:

```
https://github.com/JacKC-s/isame-pi-cfg/settings/keys
```

Add it there with write access, rerun `save-config`. Key's scoped to
this repo only, nothing else on the account.
