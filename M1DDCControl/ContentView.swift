import SwiftUI
import AppKit

struct DisplayItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let uuid: String
    let isBuiltin: Bool
}

struct ContentView: View {
    @EnvironmentObject var launchAtLogin: LaunchAtLoginManager

    @State private var displays: [DisplayItem] = []
    @State private var selectedDisplayID: Int = 1
    @State private var brightness: Double = 50
    @State private var outputText: String = ""
    @State private var isLoading = false

    private let service = M1DDCService()

    private var selectedDisplay: DisplayItem? {
        displays.first { $0.id == selectedDisplayID }
    }

    private var canControlBrightness: Bool {
        guard let selectedDisplay else { return false }
        return !selectedDisplay.isBuiltin
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("M1DDCControl")
                .font(.headline)

            Toggle("Load at startup", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            if !launchAtLogin.errorMessage.isEmpty {
                Text(launchAtLogin.errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Divider()

            Button("Load Displays") {
                loadDisplays()
            }

            Picker("Display", selection: $selectedDisplayID) {
                ForEach(displays) { display in
                    Text("[\(display.id)] \(display.name)")
                        .tag(display.id)
                }
            }
            .pickerStyle(.menu)
            
            if let selectedDisplay {
                Text("Selected: [\(selectedDisplay.id)] \(selectedDisplay.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let selectedDisplay, selectedDisplay.isBuiltin {
                Text("Built-in Retina display is shown for reference only. Brightness control is disabled for it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Brightness: \(Int(brightness))")

            Slider(value: $brightness, in: 0...100, step: 1)
                .disabled(!canControlBrightness)

            Button("Set Brightness") {
                setBrightness()
            }
            .disabled(!canControlBrightness)

            if isLoading {
                ProgressView()
            }

            Divider()

            ScrollView {
                Text(outputText.isEmpty ? "No output yet" : outputText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 110)

            Divider()

            HStack {
                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            loadDisplays()
            launchAtLogin.refresh()
        }
    }

    private func loadDisplays() {
        isLoading = true

        let currentSelectedID = selectedDisplayID

        Task {
            do {
                let raw = try service.listDisplays()
                let parsed = parseDisplays(from: raw)

                await MainActor.run {
                    self.displays = parsed

                    if parsed.contains(where: { $0.id == currentSelectedID }) {
                        self.selectedDisplayID = currentSelectedID
                    } else if let firstExternal = parsed.first(where: { !$0.isBuiltin }) {
                        self.selectedDisplayID = firstExternal.id
                    } else if let first = parsed.first {
                        self.selectedDisplayID = first.id
                    }

                    self.outputText = raw.replacingOccurrences(of: "(null)", with: "Built-in Retina Display")
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.outputText = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    private func setBrightness() {
        guard canControlBrightness else { return }

        isLoading = true

        Task {
            do {
                let value = Int(brightness)
                _ = try service.setBrightness(displayID: selectedDisplayID, value: value)
                let rawDisplays = try service.listDisplays()

                await MainActor.run {
                    self.outputText = rawDisplays
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.outputText = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func parseDisplays(from raw: String) -> [DisplayItem] {
        raw
            .split(separator: "\n")
            .compactMap { line in
                let pattern = #"\[(\d+)\]\s+(.+?)\s+\(([A-F0-9\-]+)\)"#

                guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
                let lineString = String(line)
                let range = NSRange(lineString.startIndex..<lineString.endIndex, in: lineString)

                guard let match = regex.firstMatch(in: lineString, options: [], range: range),
                      let idRange = Range(match.range(at: 1), in: lineString),
                      let nameRange = Range(match.range(at: 2), in: lineString),
                      let uuidRange = Range(match.range(at: 3), in: lineString),
                      let id = Int(lineString[idRange]) else {
                    return nil
                }

                let rawName = String(lineString[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let uuid = String(lineString[uuidRange])

                let isBuiltin = rawName == "(null)"
                let displayName = isBuiltin ? "Built-in Retina Display" : rawName

                return DisplayItem(id: id, name: displayName, uuid: uuid, isBuiltin: isBuiltin)
            }
    }
}
