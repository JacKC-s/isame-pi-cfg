# Pi user scripts

Put runnable shell scripts directly in `scripts/bin/`. Each regular,
non-hidden file there is installed automatically on both Pi targets when the
configuration is rebuilt:

- as a command with the same filename on every user's `PATH`;
- as a read-only source file at `/etc/isame/scripts/<filename>`.

For example, adding `scripts/bin/printer-status` makes `printer-status`
available after `sudo pull-config <branch>` (or any NixOS rebuild).

Use simple command-safe filenames such as `printer-status`; a `.sh` suffix is
allowed but remains part of the command name. Files in subdirectories are not
installed, and dotfiles are ignored. Script dependencies must be supplied by
the system configuration (for example, add `curl` or `jq` to a Nix package
list when a script needs them).

The source script does not need an executable bit: Nix creates the executable
wrapper. Keep scripts in Git so a clone contains the same scripts.
