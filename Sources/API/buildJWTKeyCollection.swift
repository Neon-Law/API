import Foundation
import JWTKit

func buildJWTKeyCollection() async throws -> JWTKeyCollection {
    let env = ProcessInfo.processInfo.environment
    let issuerOverride = env["JWT_ISSUER_OVERRIDE"]
    let region = env["COGNITO_REGION"] ?? "us-west-2"
    let userPoolId = env["COGNITO_USER_POOL_ID"] ?? ""

    let keys = JWTKeyCollection()

    guard !userPoolId.isEmpty else {
        return keys
    }

    let base = issuerOverride ?? "https://cognito-idp.\(region).amazonaws.com"
    guard let jwksURL = URL(string: "\(base)/\(userPoolId)/.well-known/jwks.json") else {
        return keys
    }

    let (data, _) = try await URLSession.shared.data(from: jwksURL)
    try await keys.add(jwksJSON: String(decoding: data, as: UTF8.self))
    return keys
}
