import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Camera Settings") {
                    Toggle("Remove Apple Processing", isOn: $viewModel.removeAppleProcessing)
                    Toggle("Night Mode", isOn: $viewModel.useNightMode)
                    Toggle("Timer", isOn: $viewModel.timerEnabled)

                    if viewModel.timerEnabled {
                        Stepper("Timer Duration: \(viewModel.timerSeconds)s", value: $viewModel.timerSeconds, in: 0...30)
                    }
                }

                Section("Capture Format") {
                    Picker("Format", selection: $viewModel.selectedFormat) {
                        Text("RAW (DNG)").tag(CaptureFormat.raw)
                        Text("HEIF").tag(CaptureFormat.heif)
                        Text("JPEG").tag(CaptureFormat.jpeg)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Manual Controls Range") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ISO: \(String(format: "%.0f", viewModel.isoRange.lowerBound)) - \(String(format: "%.0f", viewModel.isoRange.upperBound))")
                            .font(.caption)
                        Text("Shutter Speed: 1/\(Int(1.0 / viewModel.shutterSpeedRange.upperBound)) - \(String(format: "%.1f\"", viewModel.shutterSpeedRange.lowerBound))")
                            .font(.caption)
                        Text("White Balance: \(Int(viewModel.whiteBalanceRange.lowerBound))K - \(Int(viewModel.whiteBalanceRange.upperBound))K")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }

                Section("Available Devices") {
                    if !viewModel.availableLenses.isEmpty {
                        ForEach(viewModel.availableLenses, id: \.uniqueID) { device in
                            HStack {
                                Text(device.deviceType.rawValue)
                                    .font(.caption)
                                Spacer()
                                if viewModel.selectedLensDevice?.uniqueID == device.uniqueID {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } else {
                        Text("No devices available")
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetToDefaults() {
        viewModel.manualMode = false
        viewModel.isoValue = 100
        viewModel.shutterSpeed = 1.0 / 100.0
        viewModel.focusDistance = 0.5
        viewModel.whiteBalanceTemperature = 6500
        viewModel.exposureCompensation = 0.0
        viewModel.selectedFormat = .heif
        viewModel.useNightMode = false
        viewModel.removeAppleProcessing = false
        viewModel.timerEnabled = false
        viewModel.timerSeconds = 3
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(CameraViewModel())
    }
}
