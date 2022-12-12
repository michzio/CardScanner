import UIKit
import AVFoundation
import Vision

public class VisionController: UIViewController {
    
    let configuration: CardScanner.Configuration
    
    // Settings
    var usesLanguageCorrection: Bool {
        true
    }
    
    var recognitionLevel : VNRequestTextRecognitionLevel {
        .accurate
    }
    
    var minTextHeight: Float {
        0
    }
    
    var videoStabilizationMode: AVCaptureVideoStabilizationMode {
        .standard
    }

    /*
    lazy var imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .redraw //.scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    */
    
    lazy var previewView: PreviewView = {
        let previewView = PreviewView()
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.backgroundColor = UIColor.black
        previewView.previewLayer.videoGravity = .resizeAspectFill
        return previewView
    }()
    
    var overlayViewClass: ScannerOverlayView.Type {
        ScannerOverlayView.self
    }
    
    lazy var overlayView: ScannerOverlayView = {
        let overlayView = overlayViewClass.init(configuration: configuration)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.previewView = previewView
        return overlayView
    }()
    
    lazy var torchButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        button.setImage(UIImage(systemName: "bolt.fill"), for: .selected)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(torchAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return button
    }()
    
    var annotationLayer = AnnotationLayer()
    
    // MARK: - Capture Session
    /// real-time or offline capture
    /// to perform some actions on live stream
    private var device: AVCaptureDevice?
    
    internal var session = AVCaptureSession()
    internal let sessionQueue = DispatchQueue(label: "CaptureSessionQueue")
    
    internal var videoDataOutput = AVCaptureVideoDataOutput()
    internal let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
    
    /// Vision requests
    var requests = [VNRequest]()
    
    // MARK: - Helper Properties
    var cameraBrightness: Double = 1.0
    var cameraImageBuffer: CVImageBuffer?

    init(configuration: CardScanner.Configuration) {
        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func torchAction() {
        toggleTorch(on: !torchButton.isSelected)
    }

    // MARK: - Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // setupImageView()
        setupPreviewView()
        setupOverlayView()
        setupTorchButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupLiveStream()
        // setupTextRectanglesDetection()
        setupTextRecognition()
        startLiveStream()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLiveStream()
        // self.requests.removeAll()
    }
    
    /*
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?.first?.frame = imageView.bounds
    }*/
    
    // MARK: - Device Orientation Handling
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        print("[Vision Controller] Orientation did change")

        overlayView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
            self?.setupOrientation()
            self?.overlayView.isHidden = false
        }
    }
    
    private func setupOrientation() {
        
        // Only change the current orientation if the new one is landscape or
        // portrait. You can't really do anything about flat or unknown.
        let deviceOrientation = DeviceFeatures.orientation
        overlayView.currentOrientation = deviceOrientation
        
        // Handle device orientation in the preview layer.
        if let connection = previewView.previewLayer.connection {
            if let newOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) {
                connection.videoOrientation = newOrientation
            }
        }
    }
    
    // MARK: - Setup Views
    
    private func setupPreviewView() {
        view.addSubview(previewView)
        // constraint preview view
        previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // non-removable layer, drawing on this layer
        // stays even after capture preview stop
        previewView.layer.addSublayer(CALayer())
    }
    
    private func setupOverlayView() {
        view.addSubview(overlayView)
        // constraint overlay view
        overlayView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        overlayView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
        overlayView.topAnchor.constraint(equalTo: previewView.topAnchor).isActive = true
        overlayView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor).isActive = true
    }
    
    private func setupTorchButton() {
        view.addSubview(torchButton)
        // constraint button
        torchButton.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 12).isActive = true
        torchButton.topAnchor.constraint(equalTo: previewView.topAnchor, constant: 12).isActive = true
    }
    
    /*
    private func addAnnotationLayer() {
        
        annotationLayer.bounds = imageView.layer.frame
        annotationLayer.opacity = 0.0
        imageView.layer.addSublayer(annotationLayer)
    }*/
}

// MARK: - AVFoundation

extension VisionController {
    
    private func setupLiveStream() {
        
        previewView.session = session
        
        // Starting the capture session is a blocking call. Perform setup using
        // a dedicated serial dispatch queue to prevent blocking the main thread.
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
            
            // Calculate region of interest now that the camera is setup.
            DispatchQueue.main.async { [weak self] in
                
                // Figure out initial orientation
                self?.setupOrientation()
            }
        }
    }
     
    private func setupCaptureSession() {
        // remove previous inputs & outputs
        if let inputs = session.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                session.removeInput(input)
            }
        }
        if let outputs = session.outputs as? [AVCaptureVideoDataOutput] {
            for output in outputs {
                session.removeOutput(output)
            }
        }
        
        // redirect stream from camera to pixel buffer (screen)
        setupCaptureDevice()
        configCaptureDeviceInput()
        configVideoDataOutput()
        
        // configCaptureDeviceZoomAndFocus()
        
    }
    
    func startLiveStream() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    private func setupCaptureDevice() {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not create capture device.")
            return
        }
        self.device = device
        
        // NOTE:
        // Requesting 4k buffers allows recognition of smaller text but will
        // consume more power. Use the smallest buffer size necessary to keep
        // down battery usage.
        if device.supportsSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
            overlayView.bufferAspectRatio = 3_840.0 / 2_160.0
        } else {
            session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            overlayView.bufferAspectRatio = 1_920.0 / 1_080.0
        }
    }
    // Set zoom and autofocus to help focus on very small text.
    private func configCaptureDeviceZoomAndFocus() {
        
        guard let device = device else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = 2
            device.autoFocusRangeRestriction = .near
            device.unlockForConfiguration()
        } catch {
            print("Could not set zoom level due to error: \(error)")
            return
        }
    }
    
    func configCaptureDeviceZoom(_ factor: Double) {
        
        guard let device = device else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = CGFloat(factor)
            device.unlockForConfiguration()
        } catch {
            print("Could not set zoom level due to error: \(error)")
            return
        }
    }
    
    private func configCaptureDeviceInput() {
         guard
            let device,
            let input = try? AVCaptureDeviceInput(device: device)
        else {
             print("Could not create device input.")
             return
         }
         if session.canAddInput(input) {
             session.addInput(input)
         }
    }
    
    private func configVideoDataOutput() {
        
        let output = videoDataOutput
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        // [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            
            // NOTE:
            // There is a trade-off to be made here. Enabling stabilization will
            // give temporally more stable results and should help the recognizer
            // converge. But if it's enabled the VideoDataOutput buffers don't
            // match what's displayed on screen, which makes drawing bounding
            // boxes very hard. Disable it in this app to allow drawing detected
            // bounding boxes on screen.
            output.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = videoStabilizationMode
        } else {
            print("Could not add video data output")
            return
        }
    }
    
    @objc open func stopLiveStream() {
        // Stop the camera synchronously to ensure that no further buffers are
        // received. Then update the number view asynchronously.
        DispatchQueue.main.async { [weak self] in
            self?.toggleTorch(on: false)
        }
        
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

// MARK: - Vision Framework - Text Rectangles Detection

extension VisionController {
    
    private func setupTextRectanglesDetection() {

        let request = VNDetectTextRectanglesRequest(completionHandler: { [weak self] request, error in
            self?.textDetectionHandler(request: request, error: error)
        })
        request.reportCharacterBoxes = true
        
        requests.append(request)
    }
    
    func textDetectionHandler(request: VNRequest, error: Error?) {
        
        guard let observations = request.results as? [VNTextObservation] else {
            print("[Text detection] No result!")
            return
        }
        
        // highlighting words and characters
        DispatchQueue.main.async { [weak self] in
            self?.previewView.layer.sublayers?.removeSubrange(2...)
            for observation in observations {
                self?.highlightWord(for: observation)
                // self.highlightLetters(of: observation)
            }
        }
        
        /* NOT SO EASY! -> USE VNRecognizeTextRequest
        detectWords(of: observations)
        */
    }
    
    func detectWords(of observations: [VNTextObservation]) {
        
        for observation in observations {
            for characterBox in observation.characterBoxes ?? [] {
                // 1) Train CoreML model to do character recognition
                // 2) Run model on character box
                // 3) threshold against possible garbage results
            }
            // 4) Concatenate characters into string
            // 5) Fix recognized words based on dictionary
            //    and other probabile heuristics for character pairs
        }
    }
}

// MARK: - Vision Framework - Text Recognition

extension VisionController {
    
    private func setupTextRecognition() {
        
        let request = VNRecognizeTextRequest(completionHandler: { [weak self] request, error in
            self?.textRecognitionHandler(request: request, error: error)
        })
        
        request.recognitionLevel = recognitionLevel
        request.revision = VNRecognizeTextRequestRevision1
        request.usesLanguageCorrection = usesLanguageCorrection
        request.minimumTextHeight = minTextHeight
        request.regionOfInterest = overlayView.regionOfInterest
        
        requests.append(request)
    }
    
    func textRecognitionHandler(request: VNRequest, error: Error?) {
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            print("The observations are of an unexpected type.")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.previewView.layer.sublayers?.removeSubrange(2...)
        }
        
        observationsHandler(observations: observations)
    }
    
    @objc open func observationsHandler(observations: [VNRecognizedTextObservation] ) {
        
        for observation in observations {
            
            let candidates = observation.topCandidates(1)
            if let recognizedText = candidates.first {
                print("[Text recognition] ", recognizedText.string)
                
                /*
                let range = recognizedText.string.startIndex..<recognizedText.string.endIndex
                if let observation = try? recognizedText.boundingBox(for: range) {
                    DispatchQueue.main.async {
                        self.highlightBox(observation.boundingBox, color: UIColor.green)
                    }
                }*/
            }

            DispatchQueue.main.async { [weak self] in
                self?.highlightBox(observation.boundingBox, color: UIColor.white)
            }
        }
    }
}

// MARK: - Highlighting Words, Letters, Boxes

extension VisionController {
    
    func highlightWord(for observation: VNTextObservation) {
        
        guard let boxes = observation.characterBoxes else {
            return
        }
        
        var maxX: CGFloat = 9_999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9_999.0
        var minY: CGFloat = 0.0
        
        for box in boxes {
            if box.bottomLeft.x < maxX {
                maxX = box.bottomLeft.x
            }
            if box.bottomRight.x > minX {
                minX = box.bottomRight.x
            }
            if box.bottomRight.y < maxY {
                maxY = box.bottomRight.y
            }
            if box.topRight.y > minY {
                minY = box.topRight.y
            }
        }
        
        let x = maxX * previewView.frame.width
        let y = (1 - minY) * previewView.frame.height
        let width = (minX - maxX) * previewView.frame.width
        let height = (minY - maxY) * previewView.frame.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: x, y: y, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = configuration.accentColor.cgColor
        
        previewView.layer.addSublayer(outline)
    }
    
    func highlightLetters(of observation: VNTextObservation) {
        
        guard let boxes = observation.characterBoxes else { return }
        
        for box in boxes {
            highlightLetter(of: box)
        }
    }
    
    func highlightLetter(of observation: VNRectangleObservation) {
        highlightBox(observation.boundingBox, color: UIColor.white)
    }
    
    func highlightBox(_ box: CGRect, color: UIColor, lineWidth: CGFloat = 1.0, isTemporary: Bool = true) {
        guard configuration.drawBoxes else { return }

        func transform(_ box: CGRect) -> CGRect {
            let size = previewView.frame.size
            let roi = overlayView.regionOfInterest
            let roiX = roi.minX * size.width
            let roiY = roi.minY * size.height
            let roiWidth = roi.width * size.width
            let roiHeight = roi.height * size.height
            let transform = CGAffineTransform.identity
                .scaledBy(x: 1, y: -1)
                .translatedBy(x: roiX / 2, y: -roiY - size.height / 3.5)
                .scaledBy(x: roiWidth, y: roiHeight)


            let transformedBox = box.applying(transform)
            print("Box vs TransformedBox: ", box, transformedBox, size)

            return transformedBox
        }

        func draw(_ box: CGRect) {
            let outline = CALayer()
            outline.frame = box
            outline.borderWidth = lineWidth
            outline.borderColor = color.cgColor
            
            if isTemporary {
                previewView.layer.addSublayer(outline)
            } else {
                previewView.layer.sublayers?[1].addSublayer(outline)
            }
        }
        
        DispatchQueue.main.async {
            draw(transform(box))
        }
    }
}

extension VisionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        cameraBrightness = getBrightness(sampleBuffer: sampleBuffer)
        cameraImageBuffer = pixelBuffer
    
        var requestOptions: [VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: camData]
        }
        
        print("Text orientation: \(overlayView.textOrientation.rawValue)")
       
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: overlayView.textOrientation,
            options: requestOptions
        )
        
        // Update region of interest
        self.requests.forEach { request in
            if let request = request as? VNRecognizeTextRequest {
                request.regionOfInterest = overlayView.regionOfInterest
            } else if let request = request as? VNDetectRectanglesRequest {
                // request.regionOfInterest = overlayView.regionOfInterest
            }
        }
        
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print(error)
        }
    }
}

extension VisionController {
    func boundingBox(of string: String, in candidate: VNRecognizedText) -> CGRect? {
        if let range = candidate.string.range(of: string) {
            let box = try? candidate.boundingBox(for: range)?.boundingBox
            return box
        }
        return nil
    }
}

// MARK: - Torch Helpers

extension VisionController {
    func getBrightness(sampleBuffer: CMSampleBuffer) -> Double {
        let rawMetadata = CMCopyDictionaryOfAttachments(
            allocator: nil,
            target: sampleBuffer,
            attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)
        )
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        let brightnessValue = exifData?[kCGImagePropertyExifBrightnessValue as String] as? Double
        return brightnessValue ?? 0.0
    }
    
    func toggleTorch(on: Bool) {
        guard
            let device = AVCaptureDevice.default(for: AVMediaType.video),
            device.hasTorch
        else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            torchButton.isSelected = on
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }
}
