#!/usr/bin/env bash
# Xcode Run Script: build gotcha-six-core for the active Apple target and
# generate UniFFI Swift into ios/GotchaSixCore/Generated/ (gitignored).
set -euo pipefail

if [[ -z "${SRCROOT:-}" ]]; then
  SRCROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
ROOT="$(cd "${SRCROOT}/.." && pwd)"
OUT="${SRCROOT}/GotchaSixCore/Generated"
cd "$ROOT"

# Map Xcode platform → rustc target.
PLATFORM_NAME="${PLATFORM_NAME:-iphonesimulator}"
ARCHS="${ARCHS:-arm64}"
case "${PLATFORM_NAME}" in
  iphoneos)
    RUST_TARGET="aarch64-apple-ios"
    ;;
  iphonesimulator)
    # Prefer arm64 sim (Apple Silicon). Only use x86_64 when that is the sole arch.
    if [[ "${ARCHS}" == "x86_64" ]]; then
      RUST_TARGET="x86_64-apple-ios"
    else
      RUST_TARGET="aarch64-apple-ios-sim"
    fi
    ;;
  macosx)
    RUST_TARGET="aarch64-apple-darwin"
    ;;
  *)
    echo "error: unsupported PLATFORM_NAME=${PLATFORM_NAME}" >&2
    exit 1
    ;;
esac

export PATH="${HOME}/.cargo/bin:${PATH}"
# Keep artifacts in-repo so LIBRARY_SEARCH_PATHS stays stable (ignore sandbox overrides).
export CARGO_TARGET_DIR="${ROOT}/target"

LIB_DIR="${SRCROOT}/GotchaSixCore/lib"
mkdir -p "${OUT}" "${LIB_DIR}"

echo "Building gotcha-six-core (${RUST_TARGET}, uniffi)…"
cargo build -p gotcha-six-core --features uniffi --release --target "${RUST_TARGET}"

# Bindgen reads a host library (cdylib). Build the host crate once, then generate.
echo "Generating UniFFI Swift → ${OUT}"
cargo build -p gotcha-six-core --features uniffi --release
HOST_LIB="${CARGO_TARGET_DIR}/release/libgotcha_six_core.dylib"
if [[ ! -f "${HOST_LIB}" ]]; then
  echo "error: missing host library ${HOST_LIB}" >&2
  exit 1
fi

cargo run -p gotcha-six-core --features uniffi-cli --bin uniffi-bindgen -- \
  generate --library "${HOST_LIB}" --language swift --out-dir "${OUT}"

STATIC_LIB="${CARGO_TARGET_DIR}/${RUST_TARGET}/release/libgotcha_six_core.a"
if [[ ! -f "${STATIC_LIB}" ]]; then
  echo "error: missing static library ${STATIC_LIB}" >&2
  exit 1
fi

# Stable link path for Xcode (avoids embedding rustc target triple in project settings).
cp -f "${STATIC_LIB}" "${LIB_DIR}/libgotcha_six_core.a"

echo "Rust core ready: ${LIB_DIR}/libgotcha_six_core.a"
ls -la "${OUT}"
