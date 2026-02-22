import FluentSQLiteDriver

struct CreateRolesTable: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("roles")
            .id()
            .field("name", .string, .required)
            .unique(on: "name")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("roles").delete()
    }
}
