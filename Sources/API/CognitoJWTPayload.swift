import JWTKit

struct CognitoJWTPayload: JWTPayload {
    var sub: SubjectClaim
    var email: String?
    var cognitoGroups: [String]?
    var tokenUse: String
    var exp: ExpirationClaim

    enum CodingKeys: String, CodingKey {
        case sub
        case email
        case cognitoGroups = "cognito:groups"
        case tokenUse = "token_use"
        case exp
    }

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
        guard tokenUse == "access" else {
            throw JWTError.claimVerificationFailure(
                failedClaim: nil,
                reason: "token_use must be access"
            )
        }
    }
}
