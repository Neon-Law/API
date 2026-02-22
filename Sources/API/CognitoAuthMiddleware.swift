import Hummingbird
import HummingbirdFluent
import JWTKit

struct CognitoAuthMiddleware<Context: AuthenticatedRequestContext>: RouterMiddleware {
    let keys: JWTKeyCollection
    let fluent: Fluent

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
        let payload: CognitoJWTPayload
        do {
            payload = try await keys.verify(token, as: CognitoJWTPayload.self)
        } catch {
            throw HTTPError(.unauthorized)
        }
        let user = try await findOrCreate(payload: payload)
        var context = context
        context.cognitoUser = CognitoUser(
            sub: payload.sub.value,
            email: payload.email,
            groups: payload.cognitoGroups ?? [],
            role: user.role
        )
        return try await next(request, context)
    }

    private func findOrCreate(payload: CognitoJWTPayload) async throws -> User {
        let db = fluent.db()
        if let existing = try await User.query(on: db)
            .filter(\User.$sub, .equal, payload.sub.value)
            .first()
        {
            return existing
        }
        let user = User(
            sub: payload.sub.value,
            email: payload.email ?? "",
            role: Role.forEmail(payload.email)
        )
        try await user.create(on: db)
        return user
    }
}
