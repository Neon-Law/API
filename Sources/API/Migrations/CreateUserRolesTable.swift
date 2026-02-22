import FluentSQLiteDriver

struct CreateUserRolesTable: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user_roles")
            .id()
            .field("user_id", .uuid, .required)
            .field("role_id", .uuid, .required)
            .foreignKey("user_id", references: "users", .id, onDelete: .cascade)
            .foreignKey("role_id", references: "roles", .id, onDelete: .cascade)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_roles").delete()
    }
}
