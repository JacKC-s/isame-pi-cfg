let
  # private half of this lives on the build machine, not here
  bootstrap = "age1gztpwr5jgx4hvm2mkuss85ml7d288vuj3ckwydk3gdqs677yz36svz9th0";

  # rpi4Host = "age1..."; # once a pi's actually booted, add its host key
in
{
  "pi4-software-password.age".publicKeys = [ bootstrap ];
}
