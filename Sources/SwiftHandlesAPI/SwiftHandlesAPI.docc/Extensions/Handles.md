# ``SwiftHandlesAPI/Handles``

The main client for accessing the ADA Handle Public API.

## Overview

`Handles` is a convenience wrapper around the OpenAPI-generated `Client` that simplifies initialization and configuration. It provides:

- **Network selection** via the ``Network`` enum
- **Authentication** through ``AuthenticationMiddleware``
- **Flexible configuration** with environment variables and custom URLs
- **Type-safe operations** from the auto-generated OpenAPI client

### Basic Usage

```swift
import SwiftHandlesAPI

// Create a client with direct API key
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key"
)

// Fetch a handle
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "adahandle")
    )
)

let handle = try response.ok.body.json
print("Handle: \(handle.name ?? ""), Owner: \(handle.holder ?? "")")
```

### Environment Variable Configuration

For production apps, use environment variables:

```swift
// Set environment variable first:
// export HANDLES_API_KEY="your-api-key"

let handles = try Handles(
    network: .mainnet,
    environmentVariable: "HANDLES_API_KEY"
)
```

## Topics

### Creating a Client

- ``init(network:apiKey:basePath:environmentVariable:client:)``

### Client Properties

- ``client``
- ``network``
- ``apiKey``

### Related Documentation

- <doc:GettingStarted>
- <doc:AuthenticationGuide>
- <doc:NetworkConfiguration>
- <doc:WorkingWithHandles>
