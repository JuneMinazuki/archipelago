import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SaverSettings.shared
    
    private var macbookName: String {
        Host.current().localizedName ?? "MacBook"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    HStack(spacing: 12) {
                        Slider(value: $settings.idleThresholdMinutes, in: 1...30, step: 1)
                        Text("\(Int(settings.idleThresholdMinutes)) mins")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                } label: {
                    Label("Idle Time Before Trigger", systemImage: "moon.zzz.fill")
                }
            } header: {
                Text("Idle & Sleep Configuration")
            }

            Section {
                LabeledContent {
                    HStack(spacing: 12) {
                        Slider(value: $settings.animationDuration, in: 2...30, step: 1)
                        Text("\(Int(settings.animationDuration))s")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                } label: {
                    Label("Generation / Draw Phase", systemImage: "wand.and.stars")
                }

                LabeledContent {
                    HStack(spacing: 12) {
                        Slider(value: $settings.holdDuration, in: 5...60, step: 5)
                        Text("\(Int(settings.holdDuration))s")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                } label: {
                    Label("Hold Phase (Static View)", systemImage: "pause.circle.fill")
                }

                LabeledContent {
                    HStack(spacing: 12) {
                        Slider(value: $settings.fadeDuration, in: 1...10, step: 1)
                        Text("\(Int(settings.fadeDuration))s")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                } label: {
                    Label("Fade Transition Phase", systemImage: "circle.lefthalf.filled")
                }
            } header: {
                Text("Animation Phase Durations")
            }

            Section {
                Toggle("Show Bottom Custom Text", isOn: $settings.showCustomText)
                
                LabeledContent {
                    TextField("", text: $settings.customBottomText, prompt: Text(macbookName).foregroundColor(.secondary))
                        .textFieldStyle(.roundedBorder)
                        .disabled(!settings.showCustomText)
                } label: {
                    Label("Custom Text Content", systemImage: "textformat")
                }
            } header: {
                Text("Customization")
            }
            
            Section {
                LabeledContent {
                    HStack(spacing: 12) {
                        Slider(value: $settings.darkFilter, in: 0.0...1.0, step: 0.05)
                        Text(String(format: "%.2f", settings.darkFilter))
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                } label: {
                    Label("Dark Filter Intensity", systemImage: "circle.hexagongrid.fill")
                }
            } header: {
                Text("Visual Effects")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Preferences")
        .padding(24)
        .frame(width: 500)
    }
}
