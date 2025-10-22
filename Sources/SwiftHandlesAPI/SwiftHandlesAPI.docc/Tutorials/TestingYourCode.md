# Testing Your Code

Learn how to write tests for code that uses SwiftHandlesAPI using the Swift Testing framework.

## Overview

SwiftHandlesAPI is designed to be testable. This guide shows you how to write effective tests using Swift Testing (not XCTest), mock API responses, and verify your integration code works correctly.

> Note: This project uses **Swift Testing**, the modern testing framework introduced with Swift 6. Use `@Suite`, `@Test`, and `#expect()` instead of XCTest's classes and assertions.

## Swift Testing Basics

### Test Suite Structure

Organize tests using `@Suite`:

```swift
import Testing
@testable import SwiftHandlesAPI

@Suite("Handles API Client Tests")
struct HandlesAPITests {
    
    @Test("Create client with API key")
    func testClientCreation() async throws {
        let handles = try Handles(
            network: .mainnet,
            apiKey: "test-key"
        )
        
        #expect(handles.network == .mainnet)
        #expect(handles.apiKey == "test-key")
    }
    
    @Test("Environment variable API key")
    func testEnvironmentVariable() async throws {
        // This will throw if HANDLES_API_KEY is not set
        #expect(throws: HandlesError.missingAPIKey) {
            try Handles(
                network: .mainnet,
                environmentVariable: "NONEXISTENT_KEY"
            )
        }
    }
}
```

### Assertions with #expect

Swift Testing uses `#expect()` instead of XCTAssert:

```swift
@Test("Network URL generation")
func testNetworkURL() async throws {
    let network = Network.mainnet
    let url = try network.url()
    
    #expect(url.absoluteString == "https://api.handle.me")
}

@Test("Invalid base path throws error")
func testInvalidBasePath() async throws {
    #expect(throws: HandlesError.invalidBasePath) {
        try Handles(
            network: .mainnet,
            apiKey: "key",
            basePath: "not-a-valid-url"
        )
    }
}
```

## Mocking API Responses

### Creating a Mock Transport

The OpenAPI client uses the `ClientTransport` protocol, which you can implement for testing:

```swift
import OpenAPIRuntime
import HTTPTypes
import Foundation

struct MockTransport: ClientTransport {
    let responseHandler: (HTTPRequest, URL, String) throws -> (HTTPResponse, Data?)
    
    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let (response, data) = try responseHandler(request, baseURL, operationID)
        
        let responseBody: HTTPBody? = if let data = data {
            HTTPBody(data)
        } else {
            nil
        }
        
        return (response, responseBody)
    }
}
```

### Using Mock Transport in Tests

```swift
@Suite("Handle Fetching Tests")
struct HandleFetchingTests {
    
    @Test("Fetch specific handle")
    func testFetchHandle() async throws {
        // Create mock response
        let mockHandleJSON = """
        {
            "name": "test.handle",
            "hex": "746573742e68616e646c65",
            "holder": "addr1...",
            "rarity": "common",
            "length": 11,
            "og": false
        }
        """
        
        let mockTransport = MockTransport { request, baseURL, operationID in
            #expect(operationID == "getHandlesHandle")
            
            let response = HTTPResponse(status: .ok)
            let data = mockHandleJSON.data(using: .utf8)
            
            return (response, data)
        }
        
        // Create client with mock transport
        let mockClient = Client(
            serverURL: URL(string: "https://api.handle.me")!,
            transport: mockTransport
        )
        
        let handles = try Handles(
            network: .mainnet,
            apiKey: "test-key",
            client: mockClient
        )
        
        // Test the API call
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: "test.handle")
            )
        )
        
        let handle = try response.ok.body.json
        
        #expect(handle.name == "test.handle")
        #expect(handle.rarity?.rawValue == "common")
        #expect(handle.length == 11)
    }
}
```

## Testing Error Handling

### Testing Configuration Errors

```swift
@Suite("Configuration Error Tests")
struct ConfigurationErrorTests {
    
    @Test("Missing API key throws error")
    func testMissingAPIKey() async throws {
        #expect(throws: HandlesError.missingAPIKey) {
            try Handles(
                network: .mainnet,
                environmentVariable: "THIS_VAR_DOES_NOT_EXIST"
            )
        }
    }
    
    @Test("Invalid base path throws error")
    func testInvalidBasePath() async throws {
        #expect(throws: HandlesError.invalidBasePath) {
            try Handles(
                network: .mainnet,
                apiKey: "key",
                basePath: "not a url"
            )
        }
    }
}
```

### Testing API Error Responses

```swift
@Suite("API Error Response Tests")
struct APIErrorTests {
    
    @Test("Handle 404 Not Found")
    func test404Response() async throws {
        let mockTransport = MockTransport { _, _, _ in
            let response = HTTPResponse(status: .notFound)
            return (response, nil)
        }
        
        let mockClient = Client(
            serverURL: URL(string: "https://api.handle.me")!,
            transport: mockTransport
        )
        
        let handles = try Handles(
            network: .mainnet,
            apiKey: "test-key",
            client: mockClient
        )
        
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: "nonexistent")
            )
        )
        
        // Verify we got a notFound response
        switch response {
        case .notFound:
            // Expected
            break
        default:
            Issue.record("Expected notFound response")
        }
    }
    
    @Test("Handle 400 Bad Request")
    func test400Response() async throws {
        let mockTransport = MockTransport { _, _, _ in
            let response = HTTPResponse(status: .badRequest)
            return (response, nil)
        }
        
        let mockClient = Client(
            serverURL: URL(string: "https://api.handle.me")!,
            transport: mockTransport
        )
        
        let handles = try Handles(
            network: .mainnet,
            apiKey: "test-key",
            client: mockClient
        )
        
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: "bad-request")
            )
        )
        
        switch response {
        case .badRequest:
            // Expected
            break
        default:
            Issue.record("Expected badRequest response")
        }
    }
}
```

## Testing with Fixtures

### Creating Fixture Files

Store test data in JSON files:

```swift
// Tests/SwiftHandlesAPITests/Fixtures/handle.json
{
    "name": "adahandle",
    "hex": "61646168616e646c65",
    "holder": "addr1qx...",
    "holder_type": "wallet",
    "rarity": "legendary",
    "length": 9,
    "og": true,
    "resolved_addresses": {
        "ada": "addr1qx...",
        "eth": "0x...",
        "btc": "bc1..."
    }
}
```

### Loading Fixtures

```swift
extension Bundle {
    func loadJSON<T: Decodable>(_ filename: String) throws -> T {
        guard let url = url(forResource: filename, withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

@Suite("Fixture-based Tests")
struct FixtureTests {
    
    @Test("Load and parse handle fixture")
    func testHandleFixture() async throws {
        let fixtureData: Data = try Bundle.module.loadJSON("handle")
        
        let mockTransport = MockTransport { _, _, _ in
            let response = HTTPResponse(status: .ok)
            return (response, fixtureData)
        }
        
        let mockClient = Client(
            serverURL: URL(string: "https://api.handle.me")!,
            transport: mockTransport
        )
        
        let handles = try Handles(
            network: .mainnet,
            apiKey: "test-key",
            client: mockClient
        )
        
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: "adahandle")
            )
        )
        
        let handle = try response.ok.body.json
        
        #expect(handle.name == "adahandle")
        #expect(handle.og == true)
        #expect(handle.rarity?.rawValue == "legendary")
    }
}
```

## Testing Async Operations

### Testing Concurrent Requests

```swift
@Suite("Concurrent Request Tests")
struct ConcurrentTests {
    
    @Test("Fetch multiple handles concurrently")
    func testConcurrentFetches() async throws {
        let handleNames = ["handle1", "handle2", "handle3"]
        
        let mockTransport = MockTransport { request, _, operationID in
            // Extract handle name from request path
            let path = request.path ?? ""
            let name = path.components(separatedBy: "/").last ?? "unknown"
            
            let json = """
            {"name": "\(name)", "hex": "test", "length": \(name.count)}
            """
            
            let response = HTTPResponse(status: .ok)
            let data = json.data(using: .utf8)
            
            return (response, data)
        }
        
        let mockClient = Client(
            serverURL: URL(string: "https://api.handle.me")!,
            transport: mockTransport
        )
        
        let handles = try Handles(
            network: .mainnet,
            apiKey: "test-key",
            client: mockClient
        )
        
        // Fetch concurrently
        let results = try await withThrowingTaskGroup(of: Components.Schemas.Handle.self) { group in
            for name in handleNames {
                group.addTask {
                    let response = try await handles.client.getHandlesHandle(
                        Operations.GetHandlesHandle.Input(
                            path: .init(handle: name)
                        )
                    )
                    return try response.ok.body.json
                }
            }
            
            var fetchedHandles: [Components.Schemas.Handle] = []
            for try await handle in group {
                fetchedHandles.append(handle)
            }
            return fetchedHandles
        }
        
        #expect(results.count == 3)
    }
}
```

## Integration Tests

### Testing Against Real API (Optional)

For integration tests that hit the real API:

```swift
@Suite("Integration Tests", .tags(.integration))
struct IntegrationTests {
    
    @Test("Fetch real handle from mainnet")
    func testRealAPICall() async throws {
        // Skip if no API key available
        guard let apiKey = ProcessInfo.processInfo.environment["HANDLES_API_KEY"],
              !apiKey.isEmpty else {
            throw XCTSkip("API key not available")
        }
        
        let handles = try Handles(
            network: .mainnet,
            apiKey: apiKey
        )
        
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: "adahandle")
            )
        )
        
        let handle = try response.ok.body.json
        
        #expect(handle.name != nil)
        #expect(handle.holder != nil)
    }
}

// Define custom tag
extension Tag {
    @Tag static var integration: Self
}
```

## Best Practices

### 1. Use Suites for Organization

Group related tests:

```swift
@Suite("Handles Client")
struct HandlesClientTests {
    
    @Suite("Initialization")
    struct InitializationTests {
        @Test func testWithAPIKey() async throws { /* ... */ }
        @Test func testWithEnvVar() async throws { /* ... */ }
    }
    
    @Suite("API Operations")
    struct APIOperationTests {
        @Test func testFetchHandle() async throws { /* ... */ }
        @Test func testSearchHandles() async throws { /* ... */ }
    }
}
```

### 2. Test Edge Cases

```swift
@Test("Empty search results")
func testEmptyResults() async throws {
    let mockTransport = MockTransport { _, _, _ in
        let response = HTTPResponse(status: .ok)
        let data = "[]".data(using: .utf8)
        return (response, data)
    }
    
    // Test with empty array
}

@Test("Malformed JSON response")
func testMalformedJSON() async throws {
    let mockTransport = MockTransport { _, _, _ in
        let response = HTTPResponse(status: .ok)
        let data = "{ invalid json }".data(using: .utf8)
        return (response, data)
    }
    
    // Expect decoding error
}
```

### 3. Test Parameterization

```swift
@Test("Handle names", arguments: [
    "simple",
    "my.handle",
    "long-handle-name",
    "123numeric"
])
func testHandleNames(name: String) async throws {
    // Test with different handle names
    #expect(!name.isEmpty)
}
```

### 4. Isolate Tests

Each test should be independent:

```swift
@Suite("Isolated Tests")
struct IsolatedTests {
    
    @Test func testA() async throws {
        // Create fresh client
        let handles = try Handles(network: .mainnet, apiKey: "key-a")
        // Test...
    }
    
    @Test func testB() async throws {
        // Create fresh client (not dependent on testA)
        let handles = try Handles(network: .mainnet, apiKey: "key-b")
        // Test...
    }
}
```

## Running Tests

### Command Line

```bash
# Run all tests
swift test

# Run tests in parallel
swift test --parallel

# Filter specific tests
swift test --filter HandlesTests

# Enable test discovery
swift test --enable-test-discovery
```

### Xcode

1. Press `⌘U` to run all tests
2. Click the diamond in the gutter next to individual tests
3. Use the Test Navigator (`⌘6`) to browse and run tests

## See Also

- <doc:GettingStarted>
- <doc:WorkingWithHandles>
- <doc:ErrorHandling>
- ``Handles``
