# visor_isomer, for agents

Read README.md for the parts. The app itself, its protocol and its rules
live in the visor module (github.com/AttilaTheFun/visor); the framework it
runs on is Isomer (github.com/AttilaTheFun/isomer).

## Changes

Every change to `main` goes through a pull request, reviewed by the code
owner (.github/CODEOWNERS). Keep each pull request to one focused change,
and say in it how the change was verified: the local CI below, on the
pull request's head. No attribution lines in commits.

## Rules

- Dependencies are pinned by released version: visor and isomer as Bazel
  modules from the project's registry (AttilaTheFun/bazel_registry, listed
  before the BCR in .bazelrc), with isomer's rules_swift and swift-foundation
  forks, which come from there too. Repeat isomer's other root-only
  overrides verbatim (flatbuffers' patches, rules_foreign_cc: bzlmod honours
  overrides from the root only). agent_ui and swift_sql are not pinned here:
  they come through visor, at the versions its Package.swift names. A branch
  may pin a commit while what it needs is in development; a release may not:
  tools/released_pins.sh says so, and CI's `pins` job runs it on main's
  commits, which Reviews checks before a release. App versions are the
  release's (0.36.1 (N)).
- No Apple team ids, certificates, provisioning profiles or device UDIDs in
  the repository: the team comes from the builder's own `.bazelrc.user`
  (`common --repo_env=VISOR_TEAM_ID=<team>`, visor's tools/signing), which
  is not checked in. Nor machine names, addresses or home paths: tools take
  them from the environment (`REVIEW_SERVER_HOST`, `ANDROID_SERIAL`).
- A person's own phone is not a test device: install a build there when
  they ask (tools/install_android.sh), read the version back, and stop. No
  launching, tapping or screenshots unless they explicitly ask. Test on the
  simulator and the emulator, which the harnesses below use.
- Never use Combine; async/await only. The client and UI compile against
  Isomer's SwiftUI off Apple's platforms: what the guest needs from its
  host (sockets, HTTP, settings, dictation, networks) goes through the
  bridges in libraries/visor_services_ffi, which each host implements
  (index.html on the web, VisorServices.kt on Android,
  VisorIsomerServices.swift on iOS). AgentUI's look is the package's; do
  not copy views.
- The guest is one source on every host (applications/visor_web/App.swift).
  Where AgentUI or visor choose by platform at compile time and the guest,
  built for WASI, must choose as the host's platform would, the host says
  so through a setting (`host.platform`) and the guest sets the choice in
  the environment (`suggestionsInPopover`).

## Local CI

`tools/ci/local_ci.sh [--review DIR] [suite…]` runs the suites in order and
says each one's verdict: `test` (`bazel test //...`), `snapshots`,
`layout-web`, `composer-web`, `layout-android`, `composer-android`,
`android-flow` and `web-e2e`. It wants a clean tree and a pushed HEAD, since
its results are about that commit; `tools/ci/check.py` posts each suite as
a check run on it where the GitHub App has the Checks permission.

The screens and UI tests are the proof of a commit: `tools/ci/publish_proof.py
[--commit SHA] [--pull-request N] <run dir>…` sends a run's targets (each a
`manifest.json` beside its files) to the review server through
the review tooling's `publish-proof` (a checkout at `RELEASES_CHECKOUT`),
with the server's Mac from
`REVIEW_SERVER_HOST`. With `--pull-request` the runs are kept with that pull
request's head; without, under the version they report.

## End-to-end test (the web client against a server)

`tools/e2e/run.py` builds the web client, serves it beside a stand-in Visor
Server (`stub_server.py`: `/api/hello`, the WebSocket login → `welcome`,
ping/pong, the calls a sessions list makes) and loads it in headless Chrome:
both stub sessions must be listed with no failed request and nothing
uncaught (`page_check.js`). `run.py <directory>` tests a site already built
(a published copy). Run it before publishing the web client. The stub's
numbers are the ones a 32-bit client can't hold (token counts and revisions
past 2^31, a count past exact doubles, negatives, fractions): wasm32's `Int`
is 32 bits, and `Int(Double)` traps out of range.

It runs three roads: the stub's WebSocket; the upgrade refused with 501
(`--no-websocket`, a reverse proxy that passes no WebSockets), when the list
must still appear by polling (`GET /api/sessions?since=`, held by the stub
while nothing changed; `/stub/stats` proves the polls happened); and no shim
and nothing saved, when the page, served by the stub itself, must find the
server at its own origin. `run.py --review <dir>` also runs it in a
landscape window and records each road, writing `ui-test` manifests.

`tools/uitests/android_flow.py --review <dir>` is the Android UI test: on
the emulator (or a leased lab phone, `ANDROID_SERIAL`), in portrait and in
landscape, it does what a reader does on visor's snapshot fixture (the
sessions list, a session opened, its details opened and closed, New
Session, a question answered), each step recorded with its last screen. Its
checks read the UI dump as XML (`uiautomator dump --windows` where a popup
must be seen): a button's `enabled` is on the clickable node above the words
Compose puts in it.

`tools/e2e/transcript_layout_check.js` and `composer_check.js` (headless
Chrome, a 390-point window by device emulation) and their Android twins in
tools/uitests check the transcript's code blocks and pictures and AgentUI's
composer typed into.

## Snapshot tests

`tools/snapshots/snapshots.py run [--targets …] [--screens …]` screenshots
every screen of visor's fixture mode (`fixture=snapshot`,
`fixture.screen=<screen>`: a canned computer, sessions and transcript at a
fixed clock) and compares each with tests/snapshots/<target>/<screen>.png,
painting changed pixels red in a diff (report.html); it exits 1 when
anything changed. `snapshots.py accept <run dir> [--targets …] [--screens …]`
makes captures the references: accept only what changed, and commit them
with the change that moved them. `VISOR_SNAPSHOT_BAZEL_FLAGS` adds Bazel
flags (an `--override_module` to test an unpinned dependency).

- `web-mobile`: the web client in Mobile Safari on the harness's own
  simulator, `visor-snapshots`, made if missing and shut down after.
- `ios`, `ios-landscape`: the iPhone app (the WasmKit one), pictured by
  tests/ios_fixture, an XCUITest that takes the fixture's screens as visor's
  own probe takes the native app's, on an iPhone 17 with iOS 27 and the
  same status bar, a simulator its runner makes and deletes. Filed as target
  `ios` in each orientation, so a review server can hold each picture
  against the native app's.
- `android`: the hermetic emulator (emulator-5554, booted if none).
- `android-lab`, `android-lab-landscape`: a leased lab phone, only inside a
  lease (`ANDROID_SERIAL` and the lab's adb from it), with references of
  their own.
- `red-ios`, `web-desktop`, `macos`: the native app on the iPhone simulator,
  and desktop Safari and the Mac app in a macOS test VM.

Never another session's simulator or emulator: the harness uses its own.
