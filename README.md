This repository contains the Nix configuration files I'm using to test NixOS/nixpkgs#372743, for the sake of reproducibility and being able to share my test environment for others.

This isn't great code, it's code that's been hacked together quickly for test purposes. In particular, it does a lot of [importing from derivations][ifd], including some reasonably chunky derivations, which significantly slows down evaluation.

[ifd]: https://nix.dev/manual/nix/2.25/language/import-from-derivation
