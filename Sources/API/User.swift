import FluentSQLiteDriver
import Foundation

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(custom: .id, generatedBy: .database) var id: Int?
    @Field(key: "sub") var sub: String
    @Field(key: "email") var email: String
    @Field(key: "role") var role: Role
    @Timestamp(key: "inserted_at", on: .create) var insertedAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(sub: String, email: String, role: Role) {
        self.sub = sub
        self.email = email
        self.role = role
    }
}
