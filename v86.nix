{
  pkgs,
  v86,
  stdenv,
  ...
}: let
  closureCompiler = pkgs.fetchurl {
    url = "https://repo1.maven.org/maven2/com/google/javascript/closure-compiler/v20210601/closure-compiler-v20210601.jar";
    hash = "sha256-ZPFhxlo9ukLJpPWnnbM1rA51f8ukhs15KCBaxMJY7wg=";
  };
in
  stdenv.mkDerivation {
    name = "v86";
    src = v86;

    nativeBuildInputs = [
      pkgs.gnumake
      pkgs.nodejs
      pkgs.python3
      pkgs.jre8
      pkgs.rustc
      pkgs.cargo
      pkgs.lld
      pkgs.llvmPackages.clang-unwrapped
    ];

    preBuild = ''
      # Provide the closure compiler to avoid wget in Makefile
      mkdir -p closure-compiler
      cp ${closureCompiler} closure-compiler/compiler.jar

      # Make sure cargo can write its lockfile by copying the source to a writable directory
      # The derivation automatically unpacks src into a writable directory, so we just need
      # to ensure cargo target directory is local
      export CARGO_HOME=$(mktemp -d)

      patchShebangs tools gen
    '';

    buildFlags = [
      "build/libv86.js"
      "build/v86.wasm"
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp build/libv86.js $out/
      cp build/v86.wasm $out/
      cp bios/seabios.bin $out/
      cp bios/vgabios.bin $out/

      runHook postInstall
    '';
  }
