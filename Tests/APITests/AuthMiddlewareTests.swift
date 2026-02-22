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

    @Test("returns 403 when customer token hits admin-only route")
    func testAnonymousIsForbidden() async throws {
        try await withTestFluent { fluent in
            let keys = await TestJWT.buildKeyCollection()
            let token = try await TestJWT.mint(sub: "customer-user", email: "customer@example.com")
            let app = buildAuthTestApplication(keys: keys, fluent: fluent, minimumRole: .admin)
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

    @Test("returns 200 when customer token hits customer-level route")
    func testAuthorizedAccess() async throws {
        try await withTestFluent { fluent in
            let keys = await TestJWT.buildKeyCollection()
            let token = try await TestJWT.mint(sub: "authorized-test-sub")
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

    @Test("returns 200 when admin token hits admin-only route")
    func testAdminAccess() async throws {
        try await withTestFluent { fluent in
            let keys = await TestJWT.buildKeyCollection()
            let token = try await TestJWT.mint(
                sub: "admin-user-sub",
                email: "lawyer@neonlaw.com"
            )
            let app = buildAuthTestApplication(keys: keys, fluent: fluent, minimumRole: .admin)
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
    fluent: Fluent,
    minimumRole: Role = .customer
) -> some ApplicationProtocol {
    let router = Router(context: APIRequestContext.self)
    router.add(middleware: CognitoAuthMiddleware(keys: keys, fluent: fluent))
    router.add(middleware: AuthorizationMiddleware(minimumRole: minimumRole))
    router.get("ping") { _, _ in "pong" }
    return Application(router: router)
}
