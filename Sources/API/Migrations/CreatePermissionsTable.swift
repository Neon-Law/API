import FluentSQLiteDriver

struct CreatePermissionsTable: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("permissions")
            .id()
            .field("user_sub", .string, .required)
            .field("resource", .string, .required)
            .field("action", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("permissions").delete()
    }
}
