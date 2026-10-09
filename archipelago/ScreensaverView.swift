import SwiftUI

struct ScreensaverView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Text("Archipelago Screensaver")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
