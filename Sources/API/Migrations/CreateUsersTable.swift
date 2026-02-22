import FluentSQLiteDriver

struct CreateUsersTable: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("sub", .string, .required)
            .field("email", .string, .required)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime)
            .unique(on: "sub")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}
