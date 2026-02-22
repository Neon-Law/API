import AWSLambdaEvents
import Hummingbird
import HummingbirdLambda
import OpenAPIHummingbird

struct APILambda {
    static func run() async throws {
        let codeCommitService = CodeCommitService()
        try await codeCommitService.connect()

        let router = Router(context: BasicLambdaRequestContext<APIGatewayV2Request>.self)
        let api = APIImpl(codeCommitService: codeCommitService)
        try api.registerHandlers(on: router, serverURL: try Servers.Server1.url())

        let lambda = APIGatewayV2LambdaFunction(router: router)
        try await lambda.runService()
    }
}
