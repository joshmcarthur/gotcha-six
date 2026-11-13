# Gotcha Six iOS

Native SwiftUI companion (slices 4+) plus checked-in UniFFI Swift bindings under `GotchaSixCore/`.

Linux CI can **generate** these Swift files. Linking and running the app needs a Mac with Xcode.

## Generate Swift bindings

UniFFI 0.29 does not ship a crates.io binary. This repo exposes a thin `uniffi-bindgen` bin behind `--features uniffi-cli` (pinned to the same `uniffi` 0.29.x as `core`).

From the repo root:

```bash
cargo build -p gotcha-six-core --features uniffi --release

# Linux
cargo run -p gotcha-six-core --features uniffi-cli --bin uniffi-bindgen -- \
  generate --library target/release/libgotcha_six_core.so \
  --language swift --out-dir ios/GotchaSixCore

# macOS (host dylib)
cargo run -p gotcha-six-core --features uniffi-cli --bin uniffi-bindgen -- \
  generate --library target/release/libgotcha_six_core.dylib \
  --language swift --out-dir ios/GotchaSixCore
```

Re-run generate after changing `core/src/uniffi_api.rs` (or any `#[uniffi::export]` surface). Commit the updated files under `GotchaSixCore/` — do not gitignore them.

Do not enable `wasm` and `uniffi` in the same build.

## Apple rustup targets (Mac, for linking later)

Needed when the Xcode project (slice 4) builds the Rust cdylib for device/simulator:

```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

Example device build (slice 4 will wire this into an Xcode build phase):

```bash
cargo build -p gotcha-six-core --features uniffi --release --target aarch64-apple-ios
```

## Signing

Placeholder bundle id is `nz.mcarthur.GotchaSix` until the team prefix is set in the Xcode project (slice 4). No signing config lives in this slice.
