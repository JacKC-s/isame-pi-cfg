{ config, pkgs, lib, ... }:

# console banner - shown before login (/etc/issue, via getty.helpLine +
# a oneshot appending to /run/issue.d, since agetty can't shell out to
# git/ip itself) and after login (bash's interactiveShellInit, same
# info, re-checked live so it's always current by the time you're
# actually looking at it). branch comes from /etc/nixos's checked-out
# ref, address is the first global ipv4 nixos can find - fine for a
# single-interface box, which is the only case this needs to cover.
let
  bannerVars = ''
    branch="$(${pkgs.git}/bin/git -C /etc/nixos symbolic-ref --short -q HEAD)"
    [ -n "$branch" ] || branch="unknown"
    ip="$(${pkgs.iproute2}/bin/ip -4 -o addr show scope global | ${pkgs.gawk}/bin/awk '{print $4}' | ${pkgs.coreutils}/bin/cut -d/ -f1 | ${pkgs.coreutils}/bin/head -n1)"
    [ -n "$ip" ] || ip="no address yet"
  '';
in
{
  services.getty.helpLine = lib.mkAfter ''

    In-Space Additive Manufacturing Experience
  '';

  systemd.services.isame-issue-branch = {
    description = "write current branch + address into the pre-login banner";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    before = [ "getty.target" "getty-pre.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /run/issue.d
      ${bannerVars}
      {
        echo "Configuration: $branch"
        echo "IP address:    $ip"
        echo "https://github.com/JacKC-s/isame-pi-cfg/tree/$branch"
        echo
      } > /run/issue.d/50-isame-branch.issue
    '';
  };

  programs.bash.interactiveShellInit = ''
    ${bannerVars}
    echo
    echo "  In-Space Additive Manufacturing Experience"
    echo "  Configuration: $branch"
    echo "  IP address:    $ip"
    echo "  https://github.com/JacKC-s/isame-pi-cfg/tree/$branch"
    echo
  '';
}
