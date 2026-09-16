let
  # team-shared key, not tied to one person's machine. private half is
  # NOT here - distributed to the team directly, each person saves it at
  # $HOME/secrets/bootstrap-age-key.txt on whatever they build/rotate from
  bootstrap = "age1m7jq9uw72sfguudyv2j6nhytlamts87lhs305sqfzgeycfxwt3xsatecar";

  # rpi4Host = "age1..."; # once a pi's actually booted, add its host key
in
{
  "pi4-software-password.age".publicKeys = [ bootstrap ];
}
