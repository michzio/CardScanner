import Foundation
import NaturalLanguage

// MARK: - Card Number
extension String {
    
    func checkCardNumber() -> String? {
        let cardValidator = CardValidator()
        guard
            cardValidator.validationType(from: self) != nil,
            cardValidator.validateWithLuhnAlgorithm(cardNumber: self)
        else {
            return nil
        }
        return sanitizedNumericString
    }
    
    func extractCardNumber() -> String? {
        
        print("Extracting number from: \(self)")
        
        let pattern = "(\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4})|(\\d{4}\\s?\\d{6}\\s?\\d{5})|(\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{2})"
        
        guard let range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) else {
            // No exp date found.
            return nil
        }
        
        let potentialNumber = String(self[range])

        let cardValidator = CardValidator()
        guard
            cardValidator.validationType(from: potentialNumber) != nil,
            cardValidator.validateWithLuhnAlgorithm(cardNumber: potentialNumber)
        else {
            return nil
        }
        return potentialNumber.sanitizedNumericString
    }
}

// MARK: - Exp Date
extension String {
    func extractExpDate() -> String? {
        let pattern = "(0[1-9]|1[0-2])\\/([0-9]{4}|[0-9]{2})"
        
        guard let range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) else {
            // No exp date found.
            return nil
        }
        
        let expDate = String(self[range])
        return expDate
    }
}

// MARK: - Full Name
extension String {
    
    func checkOccurance(of string: String) -> Bool {
        self.lowercased().contains(string.lowercased())
    }
    
    func checkFullName(firstName: String, lastName: String) -> String? {
        
        guard !firstName.isEmpty || !lastName.isEmpty else { return nil }
        
        var fullName = ""
        
        if self.checkOccurance(of: firstName) {
            fullName += firstName.uppercased() + " "
        }
        if self.checkOccurance(of: lastName) {
            fullName += lastName.uppercased()
        }
        
        fullName = fullName.trimmLeadingAndTrailing()
        
        if fullName.isEmpty {
            return nil
        }
        
        return fullName
    }
    
    enum NameType {
        case personal
        case company
    }
    
    func extractNames() -> [NameType : [String]] {
        
        print("Name extracting: \(self)")
        
        let text = self
        let range = text.startIndex..<text.endIndex
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        tagger.setLanguage(.english, range: range)
        
        // personalName & organization names
        var personalNames = [String]()
        var companyNames = [String]()
        
        let options : NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            
            if tag == .personalName {
                let name = text[tokenRange]
                personalNames.append(String(name))
            } else if tag == .organizationName {
                let name = text[tokenRange]
                companyNames.append(String(name))
            }
            return true
        }
        
        var result = [NameType : [String]]()
        if !personalNames.isEmpty {
            result[.personal] = personalNames
        }
        if !companyNames.isEmpty {
            result[.company] = companyNames
        }
        return result
    }
    
    func extractCardHolder2() -> String? {
        
        print("Card Holder extracting: \(self)")
        
        let brands = [
            "American Express", "Diners Club", "Discover", "JCB", "Mastercard", "UnionPay",
            "Visa", "Debit", "Credit", "Card", "Bank", "Valid", "Thru", "Good", "Month", "Year", "Business",
        ]
        let brandsRegex = brands.joined(separator: "|")
        
        // - removing card number digits, exp date digits and "/" character
        // as this breaks NSLinguisticTagger from classifying names correctly
        // - remove card brands
        // - remove excessive whitespaces
        var text = self.components(separatedBy: CharacterSet.decimalDigits).joined()
        text = text.replacingOccurrences(of: brandsRegex, with: "", options: [.caseInsensitive, .regularExpression])
        text = text.replacingOccurrences(of: "  ", with: " ")
        
        let range = text.startIndex..<text.endIndex
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        tagger.setLanguage(.english, range: range)
        
        var personalNames = [String]()
        
        // personalName
        let options : NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        let foundTags = tagger.tags(in: range, unit: .word, scheme: .nameType, options: options)
        
        foundTags.forEach { tag, tokenRange in
            if tag == .personalName {
                let name = text[tokenRange]
                personalNames.append(String(name))
            }
        }
        
        print("Dominant Language: \(tagger.dominantLanguage.debugDescription)")
        print("Full name: \(personalNames.first ?? "nil")")
        
        if personalNames.count > 1 {
            return personalNames.joined(separator: " ")
        }
        
        if let name = personalNames.first {
            let components = name.components(separatedBy: .whitespaces)
            if components.count > 1 {
                return name
            } else {
                let words = text.components(separatedBy: .whitespaces)
                if let idx = words.firstIndex(where: { $0 == name }), words.count > (idx + 1) {
                    let last = words[idx + 1]
                    if last.count < 3, words.count > (idx + 2) {
                        return "\(name) \(words[idx + 1]) \(words[idx + 2])"
                    } else {
                        return "\(name) \(words[idx + 1])"
                    }
                }
            }
        }
        
        return personalNames.first
    }
    
    func extractCardHolder() -> String? {
        
        print("Card Holder extracting: \(self)")
        
        let brands = [
            "American Express", "Diners Club", "Discover", "JCB", "Mastercard",
            "UnionPay", "Visa", "Debit", "Credit", "Card", "Bank"
        ]
        let brandsRegex = brands.joined(separator: "|")
        
        // - removing card number digits, exp date digits and "/" character
        // as this breaks NSLinguisticTagger from classifying names correctly
        // - remove card brands
        // - remove excessive whitespaces
        var text = self.components(separatedBy: CharacterSet.decimalDigits).joined()
        text = text.replacingOccurrences(of: brandsRegex, with: "", options: [.caseInsensitive, .regularExpression])
        text = text.replacingOccurrences(of: "  ", with: " ")
        
        let range = NSRange(location: 0, length: text.utf16.count)
    
        let tagger = NSLinguisticTagger(tagSchemes: [.nameType], options: 0)
        tagger.string = text
        tagger.setOrthography(NSOrthography.defaultOrthography(forLanguage: "en-US"), range: range)
        
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitOther, .joinNames]
        let tags: [NSLinguisticTag] = [.personalName]
        
        var personalNames = [String]()
        
        /*
        // this is asynchronous, we prefere to retrieve classification tags synchronously
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { (tag, tokenRange, stop) in
            if let tag = tag, tags.contains(tag) {
                if let range = Range(tokenRange, in: text) {
                    let name = text[range]
                    print("Name: \(name): \(tag)")
                }
            }
        }*/
        
        var tokenRanges: NSArray?
        let foundTags = tagger.tags(in: range, unit: .word, scheme: .nameType, options: options, tokenRanges: &tokenRanges)
        
        if let tokenRanges = tokenRanges {
            foundTags.enumerated().forEach { i, tag in
                if tags.contains(tag), let nsrange = tokenRanges[i] as? NSRange {
                    if let range = Range(nsrange, in: text) {
                        let name = text[range]
                        personalNames.append(String(name))
                    }
                }
            }
        }
        
        print("Dominant Language: \(tagger.dominantLanguage ?? "nil")")
        print("Full name: \(personalNames.first ?? "nil")")
        return personalNames.first
    }
}

// MARK: - Phone Number
extension String {
    // Extracts the first US-style phone number found in the string, returning
    // the range of the number and the number itself as a tuple.
    // Returns nil if no number is found.
    func extractPhoneNumber() -> (Range<String.Index>, String)? {
        // Do a first pass to find any substring that could be a US phone
        // number. This will match the following common patterns and more:
        // xxx-xxx-xxxx
        // xxx xxx xxxx
        // (xxx) xxx-xxxx
        // (xxx)xxx-xxxx
        // xxx.xxx.xxxx
        // xxx xxx-xxxx
        // xxx/xxx.xxxx
        // +1-xxx-xxx-xxxx
        // Note that this doesn't only look for digits since some digits look
        // very similar to letters. This is handled later.
        let pattern = #"""
        (?x)                    # Verbose regex, allows comments
        (?:\+1-?)?                # Potential international prefix, may have -
        [(]?                    # Potential opening (
        \b(\w{3})                # Capture xxx
        [)]?                    # Potential closing )
        [\ -./]?                # Potential separator
        (\w{3})                    # Capture xxx
        [\ -./]?                # Potential separator
        (\w{4})\b                # Capture xxxx
        """#
        
        guard let range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) else {
            // No phone number found.
            return nil
        }
        
        // Potential number found. Strip out punctuation, whitespace and country
        // prefix.
        var phoneNumberDigits = ""
        let substring = String(self[range])
        let nsrange = NSRange(substring.startIndex..., in: substring)
        do {
            // Extract the characters from the substring.
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            if let match = regex.firstMatch(in: substring, options: [], range: nsrange) {
                for rangeInd in 1 ..< match.numberOfRanges {
                    let range = match.range(at: rangeInd)
                    let matchString = (substring as NSString).substring(with: range)
                    phoneNumberDigits += matchString as String
                }
            }
        } catch {
            print("Error \(error) when creating pattern")
        }
        
        // Must be exactly 10 digits.
        guard phoneNumberDigits.count == 10 else {
            return nil
        }
        
        // Substitute commonly misrecognized characters, for example: 'S' -> '5' or 'l' -> '1'
        var result = ""
        let allowedChars = "0123456789"
        for var char in phoneNumberDigits {
            char = char.getSimilarCharacterIfNotIn(allowedChars: allowedChars)
            guard allowedChars.contains(char) else {
                return nil
            }
            result.append(char)
        }
        return (range, result)
    }
}

extension String {
    var sanitizedNumericString: String {
        stringByRemovingCharactersFromSet(CharacterSet.asciiDigit.inverted)
    }
    
    func stringByRemovingCharactersFromSet(_ characterSet: CharacterSet) -> String {
        let filtered = unicodeScalars.filter { !characterSet.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
    
    func trimmLeadingAndTrailing() -> String {
        let pattern = "(?:^\\s+)|(?:\\s+$)"
        return filter(with: pattern)
    }
    
    func filter(with pattern : String) -> String {
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            
            let range = NSRange(location: 0, length: self.count)
            let filteredString = regex.stringByReplacingMatches(in: self, options: .reportProgress, range: range, withTemplate: "")
            return filteredString
        }
        
        return self
    }
}

extension Character {
    // Given a list of allowed characters, try to convert self to those in list
    // if not already in it. This handles some common misclassifications for
    // characters that are visually similar and can only be correctly recognized
    // with more context and/or domain knowledge. Some examples (should be read
    // in Menlo or some other font that has different symbols for all characters):
    // 1 and l are the same character in Times New Roman
    // I and l are the same character in Helvetica
    // 0 and O are extremely similar in many fonts
    // oO, wW, cC, sS, pP and others only differ by size in many fonts
    func getSimilarCharacterIfNotIn(allowedChars: String) -> Character {
        let conversionTable = [
            "s": "S",
            "S": "5",
            "5": "S",
            "o": "O",
            "Q": "O",
            "O": "0",
            "0": "O",
            "l": "I",
            "I": "1",
            "1": "I",
            "B": "8",
            "8": "B",
        ]
        // Allow a maximum of two substitutions to handle 's' -> 'S' -> '5'.
        let maxSubstitutions = 2
        var current = String(self)
        var counter = 0
        while !allowedChars.contains(current) && counter < maxSubstitutions {
            if let altChar = conversionTable[current] {
                current = altChar
                counter += 1
            } else {
                // Doesn't match anything in our table. Give up.
                break
            }
        }
        
        return current.first ?? .init("")
    }
}

extension CharacterSet {
    static let asciiDigit = CharacterSet(charactersIn: "0123456789")
}
