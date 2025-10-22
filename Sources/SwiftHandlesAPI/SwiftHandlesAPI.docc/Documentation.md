# ``SwiftHandlesAPI``

A Swift client library for the ADA Handle Public API, providing type-safe access to Cardano blockchain handle data and operations.

## Overview

SwiftHandlesAPI is a modern Swift package that wraps the [ADA Handle Public API](https://handle.me) with automatically generated, type-safe client code. Built on top of Swift OpenAPI Generator, it provides seamless access to handle data, holder information, and blockchain statistics for the Cardano ecosystem.

### Key Features

- **Type-safe API client** automatically generated from OpenAPI specification
- **Built-in authentication** with API key support (direct or environment variable)
- **Network flexibility** supporting multiple Cardano networks (mainnet, preprod, preview)
- **Modern Swift** leveraging async/await, Swift 6.2, and Swift Concurrency
- **Comprehensive testing** support using Swift Testing framework
- **Multi-platform** compatible with iOS, macOS, watchOS, and tvOS

### Architecture

The library is structured around three key components:

1. **``Handles``** - The main client wrapper providing convenient initialization and network selection
2. **``AuthenticationMiddleware``** - Automatic Bearer token injection for API authentication
3. **``Network``** - Type-safe network selection for different Cardano environments

All API types and operations are generated at build time from the OpenAPI specification via the Swift OpenAPI Generator plugin.

### Quick Start

Get started with a simple API call:

```swift
import SwiftHandlesAPI

// Create a client with direct API key
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

let handle = try response.ok.body.json
print("Handle: \(handle.name ?? "unknown")")
print("Holder: \(handle.holder ?? "unknown")")
```

Or use environment variables for API key management:

```swift
// Set environment variable first:
// export HANDLES_API_KEY="your-api-key"

let handles = try Handles(
    network: .mainnet,
    environmentVariable: "HANDLES_API_KEY"
)
```

## Topics

### Tutorials

- <doc:GettingStarted>
- <doc:AuthenticationGuide>
- <doc:WorkingWithHandles>
- <doc:NetworkConfiguration>
- <doc:ErrorHandling>
- <doc:TestingYourCode>

### Essentials

- ``Handles``
- ``Network``
- ``AuthenticationMiddleware``
- ``HandlesError``

### OpenAPI Generated Types

The following namespaces contain auto-generated types from the OpenAPI specification:

- `Client` - The underlying OpenAPI client
- `Operations` - API operation inputs and outputs
- `Components` - Schema types including `Handle`, `Holder`, `UTxO`, and more
