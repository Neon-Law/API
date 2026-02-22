import Hummingbird

struct AuthorizationMiddleware<Context: AuthenticatedRequestContext>: RouterMiddleware {
    let minimumRole: Role

    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard let user = context.cognitoUser else {
            throw HTTPError(.unauthorized)
        }
        guard user.role.satisfies(minimumRole) else {
            throw HTTPError(.forbidden)
        }
        return try await next(request, context)
    }
}
