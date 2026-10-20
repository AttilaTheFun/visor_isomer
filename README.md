# visor_isomer

> [!WARNING]
> **Very experimental, in early development.** These hosts are a work in
> progress on an experimental framework: their APIs and behaviour will
> change without notice, and nothing here is supported. Use them at your own
> risk.

The [Isomer](https://github.com/AttilaTheFun/isomer) hosts of
[Visor](https://github.com/AttilaTheFun/visor): the same client, carried to
the web, Android, Linux and Windows.

Visor is the Apple-native app — the menu bar server, the iOS and Mac
clients and the libraries they share — as a Bazel module of its own. This
module depends on it (`bazel_dep(visor)`, pinned by commit) and adds what
each other platform needs:

- **.bazelrc** points visor's `//:swift_ui` label flag at isomer's
  SwiftUI, so `import SwiftUI` in visor's libraries is the reimplementation
  here rather than Apple's framework.
- **libraries/visor_services_ffi** — the client's three services (socket,
  HTTP, settings) as swift_ffi interfaces a host implements across a
  boundary: `SocketBridge`, `HttpBridge`, `SettingsBridge`.
  `installBridgedVisorServices` reads them from the injected dependency
  dictionary (the browser); `installVisorBridges` takes them directly
  (Android's Kotlin).
- **applications/visor_web** — the browser: index.html implements the
  bridges over WebSocket, fetch and localStorage. Published to
  https://attilathefun.github.io/visor_isomer_releases/ with tools/publish_web.sh.
- **applications/visor_android** — VisorServices.kt implements them over an
  SSL socket (a small RFC 6455 client of its own), HttpURLConnection and
  SharedPreferences.
- **applications/visor_linux**, **applications/visor_windows** — visor's
  own Foundation implementations, compiled for that platform's Foundation.
  Built on those hosts; unverified from a Mac.
- **applications/visor_isomer_compiled_ios** — the blue Visor
  (com.LoganShire.VisorIsomer) as of 0.32: visor's client compiled natively
  against Isomer's frameworks (isomer's `isomer_compiled_feature`), with
  visor's own iOS services, drawn by Apple's SwiftUI through isomer's
  WasmView. The same source as the red Visor with Isomer's SwiftUI in place
  of Apple's: its screens are compared with visor's iOS snapshots (launch it
  with `-visor.fixture snapshot -visor.fixture.screen <screen>`). iOS 18
  until Isomer's Foundation, Observation and Synchronization join it.
  applications/visor_isomer_ios is the wasm build it replaces (iOS 16).
- **libraries/visor_pasteboard_isomer**, **libraries/visor_camera_isomer** —
  visor's pasteboard and camera label flags, set in .bazelrc to Isomer's
  `Clipboard` and `cameraCapture`.

## Building

    bazel build //applications/visor_web
    bazel build //applications/visor_android
    bazel build //applications/visor_isomer_compiled_ios --ios_multi_cpus=sim_arm64
    tools/publish_web.sh <checkout of AttilaTheFun/visor_isomer_releases>

Developing visor and this module together: swap the `git_override` in
MODULE.bazel for the commented `local_path_override`.

## License

Apache 2.0.
