{
  description = "Minimal NixOS 9p bundle for v86 (i686)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    v86 = {
      url = "github:progrium/v86/gh-pkg-docker";
      flake = false;
    };
    wanix = {
      url = "github:tractordev/wanix/c82e6264ec6c94b051adb28fdf58676b93d7f030";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    v86,
    wanix,
  }: let
  in {
    packages."i686-linux" = let
      system = "i686-linux";
      pkgs = import nixpkgs {inherit system;};
    in {
      kernel = pkgs.linuxPackages_6_12.kernel.override {
        ignoreConfigErrors = true;
        extraConfig = ''
          NET_9P y
          NET_9P_VIRTIO y
          9P_FS y
          VIRTIO_NET y
          VIRTIO_BLK y
          VIRTIO_CONSOLE y
          VIRTIO_PCI y
          VIRTIO_PCI_LIB y
          PACKET y
          UNIX y
        '';
      };
      rootenv = pkgs.buildEnv {
        name = "root-env";
        paths = with pkgs; [
          busybox
        ];
        pathsToLink = ["/bin" "/etc" "/lib" "/proc" "/sys" "/dev" "/root" "/tmp" "/var" "/var/log" "/var/run"];
      };
      rootfs = let
        rootenv = self.packages."i686-linux".rootenv;
      in
        pkgs.runCommand "rootfs" {
          closureInfo = pkgs.closureInfo {rootPaths = [rootenv];};
        } ''
          mkdir -p $out/{bin,etc,lib,proc,sys,dev,root}
          cp -r ${rootenv}/* $out/

          # Basic etc
          echo "root:x:0:0::/root:/bin/sh" > $out/etc/passwd
          echo "root:x:0:" > $out/etc/group
          echo "proc /proc proc defaults 0 0" > $out/etc/fstab

          mkdir -p $out/etc/init.d
          cp ${./init.sh} $out/etc/init.d/rcS
          chmod +x $out/etc/init.d/rcS

          mkdir -p $out/nix/store
          while read path; do
            cp -a $path $out/nix/store/$(basename $path)
          done < $closureInfo/store-paths
        '';
    };
    packages."x86_64-linux" = let
      system = "x86_64-linux";
      pkgs = import nixpkgs {inherit system;};
    in {
      v86 = pkgs.callPackage ./v86.nix {inherit v86;};
      wanix = pkgs.callPackage ./wanix.nix {inherit wanix;};
      bundle_unzipped = pkgs.runCommand "bundle_unzipped" {} ''
        mkdir -p $out/{kernel,rootfs,v86}
        cp ${self.packages."i686-linux".kernel}/bzImage $out/kernel/
        cp -r ${self.packages."i686-linux".rootfs}/* $out/rootfs/
        cp -r ${self.packages.${system}.v86}/* $out/v86/
        cp ${./init.js} $out/init.js
      '';
      bundle = pkgs.runCommand "bundle" {} ''
        mkdir -p $out
        tar -czf $out/bundle.tar.gz -C ${self.packages.${system}.bundle_unzipped} .
      '';
    };
  };
}
