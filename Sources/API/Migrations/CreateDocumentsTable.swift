import FluentSQLiteDriver

struct CreateDocumentsTable: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("documents")
            .id()
            .field("name", .string, .required)
            .field("matter_name", .string, .required)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("documents").delete()
    }
}
