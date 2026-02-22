import AWSLambdaEvents
import Hummingbird
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
        let codeCommitService = CodeCommitService()
        try await codeCommitService.connect()

        let keys = try await buildJWTKeyCollection()
        let router = Router(context: LambdaAPIRequestContext.self)
        router.add(middleware: CognitoAuthMiddleware(keys: keys))

        let api = APIImpl(codeCommitService: codeCommitService)
        try api.registerHandlers(on: router, serverURL: try Servers.Server1.url())

        let lambda = APIGatewayV2LambdaFunction(router: router)
        try await lambda.runService()
    }
}
