import UIKit
import Vision
import CoreHaptics

protocol CardScannerDelegate: AnyObject {
    
    func didTapCancel()
    func didTapDone(number: String?, expDate: String?, holder: String?)
    
    func didScanCard(number: String?, expDate: String?, holder: String?)
}

public class CardScannerController : VisionController {
    
    // MARK: - Delegate
    weak var delegate: CardScannerDelegate?
    
    // MRAK: - Ovelay View
    override var overlayViewClass: ScannerOverlayView.Type {
        return CardOverlayView.self
    }
    
    // MARK: - Views
    lazy var cardNumberLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = ""
        label.font = .systemFont(ofSize: 20)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var brandLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = ""
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var expDateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = ""
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var cardHolderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = ""
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var button: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.setTitle(configuration.localizedCancelButton, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(configuration: CardScanner.Configuration) {
        super.init(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLabels()
        setupButton()
    }

    @objc func doneButtonAction() {
        if button.title(for: .normal) == configuration.localizedCancelButton {
            stopLiveStream()
            delegate?.didTapCancel()
        } else {
            delegate?.didTapDone(number: foundNumber, expDate: foundExpDate, holder: foundCardHolder)
        }
    }
    
    func setupLabels() {
        
        let stack = UIStackView(arrangedSubviews: [cardNumberLabel, brandLabel, expDateLabel, cardHolderLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .leading
       
        view.addSubview(stack)
        // constraint labels
        stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
    }
    
    func setupButton() {
        view.addSubview(button)
        // constraint button
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        button.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
    }
    
    override var usesLanguageCorrection: Bool {
        return true
    }
    
    override var recognitionLevel: VNRequestTextRecognitionLevel {
        return .accurate
    }
    
    // You can hint here user first/last name
    // To improve card holder detection
    var firstNameSuggestion: String = ""
    var lastNameSuggestion: String = ""

    let numberTracker = StringTracker()
    let expDateTracker = StringTracker()
    let fullNameTracker = StringTracker()
    
    var foundNumber : String?
    var foundExpDate : String?
    var foundCardHolder : String?
    
    public override func observationsHandler(observations: [VNRecognizedTextObservation] ) {
        
        var numbers = [StringRecognition]()
        var expDates = [StringRecognition]()
        
        // Create a full transcript to run analysis on.
        var text : String = ""
        
        if observationsCount == 20 && (foundNumber == nil) && cameraBrightness < 0 {
            // toggleTorch(on: true)
        }
        
        let maximumCandidates = 1
        for observation in observations {
            
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            print("[Text recognition] ", candidate.string)
            
            if foundNumber == nil, let cardNumber = candidate.string.checkCardNumber() {
                let box = observation.boundingBox
                numbers.append((cardNumber, box))
            }
            if foundExpDate == nil, let expDate = candidate.string.extractExpDate() {
                let box = boundingBox(of: expDate, in: candidate)
                expDates.append((expDate, box))
            }
            
            text += candidate.string + " "

            highlightBox(observation.boundingBox, color: UIColor.white)
        }
        
        if foundNumber == nil, let cardNumber = text.extractCardNumber() {
            numbers.append((cardNumber, nil))
        }
       
        searchCardNumber(numbers)
        searchExpDate(expDates)
        searchCardHolder(text)
        
        shouldStopScanner()
    }
    
    private func searchCardNumber(_ numbers : [StringRecognition]) {
        guard foundNumber == nil else { return }
            
        numberTracker.logFrame(recognitions: numbers)
            
        if let sureNumber = numberTracker.getStableString() {
            foundNumber = sureNumber
            
            showString(string: sureNumber, in: cardNumberLabel)
            
            let cardType = CardValidator().validationType(from: sureNumber)
            let brand = cardType?.group.rawValue ?? ""
            showString(string: brand, in: brandLabel)
            
            if let box = numberTracker.getStableBox() {
                highlightBox(box, color: configuration.accentColor, lineWidth: 2, isTemporary: false)
            }
            
            numberTracker.reset(string: sureNumber)
        }
    }
    
    private func searchExpDate(_ expDates: [StringRecognition]) {
        guard foundExpDate == nil else { return }
        
        expDateTracker.logFrame(recognitions: expDates)
        
        if let sureExpDate = expDateTracker.getStableString() {
            foundExpDate = sureExpDate
            
            showString(string: sureExpDate, in: expDateLabel)
            
            if let box = expDateTracker.getStableBox() {
                highlightBox(box, color: configuration.accentColor, lineWidth: 2, isTemporary: false)
            }
            
            expDateTracker.reset(string: sureExpDate)
        }
    }
    
    private func searchCardHolder(_ text: String) {
        
        guard foundCardHolder == nil else { return }
        
        func trackFullName(_ fullName: StringRecognition) {
            fullNameTracker.logFrame(recognition: fullName)
            
            if let sureFullName = fullNameTracker.getStableString() {
                foundCardHolder = sureFullName
                
                showString(string: sureFullName, in: cardHolderLabel)
                
                fullNameTracker.reset(string: sureFullName)
            }
        }
        
        if let fullName = text.extractCardHolder2() {
            trackFullName((fullName, nil))
        } else if let fullName = text.checkFullName(firstName: firstNameSuggestion, lastName: lastNameSuggestion) {
            trackFullName((fullName, nil))
        }
    }
    
    private func showString(string: String, in label: UILabel) {
        DispatchQueue.main.async {
            label.text = "\(string)"
        }
    }
    
    private func showString(string: NSAttributedString, in label: UILabel) {
        DispatchQueue.main.async {
            label.attributedText = string
        }
    }
    
    // MARK: - Scanner Stop
    var observationsCount: Int = 0
    
    private func shouldStopScanner() {
        
        if foundNumber != nil && ((foundExpDate != nil && foundCardHolder != nil) || (observationsCount > 50) ) {
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            stopLiveStream()
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.didScanCard(
                    number: strongSelf.foundNumber,
                    expDate: strongSelf.foundExpDate,
                    holder: strongSelf.foundCardHolder
                )
            }
        }
        
        observationsCount += 1
    }
    
    public override func stopLiveStream() {
        super.stopLiveStream()
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.button.setTitle(strongSelf.configuration.localizedDoneButton, for: .normal)
            strongSelf.previewView.layer.sublayers?.removeSubrange(2...)
        }
    }
}
