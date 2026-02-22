import Hummingbird
import HummingbirdFluent

struct AuthorizationMiddleware<Context: AuthenticatedRequestContext>: RouterMiddleware {
    let fluent: Fluent
    let resource: String
    let action: String

    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard let user = context.cognitoUser else {
            throw HTTPError(.unauthorized)
        }
        let permitted =
            try await Permission.query(on: fluent.db())
            .filter(\Permission.$userSub, .equal, user.sub)
            .filter(\Permission.$resource, .equal, resource)
            .filter(\Permission.$action, .equal, action)
            .first() != nil
        guard permitted else {
            throw HTTPError(.forbidden)
        }
        return try await next(request, context)
    }
}
