import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var viewModel: CameraViewModel
    @State private var showSettings = false
    @State private var showHistogram = false

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: viewModel.cameraSession)
                .ignoresSafeArea()

            // Histogram overlay
            if showHistogram {
                HistogramView()
                    .frame(height: 60)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding()
            }

            VStack {
                // Top controls
                HStack {
                    // Histogram toggle
                    Button(action: { showHistogram.toggle() }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Format selector
                    Menu {
                        Button("RAW (DNG)") {
                            viewModel.selectedFormat = .raw
                        }
                        Button("HEIF") {
                            viewModel.selectedFormat = .heif
                        }
                        Button("JPEG") {
                            viewModel.selectedFormat = .jpeg
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                            Text(formatName)
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(6)
                    }

                    // Settings button
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Manual mode toggle
                HStack {
                    Text("Manual Mode")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Button(action: { viewModel.manualMode.toggle() }) {
                        Image(systemName: viewModel.manualMode ? "slider.horizontal.3" : "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.manualMode ? .blue : .gray)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)

                // Manual controls panel (only shown when manual mode is ON)
                if viewModel.manualMode {
                VStack(spacing: 16) {
                    // ISO control
                    VStack(alignment: .leading) {
                        HStack {
                            Text("ISO")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(viewModel.isoValue))")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        Slider(value: $viewModel.isoValue, in: viewModel.isoRange)
                            .onChange(of: viewModel.isoValue) { newValue in
                                viewModel.setISO(newValue)
                            }
                    }

                    // Shutter speed control
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Shutter Speed")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(formatShutterSpeed(viewModel.shutterSpeed))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        Slider(value: $viewModel.shutterSpeed, in: viewModel.shutterSpeedRange)
                            .onChange(of: viewModel.shutterSpeed) { newValue in
                                viewModel.setShutterSpeed(newValue)
                            }
                    }

                    // Focus distance control
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Focus")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%.1f", viewModel.focusDistance))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        Slider(value: $viewModel.focusDistance, in: viewModel.focusDistanceRange)
                            .onChange(of: viewModel.focusDistance) { newValue in
                                viewModel.setFocusDistance(newValue)
                            }
                    }

                    // White balance control
                    VStack(alignment: .leading) {
                        HStack {
                            Text("White Balance")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(viewModel.whiteBalanceTemperature))K")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        Slider(value: $viewModel.whiteBalanceTemperature, in: viewModel.whiteBalanceRange)
                            .onChange(of: viewModel.whiteBalanceTemperature) { newValue in
                                viewModel.setWhiteBalance(newValue)
                            }
                    }

                    // Exposure compensation
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Exposure")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%+.1f", viewModel.exposureCompensation))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        Slider(value: $viewModel.exposureCompensation, in: viewModel.exposureCompensationRange)
                            .onChange(of: viewModel.exposureCompensation) { newValue in
                                viewModel.setExposureCompensation(newValue)
                            }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .padding()
                }

                // Bottom controls
                HStack(spacing: 20) {
                    // Night mode toggle
                    VStack {
                        Button(action: { viewModel.useNightMode.toggle() }) {
                            Image(systemName: viewModel.useNightMode ? "moon.stars.fill" : "moon.stars")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.useNightMode ? .yellow : .gray)
                        }
                        Text("Night")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }

                    // Apple processing toggle
                    VStack {
                        Button(action: { viewModel.removeAppleProcessing.toggle() }) {
                            Image(systemName: viewModel.removeAppleProcessing ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.removeAppleProcessing ? .green : .gray)
                        }
                        Text("No AI")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }

                    // Timer toggle
                    VStack {
                        Button(action: { viewModel.timerEnabled.toggle() }) {
                            Image(systemName: viewModel.timerEnabled ? "timer" : "timer")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.timerEnabled ? .orange : .gray)
                        }
                        Text("Timer")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Capture button
                    Button(action: { viewModel.capturePhoto() }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                    .frame(width: 80, height: 80)
                            )
                    }
                }
                .padding()
                .padding(.bottom)
            }

        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }

    private var formatName: String {
        switch viewModel.selectedFormat {
        case .raw:
            return "RAW"
        case .heif:
            return "HEIF"
        case .jpeg:
            return "JPEG"
        }
    }

    private func formatShutterSpeed(_ duration: Double) -> String {
        if duration >= 1 {
            return String(format: "%.1f\"", duration)
        } else {
            let fraction = Int(1.0 / duration)
            return "1/\(fraction)"
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CameraViewModel())
    }
}
