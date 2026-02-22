import Hummingbird
import JWTKit

struct CognitoAuthMiddleware<Context: AuthenticatedRequestContext>: RouterMiddleware {
    let keys: JWTKeyCollection

    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard let authorization = request.headers[.authorization],
            authorization.lowercased().hasPrefix("bearer ")
        else {
            throw HTTPError(.unauthorized)
        }
        let token = String(authorization.dropFirst(7))
        let payload = try await keys.verify(token, as: CognitoJWTPayload.self)
        var context = context
        context.cognitoUser = CognitoUser(
            sub: payload.sub.value,
            email: payload.email,
            groups: payload.cognitoGroups ?? []
        )
        return try await next(request, context)
    }
}
