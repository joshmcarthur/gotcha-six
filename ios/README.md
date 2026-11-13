# Gotcha Six iOS

Native SwiftUI companion (slices 4+). The radar parser and alert gate live in
Rust (`gotcha-six-core`); the app links that library and calls it through
UniFFI-generated Swift. **Do not reimplement `$DFDMD` parsing in Swift.**

Generated bindings are **not** checked in. Produce them at build time (or via
the script below) and link the Rust `staticlib`.

## One-time: generate bindings (dev / CI smoke)

UniFFI 0.29 has no crates.io CLI binary. Use the repo’s `uniffi-bindgen` bin:

```bash
./ios/generate-bindings.sh
```

That builds `gotcha-six-core` with `--features uniffi` and writes Swift + FFI
headers into `ios/GotchaSixCore/Generated/` (gitignored).

Smoke-check the surface:

```bash
rg 'UniffiRadarEngine|UniffiAlertGate|EngineOutput|radarPresetCommands' ios/GotchaSixCore/Generated/
```

Do not enable `wasm` and `uniffi` in the same build.

## What Xcode should link (slice 4)

1. **Rust static library** for the active Apple target, e.g.

   ```bash
   rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
   cargo build -p gotcha-six-core --features uniffi --release --target aarch64-apple-ios-sim
   # → target/aarch64-apple-ios-sim/release/libgotcha_six_core.a
   ```

2. **Generated Swift** from `./ios/generate-bindings.sh` (or the same steps in
   an Xcode run script phase that also maps `PLATFORM_NAME` → the right
   `--target`).

3. Wire `gotcha_six_coreFFI.modulemap` / header so Swift can import the FFI
   module, and link `libgotcha_six_core.a` plus system libs UniFFI needs
   (`libffi` is not required for UniFFI’s Rust side; usually just the staticlib
   + Swift stdlib).

Slice 4 owns the `.xcodeproj` and the exact build-phase script.

## Signing

Placeholder bundle id: `nz.mcarthur.GotchaSix` (team prefix later in Xcode).
