#!/usr/bin/env bash
set -euo pipefail

aar=${1:-codec2/build/outputs/aar/codec2-release.aar}
abis=(arm64-v8a armeabi-v7a x86 x86_64)
libraries=(libcodec2.so libcodec2-android.so)

test -f "$aar"
contents=$(unzip -Z1 "$aar")

for abi in "${abis[@]}"; do
  for library in "${libraries[@]}"; do
    grep -Fxq "jni/$abi/$library" <<<"$contents"
  done
done

grep -Fxq 'assets/LICENSES/codec2-android-LGPL-2.1.txt' <<<"$contents"
grep -Fxq 'assets/LICENSES/Codec2-LGPL-2.1.txt' <<<"$contents"
grep -Fxq 'assets/NOTICE' <<<"$contents"

printf '%s\n' "$contents" | grep -E '^(jni/|assets/LICENSES/|assets/NOTICE$)'
