extension CardValidationType {
    static let typesInCorrectCheckOrder: [CardValidationType] = [
        /*
            These rules must be in the order below, because some definitions are wider than others.
            E.g. Elo card number might be included in Mastercard numbers definitions (as it might be only a subset of MC numbers.
        */

        // .bcmc, NOT USED, NO RULES SET FOR THIS TYPE
        .americanExpress,

        .visaAlphaBankBonus,
        .visaDankort,
        .visa,

        .elo,

        .masterCardBijenkorf,
        .masterCardAlphaBankBonus,
        .masterCard,

        .dinersClub,
        .discover,
        .jcb,
        .unionPay,
        .hiperCard,

        .bancontact,
        .solo,
        .dankort,
        .uatp,
        .chinaUnionPay,
        .codensa,
        .hiper,
        .oasis,
        .karenMillen,
        .warehouse,
        .mir,
        .maestroUK,
        .maestro,
        .cartebancaire,
    ]

    static let americanExpress = CardValidationType(group: .amex, regex: "^3[47][0-9]{0,13}$")
    static let bancontact = CardValidationType(group: .bancontact, regex: "^((6703)[0-9]{0,15}|(479658|606005)[0-9]{0,13})$")

    /* static let bcmc = CardValidationType(group: .bcmc, regex: "" //NO RULES SET) */

    static let cartebancaire = CardValidationType(group: .cartebancaire, regex: "^[4-6][0-9]{3,15}$")
    static let chinaUnionPay = CardValidationType(group: .chinaUnionPay, regex: "^(62)[0-9]{0,17}$")
    static let codensa = CardValidationType(group: .codensa, regex: "^(590712)[0-9]{0,10}$")
    static let dankort = CardValidationType(group: .dankort, regex: "^(5019)[0-9]{0,12}$")
    static let dinersClub = CardValidationType(group: .diners, regex: "^((30)[0123459][0-9]{0,11}|(3)[689][0-9]{0,12})$")

    // see https://www.discoverglobalnetwork.com/downloads/IPP_VAR_Compliance.pdf
    static let discover = CardValidationType(group: .discover, regex: "^((6011)[0-9]{0,12}|(64)[4-9][0-9]{0,13}|(65)[0-9]{0,14})$")

    static let elo = CardValidationType(group: .elo, regex: """
^(\
(506699|5067[0-6][0-9]|50677[0-8])[0-9]{0,12}|\
(509[0-8][0-9]{2}|5099[0-8][0-9]|50999[0-9])[0-9]{0,12}|\
(65003[1-3])[0-9]{0,12}|\
(65003[5-9]|65004[0-9]|65005[01])[0-9]{0,12}|\
(65040[5-9]|6504[1-3][0-9])[0-9]{0,12}|\
(65048[5-9]|65049[0-9]|6505[0-2][0-9]|65053[0-8])[0-9]{0,12}|\
(65054[1-9]|6505[5-8][0-9]|65059[0-8])[0-9]{0,12}|\
(65070[0-9]|65071[0-8])[0-9]{0,12}|\
(65072[0-7])[0-9]{0,12}|\
(65090[1-9]|6509[1-6][0-9]|65097[0-8])[0-9]{0,12}|\
(65165[2-9]|6516[67][0-9])[0-9]{0,12}|\
(65500[0-9]|65501[0-9])[0-9]{0,12}|\
(65502[1-9]|6550[34][0-9]|65505[0-8])[0-9]{0,12}|\
(401178|401179|438935|457631|457632|431274|451416|457393|504175|627780|636297|636368)[0-9]{0,12}\
)$
"""
    )

    static let hiper = CardValidationType(group: .hiper, regex: "^(637095|637568|637599|637609|637612)[0-9]{0,10}$")
    static let hiperCard = CardValidationType(group: .hiperCard, regex: "^(606282)[0-9]{0,10}$")
    static let jcb = CardValidationType(group: .jcb, regex: "^((352[89]|35[3-8][0-9])[0-9]{0,12}|(2131)[0-9]{0,19}|(1800)[0-9]{0,19})$")
    static let karenMillen = CardValidationType(group: .karenMillen, regex: "^(98261465)[0-9]{0,8}$")
    static let maestro = CardValidationType(group: .maestro, regex: "^(5[6-8][0-9]{0,17}|6[0-9]{0,18})$")
    static let maestroUK = CardValidationType(group: .maestroUK, regex: "^(6759)[0-9]{0,15}$")

    // https://www.mastercard.us/content/dam/mccom/global/documents/mastercard-rules.pdf
    static let masterCard = CardValidationType(
        group: .masterCard,
        regex: "^(5[1-5][0-9]{5,}|(222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{0,12})$"
    )

    static let masterCardAlphaBankBonus = CardValidationType(group: .masterCardAlphaBankBonus, regex: "^(510099)[0-9]{0,10}$")
    static let masterCardBijenkorf = CardValidationType(group: .masterCardBijenkorf, regex: "^(5100081)[0-9]{0,9}$")
    static let mir = CardValidationType(group: .mir, regex: "^(220)[0-9]{0,16}$")
    static let oasis = CardValidationType(group: .oasis, regex: "^(982616)[0-9]{0,10}$")
    static let solo = CardValidationType(group: .solo, regex: "^(6767)[0-9]{0,15}$")
    static let uatp = CardValidationType(group: .uatp, regex: "^1[0-9]{0,14}$")

    // For Union Pay by Discover https://www.discoverglobalnetwork.com/downloads/IPP_VAR_Compliance.pdf
    static let unionPay = CardValidationType(group: CardGroup.unionPay, regex: "^(62|81)[0-9]{0,}$")
    static let visa = CardValidationType(group: .visa, regex: "^4[0-9]{0,16}$")
    static let visaAlphaBankBonus = CardValidationType(group: .visaAlphaBankBonus, regex: "^(450903)[0-9]{0,10}$")
    static let visaDankort = CardValidationType(group: .visaDankort, regex: "^(4571)[0-9]{0,12}$")
    static let warehouse = CardValidationType(group: .warehouse, regex: "^(982633)[0-9]{0,10}$")
}
