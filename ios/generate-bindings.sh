#!/usr/bin/env bash
# Build gotcha-six-core (uniffi) and generate Swift bindings into ios/GotchaSixCore/Generated/.
# Generated files are gitignored — run from Xcode (slice 4) or locally before compiling the app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/ios/GotchaSixCore/Generated"
cd "$ROOT"

cargo build -p gotcha-six-core --features uniffi --release

if [[ "$(uname -s)" == "Darwin" ]]; then
  LIB="${ROOT}/target/release/libgotcha_six_core.dylib"
else
  LIB="${ROOT}/target/release/libgotcha_six_core.so"
fi

mkdir -p "$OUT"
cargo run -p gotcha-six-core --features uniffi-cli --bin uniffi-bindgen -- \
  generate --library "$LIB" --language swift --out-dir "$OUT"

echo "Wrote Swift bindings to $OUT"
ls -la "$OUT"
