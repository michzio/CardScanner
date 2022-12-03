import SwiftUI

public enum CardGroup: String, Decodable {
    case amex = "AMEX"
    case bancontact
    case bcmc = "BCMC"
    case cartebancaire = "CARTEBANCAIRE"
    case chinaUnionPay
    case cup
    case codensa
    case dankort
    case diners = "DINERS"
    case discover = "DISCOVER"
    case elo
    case hiper
    case hiperCard
    case jcb = "JCB"
    case karenMillen
    case maestro
    case maestroUK
    case masterCard = "MASTER_CARD"
    case masterCardAlphaBankBonus
    case masterCardBijenkorf
    case mir
    case oasis
    case solo
    case uatp
    case unionPay
    case visa = "VISA"
    case visaAlphaBankBonus
    case visaDankort
    case warehouse

    case other = "OTHER"

    public var isBCMCCard: Bool {
        self == .bcmc || self == .bancontact
    }
}
