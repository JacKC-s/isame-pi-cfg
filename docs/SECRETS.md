# Secrets

The only secret in this repo right now is `pi4-software`'s login
password, encrypted with [agenix](https://github.com/ryantm/agenix)
(`secrets/pi4-software-password.age`) instead of committed in the
clear. `pi4-software` is the default account - home dir is where
klipper/moonraker expect their data (`/home/pi4-software/printer_data`).

## First-time setup

You need your own bootstrap key - the one any existing image was built
with only exists on the machine that built it, never in this repo.
Goes at `$HOME/secrets/bootstrap-age-key.txt` (works whether that's
`/root` on a VM or a regular user's home on WSL/Linux - see
[BUILDING.md](BUILDING.md)):

```bash
mkdir -p ~/secrets
nix-shell -p age --run 'age-keygen -o ~/secrets/bootstrap-age-key.txt'
```

Do this *after* `nixos-install` + reboot, not from the live ISO - the
ISO's filesystem is RAM only, the key's gone the second you reboot into
the real system. Then swap `bootstrap` in `secrets/secrets.nix` for the
pubkey it printed, and roll the secret (below) to generate the actual
encrypted file.

## Rotating the secret

Run this **yourself, in your own terminal** - not by asking an AI
assistant to run it for you, even this repo's own. Anything typed
through an automated tool call ends up in that tool's conversation
history, which defeats the entire point of rotating a secret. One
command, on whatever machine holds
`$HOME/secrets/bootstrap-age-key.txt` (a board, the build vm, or your
own WSL/Linux machine):

```bash
nix-shell -p age mkpasswd --run '
  age_pub=$(grep "public key" ~/secrets/bootstrap-age-key.txt | cut -d" " -f4)
  mkpasswd -m sha-512 | age -r "$age_pub" -o secrets/pi4-software-password.age
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

Once a board's booted for real you can rekey against its actual ssh
host key instead of the bootstrap one (`ssh-to-age` it, add as a
recipient, re-encrypt) - not required, just tighter.
