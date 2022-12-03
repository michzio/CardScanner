import Foundation

public struct CardValidationType {
    public let group: CardGroup
    public let regex: String

    public init(group: CardGroup, regex: String) {
        self.group = group
        self.regex = regex
    }
}

extension CardValidationType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.group == rhs.group
    }
}
