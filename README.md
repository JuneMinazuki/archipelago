<img width="1280" height="640" alt="Banner" src="https://github.com/user-attachments/assets/83e49b06-0493-4523-95a3-cb7f153cbf1f" />

<p align="center"><b>Archipelago</b> is a native macOS menu bar application that prevents your Mac from locking into the login screen by running a hypnotic, procedurally generated hexagonal island screensaver.</p>

---

## ✨ Features

* **Procedural Island Generator**: Utilizes Perlin noise and cellular automata smoothing rules to dynamically generate unique, organic island topologies featuring deep water, shallow water, sand beaches, grass, forests, mountain rocks, and snow peaks.
* **Hardware-Accelerated Metal Rendering**: Custom Metal shaders render thousands of individual hexagonal grid tiles concurrently at a smooth 60 FPS with zero lag.
* **Smart Idle Monitoring**: Automatically tracks system idle time and triggers the screensaver without disrupting ongoing media playback, video calls, or active presentations.
* **Multi-Monitor Support**: Automatically detects and covers all active displays with borderless full-screen screensaver windows.
* **Customizable Preferences**: Configure your ideal idle thresholds, animation durations, hold phases, custom bottom overlay text, and dark filter intensity directly from the Preferences menu.
* **Seamless Menu Bar Integration**: Lives discretely in your Mac's menu bar with quick toggles to prevent system sleep, trigger the saver manually, or access settings.

## ⚙️ Preferences & Customization

You can access **Preferences** right from the menu bar item to customize:

* **Idle Time**: Set the required inactivity duration before the screensaver kicks in (1 to 30 minutes).
* **Animation Phases**: Tune the draw phase, static hold phase, and fade transitions.
* **Custom Text**: Optionally display custom text or your Mac's hostname at the bottom of the screensaver.
* **Dark Filter Intensity**: Adjust the brightness/darkness filter over the map rendering to suit dark-room environments.

---

## 🛠️ Tech Stack

* **Language**: Swift
* **UI Framework**: SwiftUI, AppKit
* **Graphics**: Metal, GameplayKit (Perlin Noise)
* **Power Management**: IOKit (`IOPMAssertion`)

---

## 🚀 Getting Started

### Prerequisites

* macOS 14.0+ (Sonoma or later recommended)
* Xcode 15.0+

### Installation & Building

1. Clone the repository:
```bash
git clone https://github.com/JuneMinazuki/archipelago.git
cd archipelago
```

2. Open the project in Xcode:
```bash
open archipelago.xcodeproj
```

*(Alternatively, open the folder as a Swift Package / Xcode project workspace).*

3. Build and run the target (`Archipelago`) using `Cmd + R`.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
