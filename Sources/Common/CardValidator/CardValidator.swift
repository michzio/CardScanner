import Foundation

public class CardValidator {

    private var validationTypes: [CardValidationType] {
        CardValidationType.typesInCorrectCheckOrder
    }

    private let minimumCardNumberLength = 9

    public init() {}
    
    /**
    Get card type from string
    - parameter string: card number string
    - returns: CreditCardValidationType structure
    */
    public func validationType(from string: String) -> CardValidationType? {
        let numbersString = getOnlyDigits(fromText: string)
        for type in validationTypes {
            let predicate = NSPredicate(format: "SELF MATCHES %@", type.regex)
            if predicate.evaluate(with: numbersString) {
                return type
            }
        }
        return nil
    }
    
    /**
    Validate card number
    - parameter string: card number string
    - returns: true or false
    */
    public func validateWithLuhnAlgorithm(cardNumber: String) -> Bool {
        let cardNumberDigits = getOnlyDigits(fromText: cardNumber)
        guard cardNumberDigits.count >= minimumCardNumberLength else { return false }

        let reversedDigits = String(cardNumberDigits.reversed())
        var oddSum = 0, evenSum = 0

        for (index, digitAsString) in reversedDigits.enumerated() {
            guard let digit = Int(String(digitAsString)) else { return false }

            if index.isMultiple(of: 2) {
                evenSum += digit
            } else {
                oddSum += digit / 5 + (2 * digit) % 10
            }
        }
        return (oddSum + evenSum).isMultiple(of: 10)
    }
    
    /**
    Validate card number string for type
    - parameter string: card number string
    - parameter type:   CreditCardValidationType structure
    - returns: true or false
    */
    public func validate(cardNumber: String, forType type: CardValidationType) -> Bool {
        validationType(from: cardNumber) == type
    }

    // MARK: - Private

    private func getOnlyDigits(fromText text: String) -> String {
        text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}
