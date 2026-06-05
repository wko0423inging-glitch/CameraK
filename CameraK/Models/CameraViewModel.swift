import AVFoundation
import Combine
import Photos

class CameraViewModel: NSObject, ObservableObject {
    @Published var isCameraAuthorized = false
    @Published var cameraSession: AVCaptureSession?
    @Published var currentDevice: AVCaptureDevice?
    @Published var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    // Manual controls state
    @Published var isoValue: Float = 100
    @Published var shutterSpeed: Double = 1.0 / 100.0
    @Published var focusDistance: Float = 0.5
    @Published var whiteBalanceTemperature: Float = 6500
    @Published var exposureCompensation: Float = 0.0
    @Published var selectedLens: AVCaptureDevice.Position = .back
    @Published var selectedFormat: CaptureFormat = .heif
    @Published var manualMode: Bool = false
    @Published var useNightMode: Bool = false
    @Published var timerEnabled: Bool = false
    @Published var timerSeconds: Int = 3
    @Published var removeAppleProcessing: Bool = false

    private var timerTask: DispatchSourceTimer?

    // Device capabilities (will be updated by updateDeviceCapabilities)
    @Published var isoRange: ClosedRange<Float> = 100...6400
    @Published var shutterSpeedRange: ClosedRange<Double> = (1.0/1000.0)...30.0
    @Published var focusDistanceRange: ClosedRange<Float> = 0...1
    @Published var whiteBalanceRange: ClosedRange<Float> = 2000...10000
    @Published var exposureCompensationRange: ClosedRange<Float> = -3...3

    // Available lenses
    @Published var availableLenses: [AVCaptureDevice] = []
    @Published var selectedLensDevice: AVCaptureDevice?

    override init() {
        super.init()
        requestCameraPermission()
        setupCamera()
    }

    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraAuthorized = granted
                }
            }
        case .denied, .restricted:
            self.isCameraAuthorized = false
        @unknown default:
            break
        }
    }

    func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        do {
            // Setup input
            if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                let input = try AVCaptureDeviceInput(device: backCamera)
                if session.canAddInput(input) {
                    session.addInput(input)
                    self.currentDevice = backCamera
                    self.selectedLensDevice = backCamera
                }
            }

            // Setup photo output
            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            // Setup video preview
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            self.videoPreviewLayer = previewLayer

            self.cameraSession = session

            // Get device capabilities
            updateDeviceCapabilities()
            getAvailableLenses()

            // Set automatic mode by default (like standard camera)
            setupAutomaticMode()

            // Start session
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    func updateDeviceCapabilities() {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()

            // ISO range - get actual device maximum
            let minIso = device.minIso
            let maxIso = device.maxIso
            self.isoRange = minIso...maxIso
            print("ISO range: \(minIso)...(\(maxIso)")

            // Shutter speed range - support up to 30 seconds for Night mode
            let minExposureDuration = device.activeFormat.minExposureDuration
            let maxExposureDuration = device.activeFormat.maxExposureDuration

            // Cap at 30 seconds max for Night mode compatibility
            let thirtySeconds = CMTimeMakeWithSeconds(30.0, preferredTimescale: 1000000)
            let effectiveMaxDuration = CMTimeCompare(maxExposureDuration, thirtySeconds) > 0 ? thirtySeconds : maxExposureDuration

            let minSS = 1.0 / Double(CMTimeGetSeconds(minExposureDuration))
            let maxSS = Double(CMTimeGetSeconds(effectiveMaxDuration))

            self.shutterSpeedRange = minSS...maxSS
            print("Shutter speed range: 1/\(Int(minSS))...(\(String(format: "%.1f", maxSS))\"")

            // Focus distance range
            let minFocus = device.minAvailableFocusDistance
            let maxFocus = device.maxAvailableFocusDistance
            if minFocus >= 0 && maxFocus > 0 {
                self.focusDistanceRange = minFocus...maxFocus
                print("Focus distance range: \(minFocus)...\(maxFocus)")
            }

            // Exposure compensation range - get actual device limits
            let minExposure = device.minExposureCompensation
            let maxExposure = device.maxExposureCompensation
            self.exposureCompensationRange = minExposure...maxExposure
            print("Exposure compensation range: \(minExposure)...\(maxExposure)")

            // White balance temperature range - device specific
            let wbRange = getWhiteBalanceRange(for: device)
            self.whiteBalanceRange = wbRange
            print("White balance range: \(Int(wbRange.lowerBound))K...\(Int(wbRange.upperBound))K")

            device.unlockForConfiguration()
        } catch {
            print("Error updating device capabilities: \(error)")
        }
    }

    func getAvailableLenses() {
        // Get back cameras only (no front camera support)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )

        self.availableLenses = discoverySession.devices
    }

    func getWhiteBalanceRange(for device: AVCaptureDevice) -> ClosedRange<Float> {
        let deviceType = device.deviceType.rawValue

        // iPhone model-specific white balance temperature ranges
        switch deviceType {
        // iPhone 15 series
        case _ where deviceType.contains("15-Pro-Max"),
             deviceType.contains("15-Pro"):
            return 1500...10000

        // iPhone 14 series
        case _ where deviceType.contains("14-Pro-Max"),
             deviceType.contains("14-Pro"):
            return 1500...10000

        // iPhone 13 series
        case _ where deviceType.contains("13-Pro-Max"),
             deviceType.contains("13-Pro"):
            return 1500...10000

        // iPhone 12 series
        case _ where deviceType.contains("12-Pro-Max"),
             deviceType.contains("12-Pro"):
            return 2000...10000

        // iPhone 11 series
        case _ where deviceType.contains("11-Pro"),
             deviceType.contains("11"):
            return 2000...10000

        // iPhone XS / XR
        case _ where deviceType.contains("XS"),
             deviceType.contains("XR"):
            return 2000...10000

        // Default for older/unknown models
        default:
            return 2000...10000
        }
    }

    func setupAutomaticMode() {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()

            // Reset to automatic mode (like standard camera app)
            device.exposureMode = .autoExposure
            device.whiteBalanceMode = .autoWhiteBalance
            device.focusMode = .autoFocus

            device.unlockForConfiguration()
            print("Automatic mode enabled (like standard camera)")
        } catch {
            print("Error setting automatic mode: \(error)")
        }
    }

    func switchToManualMode() {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()

            // Switch to manual mode - apply current values
            device.exposureMode = .custom
            device.whiteBalanceMode = .locked
            device.focusMode = .locked

            device.unlockForConfiguration()
            print("Manual mode enabled")
        } catch {
            print("Error switching to manual mode: \(error)")
        }
    }

    func capturePhoto() {
        // If timer is enabled, schedule the capture instead of capturing immediately
        if timerEnabled && timerSeconds > 0 {
            startTimerCapture()
            return
        }

        // Capture immediately
        performCapture()
    }

    private func startTimerCapture() {
        var remainingSeconds = timerSeconds

        timerTask = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timerTask?.schedule(deadline: .now(), repeating: 1.0)
        timerTask?.setEventHandler { [weak self] in
            remainingSeconds -= 1
            if remainingSeconds <= 0 {
                self?.timerTask?.cancel()
                self?.timerTask = nil
                self?.performCapture()
            }
        }
        timerTask?.resume()
    }

    private func performCapture() {
        guard let session = cameraSession,
              let photoOutput = session.outputs.first(where: { $0 is AVCapturePhotoOutput }) as? AVCapturePhotoOutput else {
            return
        }

        let photoSettings = AVCapturePhotoSettings()

        // Configure photo format based on user selection
        switch selectedFormat {
        case .raw:
            if photoOutput.availablePhotoCodecTypes.contains(.raw) {
                photoSettings.photoCodecType = .raw
            }
        case .heif:
            if photoOutput.availablePhotoCodecTypes.contains(.heif) {
                photoSettings.photoCodecType = .heif
            }
        case .jpeg:
            photoSettings.photoCodecType = .jpeg
        }

        // Disable Apple processing if requested
        if removeAppleProcessing {
            photoSettings.isAutoStillImageStabilizationEnabled = false
            if #available(iOS 16.1, *) {
                photoSettings.isPhotosDeepFusionEnabled = false
            }
            photoSettings.isAutoRedEyeReductionEnabled = false
            photoSettings.isAutoVirtualDeviceHDREnabled = false
        }

        // Disable night mode if requested
        if !useNightMode {
            photoSettings.isNightModeEnabled = false
        }

        // Capture with settings
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    func switchLens(to device: AVCaptureDevice) {
        guard let session = cameraSession else { return }

        do {
            // Remove old input
            session.inputs.forEach { session.removeInput($0) }

            // Add new input
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                self.currentDevice = device
                self.selectedLensDevice = device
                updateDeviceCapabilities()
            }
        } catch {
            print("Error switching lens: \(error)")
        }
    }

    func setISO(_ value: Float) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            device.setExposureModeCustom(duration: CMTimeMakeWithSeconds(Double(shutterSpeed), preferredTimescale: 1000000), iso: value) { _ in }
            device.unlockForConfiguration()
            self.isoValue = value
        } catch {
            print("Error setting ISO: \(error)")
        }
    }

    func setShutterSpeed(_ duration: Double) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            let cmDuration = CMTimeMakeWithSeconds(duration, preferredTimescale: 1000000)
            device.setExposureModeCustom(duration: cmDuration, iso: isoValue) { _ in }
            device.unlockForConfiguration()
            self.shutterSpeed = duration
        } catch {
            print("Error setting shutter speed: \(error)")
        }
    }

    func setFocusDistance(_ distance: Float) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            device.focusMode = .locked
            device.setFocusModeLocked(lensPosition: distance) { _ in }
            device.unlockForConfiguration()
            self.focusDistance = distance
        } catch {
            print("Error setting focus: \(error)")
        }
    }

    func setWhiteBalance(_ temperature: Float) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            let gainsForColorTemperature = AVCaptureDevice.chromaticityValues(forColorTemperatureSource: temperature)
            device.setWhiteBalanceModeLocked(with: gainsForColorTemperature) { _ in }
            device.unlockForConfiguration()
            self.whiteBalanceTemperature = temperature
        } catch {
            print("Error setting white balance: \(error)")
        }
    }

    func setExposureCompensation(_ compensation: Float) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            device.exposureMode = .custom
            device.setExposureModeCustom(duration: CMTimeMakeWithSeconds(shutterSpeed, preferredTimescale: 1000000), iso: isoValue) { _ in }
            device.unlockForConfiguration()
            self.exposureCompensation = compensation
        } catch {
            print("Error setting exposure compensation: \(error)")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        // Get JPEG data or RAW data based on format
        let imageData: Data?
        switch photo.fileDataType {
        case AVFileType.raw:
            imageData = photo.fileDataRepresentation()
        case AVFileType.heif:
            imageData = photo.fileDataRepresentation()
        default:
            imageData = photo.fileDataRepresentation()
        }

        if let imageData = imageData {
            // Save to photo library
            saveImageToPhotoLibrary(imageData)
        }
    }

    private func saveImageToPhotoLibrary(_ imageData: Data) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access denied")
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let creationRequest: PHAssetCreationRequest

                // Handle different file types
                if self.selectedFormat == .raw {
                    // Save as DNG (RAW)
                    creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .alternativePhoto, data: imageData, options: nil)
                } else {
                    // Save as JPEG or HEIF
                    creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: imageData, options: nil)
                }
            }, completionHandler: { success, error in
                if success {
                    print("Image saved to photo library successfully")
                } else if let error = error {
                    print("Error saving image to photo library: \(error)")
                }
            })
        }
    }
}

enum CaptureFormat {
    case raw
    case heif
    case jpeg
}
