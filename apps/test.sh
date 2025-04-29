#!/bin/bash
nix build .#nixosConfigurations.dev-microvm.config.microvm.declaredRunner
./result/bin/microvm-run
