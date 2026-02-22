import Foundation
import Hummingbird
import HummingbirdFluent
import OpenAPIHummingbird
import OpenAPIRuntime

struct APILocalServer {
    static func run() async throws {
        let env = ProcessInfo.processInfo.environment["ENV"] ?? "local"

        let codeCommitService = CodeCommitService()
        try await codeCommitService.connect()

        let keys = try await buildJWTKeyCollection()
        let fluent = try await buildDatabase(env: env)
        try await fluent.migrate()
        let api = APIImpl(codeCommitService: codeCommitService)

        let router = Router(context: APIRequestContext.self)
        router.add(middleware: CognitoAuthMiddleware(keys: keys))
        router.add(
            middleware: AuthorizationMiddleware(
                fluent: fluent,
                resource: "matters",
                action: "read"
            )
        )
        try api.registerHandlers(on: router, serverURL: try Servers.Server1.url())

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 8080)),
            services: [fluent],
            onServerRunning: { _ in
                print("NeonLaw API running on http://127.0.0.1:8080")
            }
        )

        try await app.runService()
        try await codeCommitService.shutdown()
    }
}
