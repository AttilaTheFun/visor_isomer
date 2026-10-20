// Visor on iOS 15 as wasm: the client — the same VisorUI screens the web
// and Android run, under isomer's SwiftUI — compiled to a wasm reactor and
// run by WasmView in a native shell, which serves it its services
// (VisorIsomerServices) and draws its tree with real SwiftUI. The shell
// needs iOS 15; what the client uses of Swift and SwiftUI comes with the
// reactor, so it is not bound by the OS's.

#if canImport(CUuiEmbeddedAot)
import CUuiEmbeddedAot
#endif
import Foundation
import IsomerWamrRuntime
import IsomerWasmView
import SwiftUI

@main
struct VisorIsomerApp: App {
    @StateObject private var model = WasmViewModel()

    init() {
        // The reactor ahead of time: wamrc's image in the app's signed
        // __TEXT segment (BUILD.bazel, visor_embedded_aot), run in place; such
        // a build bundles no .wasm. An app built without the image (the
        // default; --config=aot links it) interprets the bundled .wasm.
        #if canImport(CUuiEmbeddedAot)
        var length = 0
        if let data = iso_embedded_aot_data(&length), length > 0 {
            WamrRuntime.embeddedImage = UnsafeRawBufferPointer(start: data, count: length)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            WasmView(
                model: model,
                provider: AppBundleProvider(resource: "visor"),
                ffiModulePrefix: visorFFIPrefix,
                dependencies: visorDependencies())
        }
    }
}
