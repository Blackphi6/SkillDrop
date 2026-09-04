import SwiftUI

struct SkillDropApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 520, minHeight: 480)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 560, height: 560)
    }
}
