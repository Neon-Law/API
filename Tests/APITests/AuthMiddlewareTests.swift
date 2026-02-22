import Foundation
import Hummingbird
import HummingbirdFluent
import HummingbirdTesting
import JWTKit
import Testing

@testable import API

@Suite("Auth Middleware Tests")
struct AuthMiddlewareTests {
    @Test("returns 401 when Authorization header is missing")
    func testMissingToken() async throws {
        try await withTestFluent { fluent in
            let keys = await TestJWT.buildKeyCollection()
            let app = buildAuthTestApplication(keys: keys, fluent: fluent)
            try await app.test(.router) { client in
                try await client.execute(uri: "/ping", method: .get) { response in
                    #expect(response.status == .unauthorized)
                }
            }
        }
    }

    @Test("returns 401 when Bearer token is malformed")
    func testMalformedToken() async throws {
        try await withTestFluent { fluent in
            let keys = await TestJWT.buildKeyCollection()
            let app = buildAuthTestApplication(keys: keys, fluent: fluent)
            try await app.test(.router) { client in
                try await client.execute(
                    uri: "/ping",
                    method: .get,
                    headers: [.authorization: "Bearer not.a.valid.jwt"]
                ) { response in
                    #expect(response.status == .unauthorized)
                }
            }
        }
    }

    @Test("returns 403 when token is valid but user has no permission")
    func testForbiddenWithoutPermission() async throws {
        try await withTestFluent { fluent in
            let keys = await TestJWT.buildKeyCollection()
            let token = try await TestJWT.mint(sub: "user-without-permission")
            let app = buildAuthTestApplication(keys: keys, fluent: fluent)
            try await app.test(.router) { client in
                try await client.execute(
                    uri: "/ping",
                    method: .get,
                    headers: [.authorization: "Bearer \(token)"]
                ) { response in
                    #expect(response.status == .forbidden)
                }
            }
        }
    }

    @Test("returns 200 when token is valid and permission is granted")
    func testAuthorizedAccess() async throws {
        try await withTestFluent { fluent in
            let keys = await TestJWT.buildKeyCollection()
            let sub = "authorized-test-sub"
            let permission = Permission(userSub: sub, resource: "matters", action: "read")
            try await permission.create(on: fluent.db())
            let token = try await TestJWT.mint(sub: sub)
            let app = buildAuthTestApplication(keys: keys, fluent: fluent)
            try await app.test(.router) { client in
                try await client.execute(
                    uri: "/ping",
                    method: .get,
                    headers: [.authorization: "Bearer \(token)"]
                ) { response in
                    #expect(response.status == .ok)
                }
            }
        }
    }
}

private func withTestFluent<T: Sendable>(
    _ body: (Fluent) async throws -> T
) async throws -> T {
    let fluent = try await buildDatabase(env: "local")
    try await fluent.migrate()
    do {
        let result = try await body(fluent)
        try await fluent.shutdown()
        return result
    } catch {
        try? await fluent.shutdown()
        throw error
    }
}

private func buildAuthTestApplication(
    keys: JWTKeyCollection,
    fluent: Fluent
) -> some ApplicationProtocol {
    let router = Router(context: APIRequestContext.self)
    router.add(middleware: CognitoAuthMiddleware(keys: keys))
    router.add(
        middleware: AuthorizationMiddleware(
            fluent: fluent,
            resource: "matters",
            action: "read"
        )
    )
    router.get("ping") { _, _ in "pong" }
    return Application(router: router)
}
