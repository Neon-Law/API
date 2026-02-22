import Hummingbird

protocol AuthenticatedRequestContext: RequestContext {
    var cognitoUser: CognitoUser? { get set }
}

struct APIRequestContext: AuthenticatedRequestContext {
    var coreContext: CoreRequestContextStorage
    var cognitoUser: CognitoUser?

    init(source: Source) {
        self.coreContext = .init(source: source)
        self.cognitoUser = nil
    }
}
