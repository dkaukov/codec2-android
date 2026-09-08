# codec2-android

`codec2-android` is a deliberately small Android AAR wrapper for
[Codec2](https://github.com/drowe67/codec2) **1.2.0**. It exposes only
`CODEC2_MODE_1300`: 320 signed 16-bit PCM samples at 8 kHz are encoded as one
7-byte frame and decoded back to 320 samples.

Applications consuming the published AAR do not run CMake, download Codec2,
generate codebooks, or require host C build tools. The AAR already contains the
Java API and native libraries.

## Dependency

```groovy
dependencies {
    implementation "io.github.dkaukov:codec2-android:<version>"
}
```

## API

```java
import io.github.dkaukov.codec2.Codec2;

short[] pcm = new short[Codec2.PCM_SAMPLES];
byte[] frame = new byte[Codec2.FRAME_BYTES];

try (Codec2 codec2 = new Codec2()) {
    codec2.encode(pcm, frame);
    codec2.decode(frame, pcm);
}
```

Arrays must have exactly the documented lengths. A closed instance rejects
further operations. Instances serialize encode, decode, and close calls; use a
separate instance for each independent stream.

## Supported Android ABIs

- `arm64-v8a`
- `armeabi-v7a`
- `x86`
- `x86_64`

## Building locally

Requirements:

- JDK 17 or newer
- Android SDK 36 and NDK 27 or a compatible installed NDK
- CMake 3.22.1
- Git and a host C compiler (`cc`, `clang`, or `gcc`)

Build and verify the release AAR:

```shell
./gradlew clean test verifyReleaseAar
```

The result is `codec2/build/outputs/aar/codec2-release.aar`.

During each ABI's CMake configure step, the build fetches the commit behind the
Codec2 1.2.0 tag. It compiles Codec2's `generate_codebook.c` with the **host** C
compiler, runs that executable for only the codebooks required by mode 1300,
then compiles the selected Codec2 C sources with the Android NDK. Codec2 is
packaged as `libcodec2.so`; the small JNI facade is `libcodec2-android.so`.

## Publishing

Set `VERSION_NAME` to the release version and provide Central Portal credentials
and an ASCII-armored in-memory PGP key:

```shell
./gradlew \
  -PVERSION_NAME=1.0.0 \
  -PmavenCentralUsername=... \
  -PmavenCentralPassword=... \
  -PsigningKey="$(cat private-key.asc)" \
  -PsigningPassword=... \
  publishReleasePublicationToMavenCentralRepository
```

The `v*` GitHub release workflow performs the same signed publication and asks
the Central Portal staging compatibility service to validate and automatically
release it. Publishing is never run by the normal build workflow.

Required GitHub Actions secrets:

- `MAVEN_CENTRAL_USERNAME` — Central Portal user-token username
- `MAVEN_CENTRAL_PASSWORD` — Central Portal user-token password
- `SIGNING_KEY` — ASCII-armored private PGP key
- `SIGNING_PASSWORD` — private-key passphrase

Equivalent Gradle properties are `mavenCentralUsername`,
`mavenCentralPassword`, `signingKey`, and `signingPassword`.

## Licensing

Codec2 1.2.0 and this wrapper are distributed under GNU LGPL 2.1. Complete
license text is in [`LICENSES/Codec2-LGPL-2.1.txt`](LICENSES/Codec2-LGPL-2.1.txt)
and is also packaged in the AAR. [`NOTICE`](NOTICE) identifies the pinned
upstream source and the exact build recipe. The AAR keeps Codec2 in a separate
shared library so it can be rebuilt and replaced independently.
