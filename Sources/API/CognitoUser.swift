struct CognitoUser: Sendable {
    let sub: String
    let email: String?
    let groups: [String]
    let role: Role
}
