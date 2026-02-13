import Foundation
import Hummingbird
import HummingbirdTesting
import OpenAPIRuntime
import Testing

@testable import API

@Suite("Matters Endpoint Tests")
struct MattersEndpointTests {
    @Test("GET /matters returns 200 with matters list")
    func testGetMattersSuccess() async throws {
        let service = CodeCommitService()
        try await service.connect()

        let app = try await buildTestApplication(service: service)

        try await app.test(.router) { client in
            try await client.execute(uri: "/matters", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentType] == "application/json; charset=utf-8")

                let bodyData = Data(buffer: response.body)
                let matters = try JSONDecoder().decode(
                    Components.Schemas.MattersResponse.self,
                    from: bodyData
                )

                #expect(matters.matters.count >= 0)
            }
        }

        try await service.shutdown()
    }

    @Test("GET /matters returns valid JSON schema")
    func testGetMattersSchema() async throws {
        let service = CodeCommitService()
        try await service.connect()

        let app = try await buildTestApplication(service: service)

        try await app.test(.router) { client in
            try await client.execute(uri: "/matters", method: .get) { response in
                #expect(response.status == .ok)

                let bodyData = Data(buffer: response.body)
                let matters = try JSONDecoder().decode(
                    Components.Schemas.MattersResponse.self,
                    from: bodyData
                )

                for matter in matters.matters {
                    #expect(!matter.name.isEmpty)
                    #expect(!matter.gitUrl.isEmpty)
                    #expect(matter.gitUrl.hasPrefix("https://git-codecommit."))
                    #expect(matter.gitUrl.contains("/v1/repos/"))
                }
            }
        }

        try await service.shutdown()
    }
}

func buildTestApplication(
    service: CodeCommitService
) async throws
    -> some ApplicationProtocol
{
    let api = APIImpl(codeCommitService: service)

    let router = Router()
    try api.registerHandlers(on: router, serverURL: try Servers.Server1.url())

    return Application(router: router)
}
