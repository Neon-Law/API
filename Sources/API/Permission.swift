import FluentSQLiteDriver
import Foundation

final class Permission: Model, @unchecked Sendable {
    static let schema = "permissions"

    @ID(key: .id) var id: UUID?
    @Field(key: "user_sub") var userSub: String
    @Field(key: "resource") var resource: String
    @Field(key: "action") var action: String

    init() {}

    init(id: UUID? = nil, userSub: String, resource: String, action: String) {
        self.id = id
        self.userSub = userSub
        self.resource = resource
        self.action = action
    }
}
