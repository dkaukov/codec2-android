# Repository guidance

## Purpose and scope

This repository produces the standalone Android AAR
`io.github.dkaukov:codec2-android`.

Keep the library deliberately small. It is an Android wrapper for Codec2
`CODEC2_MODE_1300`, not a comprehensive Codec2 SDK and not a FreeDV API.

The public API is `io.github.dkaukov.codec2.Codec2`:

- `PCM_SAMPLES == 320`
- `FRAME_BYTES == 7`
- constructor and native lifecycle management
- `encode(short[], byte[])`
- `decode(byte[], short[])`
- idempotent `close()`

Do not expose raw native handles or other Codec2 modes without an explicit
request.

## Project layout

- `codec2/src/main/java/`: public Java API.
- `codec2/src/main/cpp/`: JNI facade and minimal Codec2 native build.
- `codec2/src/test/`: host-side JVM tests.
- `codec2/src/androidTest/`: Android/JNI lifecycle and round-trip tests.
- `scripts/inspect-aar.sh`: verifies packaged ABIs, native libraries, and
  licensing files.
- `.github/workflows/build.yml`: build, verification, and emulator tests.
- `.github/workflows/release.yml`: signed Maven Central publication.

## Native build constraints

- Use Codec2 1.2.0 pinned to commit
  `06d4c11e699b0351765f10398abb4f663a984f36`.
- Enable only `CODEC2_MODE_1300`.
- Keep LPCNet, FreeDV modes, and upstream tests disabled.
- Generate only codebooks required by mode 1300.
- Keep unused Codec2 sources and symbols out of the native library.
- Build the codebook generator with a host C compiler and Codec2 itself with
  the Android NDK.
- Package Codec2 as replaceable `libcodec2.so` and the JNI facade as
  `libcodec2-android.so`.
- Preserve support for `arm64-v8a`, `armeabi-v7a`, `x86`, and `x86_64` unless
  an explicit compatibility decision changes the supported ABI set.
- A consuming Android application must never need CMake, Codec2 source, native
  build tools, or codebook generation.

## Build and verification

Use JDK 17 or newer with Android SDK 36, NDK `27.0.12077973`, and CMake 3.22.1.

Run the main verification suite from the repository root:

```sh
./gradlew clean test lint verifyReleaseAar publishReleasePublicationToMavenLocal
./scripts/inspect-aar.sh
```

Run native instrumented tests when an Android device or emulator is available:

```sh
./gradlew connectedDebugAndroidTest
```

Always inspect the release AAR after native or packaging changes. It must
contain both native libraries under every supported ABI directory and the
license/notice assets.

## Public API and JNI safety

- Preserve exact Java-side array length validation.
- Preserve native-side defensive array and handle validation.
- Keep `close()` safe and idempotent.
- Operations after close must throw `IllegalStateException`.
- Keep encode, decode, and close serialized per instance.
- Update `consumer-rules.pro` if JNI class or method names change.
- Native tests are lossy-codec tests; never compare decoded PCM byte-for-byte
  with input PCM.

## Publishing

- Coordinates are `io.github.dkaukov:codec2-android:<version>`.
- Use Android release single-variant publishing with `maven-publish` and
  `signing`.
- Keep sources, Javadoc, POM metadata, developer identity, licensing, and SCM
  metadata in the publication.
- Never hard-code credentials or private signing material.
- Never publish to Maven Central unless explicitly requested and credentials
  are intentionally provided.
- Normal build and pull-request workflows must not publish.

## Licensing

Codec2 1.2.0 is GNU LGPL 2.1. Do not remove or weaken:

- `LICENSE`
- `LICENSES/Codec2-LGPL-2.1.txt`
- `NOTICE`
- licenses and notice packaged in the AAR
- the replaceable shared-library arrangement
- the pinned corresponding-source and reproducible-build information

Treat licensing changes as release-critical and verify them against the pinned
Codec2 source rather than guessing.

## Working conventions

- Work directly in this checkout; do not create additional worktrees.
- Preserve unrelated modifications and generated artifacts.
- Do not commit, push, create releases, or publish packages unless explicitly
  requested.
- Use `rg` for searches and `apply_patch` for text edits.
- Run the narrowest relevant tests after each change and the full verification
  suite before handoff.
- Run `git diff --check` before handoff once files are tracked.
