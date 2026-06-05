import SwiftUI

@main
struct CameraKApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CameraViewModel())
        }
    }
}
