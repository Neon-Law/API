import FluentPostgresDriver
import FluentSQLiteDriver
import Foundation
import HummingbirdFluent
import Logging

func buildDatabase(env: String) async throws -> Fluent {
    let logger = Logger(label: "fluent")
    let fluent = Fluent(logger: logger)

    switch env {
    case "production", "staging":
        let databaseURL = ProcessInfo.processInfo.environment["DATABASE_URL"] ?? ""
        fluent.databases.use(try .postgres(url: databaseURL), as: .psql)
    case "test":
        if let databaseURL = ProcessInfo.processInfo.environment["DATABASE_URL"] {
            fluent.databases.use(try .postgres(url: databaseURL), as: .psql)
        } else {
            fluent.databases.use(.sqlite(.memory), as: .sqlite)
        }
    default:
        fluent.databases.use(.sqlite(.memory), as: .sqlite)
    }

    await fluent.migrations.add(
        CreateUsersTable(),
        CreateRolesTable(),
        CreateUserRolesTable(),
        CreatePermissionsTable(),
        CreateDocumentsTable()
    )

    return fluent
}
