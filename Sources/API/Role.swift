enum Role: String, Codable, Sendable {
    case admin
    case customer
    case anonymous

    static func forEmail(_ email: String?) -> Role {
        guard let email else { return .customer }
        if email.hasSuffix("@neonlaw.com") || email.hasSuffix("@sagebrush.services") {
            return .admin
        }
        return .customer
    }

    func satisfies(_ minimum: Role) -> Bool {
        switch minimum {
        case .anonymous: return true
        case .customer: return self == .customer || self == .admin
        case .admin: return self == .admin
        }
    }
}
