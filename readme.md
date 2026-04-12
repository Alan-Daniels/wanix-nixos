nix build .#bundle && wanix serve --bundle bundle.tar.gz $(readlink result)
