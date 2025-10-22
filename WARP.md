# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Building and Testing

### Build the package
```bash
swift build
```

### Run all tests
```bash
swift test
```

### Run tests in parallel with test discovery
```bash
swift test --parallel --enable-test-discovery
```

### Run a specific test
```bash
swift test --filter HandlesTests
```

### Build in release mode
```bash
swift build -c release
```

### Generate documentation
```bash
swift package generate-documentation --target SwiftHandlesAPI
```

## Code Architecture

### OpenAPI Code Generation
This package uses **Swift OpenAPI Generator** to automatically generate Swift types and client code from the OpenAPI specification. The generated code is produced at build time via a Swift Package Manager plugin.

**Key files**:
- `Sources/SwiftHandlesAPI/openapi.yml` - The ADA Handle Public API specification (source of truth)
- `Sources/SwiftHandlesAPI/openapi-generator-config.yaml` - Controls code generation (types + client, public access, idiomatic naming)

Generated types are in the `Components.Schemas` namespace (e.g., `Components.Schemas.Handle`) and operations are in the `Operations` namespace.

### Client Architecture
The `Handles` struct in `HandlesAPIClient.swift` is the main entry point:
- Wraps the auto-generated OpenAPI `Client`
- Handles network selection (mainnet, preprod, preview, etc.)
- Manages API key authentication via custom `AuthenticationMiddleware`
- Supports environment variable-based API key configuration
- Provides flexible initialization (custom base paths, custom clients for testing)

The `AuthenticationMiddleware` injects Bearer token authentication into all requests via the `Authorization` header.

### Testing with Swift Testing
This project uses **Swift Testing** (not XCTest). Key patterns:
- Use `@Suite` attribute to organize test groups
- Use `@Test` attribute for individual test functions
- Use `#expect()` for assertions (not XCTAssert*)
- Mock transport layer via `ClientTransport` protocol for testing without network calls
- Test fixtures defined in `Fixtures.swift` provide mock JSON responses

## Swift Version and Platforms
- Swift 6.2 minimum
- Platforms: iOS 14+, macOS 13+, watchOS 7+, tvOS 14+

## API Usage Patterns
When using this library:
1. Create a `Handles` instance with network and optional API key
2. Access the `client` property to call API operations
3. Operations follow the pattern: `client.get{Path}{Resource}()` with typed `Input` structs
4. Parse responses using the `.ok.body.json` pattern for successful responses

Example:
```swift
let handles = try Handles(network: .mainnet, apiKey: "your-key")
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "my.handle")
    )
)
let handle = try response.ok.body.json
```
