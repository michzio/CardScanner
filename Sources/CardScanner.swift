import SwiftUI

public typealias CardScannerHandler = (_ number: String?, _ expDate: String?, _ holder: String?) -> Void

public struct CardScanner: UIViewControllerRepresentable {

    public struct Configuration {
        let watermarkText: String
        let font: UIFont
        let accentColor: UIColor
        let watermarkWidth: CGFloat
        let watermarkHeight: CGFloat
        let drawBoxes: Bool
        let localizedCancelButton: String
        let localizedDoneButton: String

        public init(
            watermarkText: String,
            font: UIFont,
            accentColor: UIColor,
            watermarkWidth: CGFloat,
            watermarkHeight: CGFloat,
            drawBoxes: Bool,
            localizedCancelButton: String,
            localizedDoneButton: String
        ) {
            self.watermarkText = watermarkText
            self.font = font
            self.accentColor = accentColor
            self.watermarkWidth = watermarkWidth
            self.watermarkHeight = watermarkHeight
            self.drawBoxes = drawBoxes
            self.localizedCancelButton = localizedCancelButton
            self.localizedDoneButton = localizedDoneButton
        }

        public static let `default` = Configuration(
            watermarkText: "Card_Scanner",
            font: .systemFont(ofSize: 24),
            accentColor: .white,
            watermarkWidth: 150,
            watermarkHeight: 50,
            drawBoxes: false,
            localizedCancelButton: "Cancel",
            localizedDoneButton: "Done"
        )
    }
    
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    
    private let firstNameSuggestion: String
    private let lastNameSuggestion: String
    private let configuration: Configuration
    
    // MARK: - Actions
    let onCardScanned: CardScannerHandler
    
    public init(
        firstNameSuggestion: String = "",
        lastNameSuggestion: String = "",
        configuration: Configuration = .default,
        onCardScanned: @escaping CardScannerHandler = { _, _, _ in }
    ) {
        self.firstNameSuggestion = firstNameSuggestion
        self.lastNameSuggestion = lastNameSuggestion
        self.configuration = configuration
        self.onCardScanned = onCardScanned
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
   
    public func makeUIViewController(context: Context) -> CardScannerController {
        let scanner = CardScannerController(configuration: configuration)
        scanner.firstNameSuggestion = firstNameSuggestion
        scanner.lastNameSuggestion = lastNameSuggestion
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: CardScannerController, context: Context) { }
    
    public class Coordinator: NSObject, CardScannerDelegate {

        private let parent: CardScanner
        
        init(_ parent: CardScanner) {
            self.parent = parent
        }
        
        func didTapCancel() {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func didTapDone(number: String?, expDate: String?, holder: String?) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCardScanned(number, expDate, holder)
        }
        
        func didScanCard(number: String?, expDate: String?, holder: String?) { }
    }
}

struct CardScanner_Previews: PreviewProvider {
    static var previews: some View {
        CardScanner()
    }
}
