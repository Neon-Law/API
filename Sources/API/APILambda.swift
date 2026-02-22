import AWSLambdaEvents
import Foundation
import Hummingbird
import HummingbirdFluent
import HummingbirdLambda
import OpenAPIHummingbird

struct LambdaAPIRequestContext: AuthenticatedRequestContext, LambdaRequestContext {
    typealias Event = APIGatewayV2Request

    var coreContext: CoreRequestContextStorage
    var event: APIGatewayV2Request
    var cognitoUser: CognitoUser?

    init(source: LambdaRequestContextSource<APIGatewayV2Request>) {
        self.coreContext = .init(source: source)
        self.event = source.event
        self.cognitoUser = nil
    }
}

struct APILambda {
    static func run() async throws {
        let env = ProcessInfo.processInfo.environment["ENV"] ?? "production"

        let codeCommitService = CodeCommitService()
        try await codeCommitService.connect()

        let keys = try await buildJWTKeyCollection()
        let fluent = try buildDatabase(env: env)
        let router = Router(context: LambdaAPIRequestContext.self)
        router.add(middleware: CognitoAuthMiddleware(keys: keys))
        router.add(
            middleware: AuthorizationMiddleware(
                fluent: fluent,
                resource: "matters",
                action: "read"
            )
        )

        let api = APIImpl(codeCommitService: codeCommitService)
        try api.registerHandlers(on: router, serverURL: try Servers.Server1.url())

        let lambda = APIGatewayV2LambdaFunction(router: router, services: [fluent])
        try await lambda.runService()
    }
}
