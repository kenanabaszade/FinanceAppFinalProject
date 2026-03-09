import Foundation

enum OnboardingRoute {
    case welcome
    case login
    case signup
    case emailVerification(email: String)
    case personalInfo
    case compliance
    case completionCheck
    case main
    case mandarinPrices
    case cardDetail(card: Card)
    case addCard
    case sendMoney
    case requestMoneyRecipients
    case enterAmount(recipient: SendMoneyRecipient)
    case requestMoneyEnterAmount(recipient: SendMoneyRecipient)
    case acceptTransfer(requestId: String)
    case notificationsCenter
    case logout
}
