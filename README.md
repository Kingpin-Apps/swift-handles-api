# SwiftHandlesAPI

A Swift client library for the [ADA Handle Public API](https://handle.me), providing type-safe access to Cardano blockchain handle data and operations.

## Features

- ✨ **Type-safe API client** generated from OpenAPI specification
- 🔐 **Built-in authentication** with API key support
- 🌐 **Network flexibility** (mainnet, preprod, preview support)
- 🧪 **Comprehensive testing** using Swift Testing framework
- 📱 **Multi-platform** support (iOS, macOS, watchOS, tvOS)
- 🚀 **Modern Swift** leveraging async/await and Swift 6.2

## Requirements

- Swift 6.2+
- iOS 14.0+ / macOS 13.0+ / watchOS 7.0+ / tvOS 14.0+
- Xcode 15.0+ (for development)

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/swift-handles-api.git", from: "0.1.0")
]
```

Or in Xcode:
1. Go to File → Add Package Dependencies...
2. Enter the repository URL
3. Select the version you want to use

## Quick Start

### Basic Usage

```swift
import SwiftHandlesAPI

// Initialize the client
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key"
)

// Fetch a specific handle
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "my.handle")
    )
)

let handleData = try response.ok.body.json
print("Handle: \(handleData.name ?? "unknown")")
print("Holder: \(handleData.holder ?? "unknown")")
```

### Using Environment Variables

```swift
// Set API key via environment variable
// export HANDLES_API_KEY="your-api-key"

let handles = try Handles(
    network: .mainnet,
    environmentVariable: "HANDLES_API_KEY"
)
```

### Custom Base URL

```swift
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key",
    basePath: "https://custom-api.example.com"
)
```

## API Operations

### Get a Specific Handle

```swift
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "adahandle")
    )
)
let handle = try response.ok.body.json
```

### Get All Handles (with filters)

```swift
let response = try await handles.client.getHandles(
    Operations.GetHandles.Input(
        query: .init(
            search: "ada",
            rarity: .rare,
            records_per_page: 50,
            page: 1
        )
    )
)
let handlesList = try response.ok.body.json
```

### Get Handle UTxO

```swift
let response = try await handles.client.getHandlesHandleUtxo(
    Operations.GetHandlesHandleUtxo.Input(
        path: .init(handle: "my.handle")
    )
)
let utxo = try response.ok.body.json
```

### Get Holder Information

```swift
let response = try await handles.client.getHoldersHolderAddress(
    Operations.GetHoldersHolderAddress.Input(
        path: .init(holder_address: "stake1u...")
    )
)
let holder = try response.ok.body.json
```

### Get Handle Statistics

```swift
let response = try await handles.client.getStats()
let stats = try response.ok.body.json
print("Total Handles: \(stats.total_handles ?? 0)")
print("Total Holders: \(stats.total_holders ?? 0)")
```

## Architecture

### OpenAPI Code Generation

This library uses [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator) to automatically generate type-safe Swift code from the OpenAPI specification at build time.

**Key Files:**
- `Sources/SwiftHandlesAPI/openapi.yml` - The ADA Handle Public API specification
- `Sources/SwiftHandlesAPI/openapi-generator-config.yaml` - Generator configuration

**Generated Namespaces:**
- `Components.Schemas.*` - Data types (e.g., `Components.Schemas.Handle`)
- `Operations.*` - API operations (e.g., `Operations.GetHandlesHandle`)

### Authentication

The library provides an `AuthenticationMiddleware` that automatically injects Bearer token authentication into all API requests:

```swift
// Automatically handled when you provide an API key
let handles = try Handles(network: .mainnet, apiKey: "your-key")
// All requests will include: Authorization: Bearer your-key
```

### Network Configuration

The `Network` enum supports multiple Cardano networks:

```swift
public enum Network {
    case mainnet
    // case preprod  // Coming soon
    // case preview  // Coming soon
    // case guild    // Coming soon
    // case sancho   // Coming soon
}
```

## Testing

This project uses the **Swift Testing** framework (not XCTest).

### Running Tests

```bash
# Run all tests
swift test

# Run tests in parallel
swift test --parallel --enable-test-discovery

# Run a specific test suite
swift test --filter HandlesTests

# Build in release mode
swift build -c release
```

### Writing Tests

```swift
import Testing
@testable import SwiftHandlesAPI

@Suite("My Test Suite")
struct MyTests {
    @Test("Test description")
    func testExample() async throws {
        let result = try await someOperation()
        #expect(result == expectedValue)
    }
}
```

### Mocking for Tests

The library provides a `ClientTransport` protocol for mocking:

```swift
struct MockTransport: ClientTransport {
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
        // Return mock responses based on operationID
    }
}

let handles = try Handles(
    network: .mainnet,
    client: Client(serverURL: baseURL, transport: MockTransport())
)
```

## Error Handling

The library defines custom errors in `HandlesError`:

```swift
enum HandlesError: Error {
    case invalidBasePath(String?)
    case missingAPIKey(String?)
    case valueError(String?)
}
```

### Handling API Errors

```swift
do {
    let response = try await handles.client.getHandlesHandle(...)
    let handle = try response.ok.body.json
} catch let error as HandlesError {
    print("Handles API Error: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Data Models

### Handle

```swift
Components.Schemas.Handle // Main handle data type
```

Key properties:
- `name` - Handle name (e.g., "my.handle")
- `hex` - Hexadecimal representation
- `holder` - Current holder address
- `holder_type` - Type of holder (wallet, script, enterprise, other)
- `rarity` - Handle rarity (basic, common, rare, ultra_rare, legendary)
- `length` - Length of the handle
- `og` - OG status
- `resolved_addresses` - Resolved addresses for various chains (ada, eth, btc)
- `utxo` - Transaction hash and index

### Holder

```swift
Components.Schemas.Holder // Holder information
```

Key properties:
- `address` - Stake key or other address type
- `type` - Address type
- `total_handles` - Number of handles held
- `default_handle` - Default handle for this holder
- `known_owner_name` - Known vendor/exchange name

### UTxO

```swift
Components.Schemas.UTxO // Unspent transaction output
```

Key properties:
- `tx_id` - Transaction ID
- `index` - UTxO index
- `lovelace` - Amount in lovelace
- `datum` - Datum CBOR if present
- `address` - UTxO address

## Documentation

### Generate Documentation

```bash
swift package generate-documentation --target SwiftHandlesAPI
```

### API Reference

For complete API documentation, see the [ADA Handle Public API docs](https://api.handle.me/swagger).

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests using Swift Testing framework
4. Ensure all tests pass (`swift test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/your-org/swift-handles-api.git
cd swift-handles-api

# Build the package
swift build

# Run tests
swift test --parallel --enable-test-discovery
```

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## Resources

- [ADA Handle Official Site](https://handle.me)
- [ADA Handle Public API](https://api.handle.me/swagger)
- [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- [Cardano Documentation](https://docs.cardano.org)

## Support

For issues, questions, or contributions, please:
- Open an issue on GitHub
- Contact the maintainers
- Check the [API documentation](https://api.handle.me/swagger)

---

**Note:** This library is a client for the ADA Handle Public API. For official ADA Handle information and services, visit [handle.me](https://handle.me).
