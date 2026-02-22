import Foundation
import JWTKit

@testable import API

enum TestJWT {
    static let secret = "test-only-hmac-secret-minimum-256-bits-long!!"

    static func buildKeyCollection() async -> JWTKeyCollection {
        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: secret), digestAlgorithm: .sha256)
        return keys
    }

    static func mint(
        sub: String = "test-user-sub",
        email: String? = "test@example.com",
        groups: [String] = [],
        expiresIn: TimeInterval = 3600
    ) async throws -> String {
        let keys = await buildKeyCollection()
        let payload = CognitoJWTPayload(
            sub: SubjectClaim(value: sub),
            email: email,
            cognitoGroups: groups.isEmpty ? nil : groups,
            tokenUse: "access",
            exp: ExpirationClaim(value: Date().addingTimeInterval(expiresIn))
        )
        return try await keys.sign(payload)
    }
}
