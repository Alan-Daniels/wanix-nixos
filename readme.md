# To build the bundle
```
nix build .#bundle
```

# To build frontend dependencies
```
nix build .#wanix
```

# To build everything together
```
nix build .#test_serve
pushd ./result
php -S localhost:8000 # or any static host you'd prefer
popd
```
and navigate to http://localhost:8000/?bundle=bundle.tar.gz&network=none
