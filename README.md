# isame-pi-cfg

NixOS config for the ISAME (In-Space Additive Manufacturing Experience)
printer stack - Klipper + Moonraker + Mainsail on a Pi 4/5. Basically
MainsailOS but declarative, so config changes are a git commit instead
of ssh-and-edit.

## Layout

```
flake.nix                  buildhost / pi4 / pi5 configs
hosts/
  buildhost/                the x86_64 dev vm, not a printer
  common.nix                 shared pi4+pi5 stuff
  pi4.nix / pi5.nix          board-specific + hostname
modules/
  printer-stack.nix          klipper/moonraker/mainsail
  motd.nix                   console banner (branch + ip)
  packages.nix                installs packages.txt
  user-scripts.nix           installs scripts/bin/*
  deploy.nix                  pull-config / save-config
secrets/                     agenix, see docs/SECRETS.md
scripts/bin/                 see scripts/README.md
docs/
  BUILDING.md                 building, flashing, updating, saving back
  SECRETS.md                   bootstrap key + rotating the password
```

See [docs/BUILDING.md](docs/BUILDING.md) to build, flash, or push an
update to a running board, and [docs/SECRETS.md](docs/SECRETS.md) for
the bootstrap key / password rotation side of things.

## Console banner

Every board shows a banner both before login (`/etc/issue`) and after
(the shell prompt), with the current branch, the box's IP, and a link
back to that branch on GitHub:

```
In-Space Additive Manufacturing Experience
Configuration: main
IP address:    192.168.1.42
https://github.com/JacKC-s/isame-pi-cfg/tree/main
```

`modules/motd.nix` has the details.

## User scripts

Put shell scripts in `scripts/bin/`. Every regular, non-hidden file in
that directory becomes a command of the same name on both board images
after a rebuild, and is also available read-only at
`/etc/isame/scripts/<name>`. See [`scripts/README.md`](scripts/README.md)
for naming and dependency details. Because the directory is
version-controlled, cloning this repository retrieves the scripts too.

## status

Running on a real Pi 4 as of the `motd-ip-and-build-docs` /
`redo-v2` work - moonraker/mainsail come up clean, klipper sits
disconnected until an MCU is actually plugged in and its serial path is
filled into the printer config, which is expected with no board wired
up yet. `pi5` config is written but not hardware-tested.

## Changed in this reorganization

Worth knowing if you touched the old layout:

- `hosts/rpi4.nix` / `rpi5.nix` -> `hosts/pi4.nix` / `pi5.nix`, and the
  matching flake outputs renamed `rpi4`/`rpi5` -> `pi4`/`pi5`. Update
  any `--flake .#rpi4` you had lying around.
- `hosts/common-pi.nix` -> `hosts/common.nix`.
- `modules/mainsail-stack.nix` -> `modules/printer-stack.nix`.
- `hosts/secrets/` -> `secrets/` (repo root).
- `hosts/local-packages.{nix,txt}` -> `modules/packages.nix` +
  `packages.txt` (repo root). `save-config` no longer auto-scrapes
  `nix profile install`ed packages into that file - add names to
  `packages.txt` yourself when you want something kept, which is more
  predictable than a script guessing at it.
- The console banner and `pull-config`/`save-config` scripts moved out
  of `hosts/common-pi.nix` into their own modules
  (`modules/motd.nix`, `modules/deploy.nix`).
- Boards renamed `mainsail-rpi4`/`mainsail-rpi5` -> `isame-pi4`/`isame-pi5`,
  dev vm `mainsail-buildhost` -> `isame-buildhost`.
- The dev vm no longer commits a plaintext root password
  (`initialPassword`) - set one yourself with `passwd` after first
  boot.
