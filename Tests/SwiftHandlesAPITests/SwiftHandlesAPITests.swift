import Testing
import Foundation
import OpenAPIRuntime
import HTTPTypes
@testable import SwiftHandlesAPI

@Suite("Handles Tests")
struct HandlesTests {
    let handles = try! Handles(
        network: .mainnet,
        apiKey: "fake-api-key",
        client: Client(
            serverURL: URL(string: "https://api.handle.me")!,
            transport: MockTransport()
        )
    )
    
    @Test("Test handle")
    func handle() async throws {
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(
                    handle: "my.handle"
                )
            )
        )
        let handleData = try response.ok.body.json
        
        // Validate we have exactly one tip record
        #expect(handleData.hex == "string")
        #expect(handleData.name == "my.handle")
    }
}
