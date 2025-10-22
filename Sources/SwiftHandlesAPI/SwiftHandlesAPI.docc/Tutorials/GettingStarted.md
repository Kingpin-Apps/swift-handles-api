# Getting Started

Learn how to install SwiftHandlesAPI and make your first API call to the ADA Handle Public API.

## Overview

SwiftHandlesAPI provides a type-safe Swift client for accessing ADA Handle data on the Cardano blockchain. This guide walks you through installation, setup, and making your first API request.

### Installation

#### Swift Package Manager

Add SwiftHandlesAPI to your project using Swift Package Manager. In your `Package.swift` file:

```swift
dependencies: [
    .package(
        url: "https://github.com/Kingpin-Apps/swift-handles-api.git",
        from: "0.1.0"
    )
]
```

Then add it to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftHandlesAPI", package: "swift-handles-api")
    ]
)
```

#### Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the repository URL: `https://github.com/Kingpin-Apps/swift-handles-api.git`
4. Select the version you want to use (e.g., "Up to Next Major Version" from 0.1.0)
5. Click **Add Package**

### Creating Your First Client

Import the package and create a ``Handles`` client instance:

```swift
import SwiftHandlesAPI

// Create a client for mainnet with your API key
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key-here"
)
```

> Tip: You can get an API key from the [ADA Handle API Portal](https://api.handle.me). Using an API key helps avoid rate limiting.

### Making Your First API Call

Once you have a client, you can fetch handle data:

```swift
// Fetch a specific handle
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "adahandle")
    )
)

// Parse the response
let handle = try response.ok.body.json

// Access handle properties
print("Handle: \(handle.name ?? "unknown")")
print("Holder: \(handle.holder ?? "unknown")")
print("Rarity: \(handle.rarity?.rawValue ?? "unknown")")

if let resolvedAda = handle.resolved_addresses?.ada {
    print("ADA Address: \(resolvedAda)")
}
```

### Best Practices

#### Use Environment Variables for API Keys

For security, avoid hardcoding API keys. Use environment variables instead:

```swift
// Set environment variable first:
// export HANDLES_API_KEY="your-api-key"

let handles = try Handles(
    network: .mainnet,
    environmentVariable: "HANDLES_API_KEY"
)
```

See <doc:AuthenticationGuide> for more authentication options.

#### Handle Errors Gracefully

Always wrap API calls in do-catch blocks:

```swift
do {
    let response = try await handles.client.getHandlesHandle(
        Operations.GetHandlesHandle.Input(
            path: .init(handle: "my.handle")
        )
    )
    let handle = try response.ok.body.json
    // Process handle data
} catch {
    print("Failed to fetch handle: \(error)")
}
```

See <doc:ErrorHandling> for comprehensive error handling patterns.

#### Respect Rate Limits

- Always use an API key to get higher rate limits
- Implement exponential backoff for retries
- Cache responses when appropriate
- Batch requests when possible

### Next Steps

Now that you've made your first API call, explore more capabilities:

- **<doc:AuthenticationGuide>** - Learn about API key management and authentication
- **<doc:WorkingWithHandles>** - Discover all available API operations
- **<doc:NetworkConfiguration>** - Configure clients for different Cardano networks
- **<doc:ErrorHandling>** - Implement robust error handling
- **<doc:TestingYourCode>** - Write tests for your integration

## See Also

- ``Handles``
- ``Network``
- <doc:AuthenticationGuide>
