# Moonraker IP Whitelist

`moonraker-whitelist` is a small terminal UI for adding an IPv4 address to
Moonraker's `trusted_clients` list.

## Run it

From this directory:

```bash
./moonraker-whitelist
```

The script requests administrator authentication when needed.

## What it does

1. Shows the currently trusted Moonraker clients.
2. Prompts for one IPv4 address and validates its format.
3. Confirms the requested change.
4. Saves a timestamped backup next to `moonraker.conf`.
5. Adds the address only if it is not already listed.
6. Restarts `moonraker.service` so the change takes effect.

Moonraker's configuration file is:

```text
/home/pi4-software/printer_data/config/moonraker.conf
```

Backups are named like `moonraker.conf.bak.YYYYMMDD-HHMMSS` in that same
directory. Enter a blank address, or answer anything other than `y` at the
confirmation prompt, to leave the configuration unchanged.
