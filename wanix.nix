{
  pkgs,
  wanix,
  buildGoModule,
  buildNpmPackage,
  symlinkJoin,
  ...
}: let
  wanix-wasm = buildGoModule {
    pname = "wanix-wasm";
    version = "0.3.0-dev";
    src = wanix;
    vendorHash = "sha256-byEHxnyO7rzuoogHLFGzKxdRk4/2ktvaLer0aId7hYQ=";

    preBuild = ''
      cp ${wanix-js}/wasi/worker/lib.js ./runtime/wasi/worker/lib.js
      cp ${wanix-js}/gojs/worker/lib.js ./runtime/gojs/worker/lib.js
    '';

    buildPhase = ''
      GOOS=js GOARCH=wasm go build -o $out/wanix.wasm ./runtime/wasm
    '';
  };
  wanix-js = buildNpmPackage {
    pname = "wanix-js";
    version = "0.3.0-dev";
    src = wanix + "/runtime";
    npmDepsHash = "sha256-xjxiMQRmhrHB1yCZ45PaNiXFstDngoNea2vujNeYWfs=";

    nativeBuildInputs = [
      pkgs.esbuild
    ];

    dontNpmInstall = true;

    buildPhase = ''
      esbuild index-handle.ts \
          --outfile=$out/wanix.handle.js \
          --bundle \
          --external:util \
          --format=esm \
          --minify
      esbuild index.ts \
          --outfile=$out/wanix.min.js \
          --bundle \
          --external:util \
          --loader:.go.js=text \
          --loader:.tinygo.js=text \
          --format=esm \
          --minify
      esbuild index.ts \
          --outfile=$out/wanix.js \
          --bundle \
          --external:util \
          --loader:.go.js=text \
          --loader:.tinygo.js=text \
          --format=esm
      esbuild wasi/mod.ts \
          --outfile=$out/wasi/worker/lib.js \
          --bundle \
          --external:util \
          --format=esm
      esbuild gojs/mod.ts \
          --outfile=$out/gojs/worker/lib.js \
          --bundle \
          --external:util \
          --format=esm
    '';

    installPhase = ''
      cp assets/index.html $out/index.html
      cp assets/wanix.css $out/wanix.css
    '';
  };
in
  symlinkJoin {
    name = "wanix";
    paths = [
      wanix-wasm
      wanix-js
    ];
    postBuild = "rm -rf $out/{gojs,wasi}";
  }
