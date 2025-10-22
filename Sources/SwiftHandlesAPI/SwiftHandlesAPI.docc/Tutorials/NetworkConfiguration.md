# Network Configuration

Learn how to configure SwiftHandlesAPI for different Cardano networks and custom endpoints.

## Overview

SwiftHandlesAPI supports multiple Cardano network environments through the ``Network`` enum. This guide covers network selection, custom base URLs, and advanced configuration options.

## Available Networks

The ``Network`` enum defines the supported Cardano networks:

```swift
public enum Network {
    case mainnet
    // Additional networks coming soon:
    // case preprod
    // case preview
    // case guild
    // case sancho
}
```

### Mainnet

The production Cardano network where real ADA and handles exist:

```swift
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key"
)
```

**Use mainnet for:**
- Production applications
- Real user data and handles
- Live blockchain queries
- Apps in the App Store

### Testnet Networks (Coming Soon)

Additional network support is planned:

- **Preprod** - Pre-production testing environment
- **Preview** - Preview testing environment  
- **Guild** - Guild network for development
- **Sancho** - Sancho testing environment

## Basic Network Selection

Choose a network when initializing your client:

```swift
import SwiftHandlesAPI

// Mainnet (production)
let mainnetClient = try Handles(
    network: .mainnet,
    apiKey: "your-api-key"
)

// Future: Preprod (testing)
// let preprodClient = try Handles(
//     network: .preprod,
//     apiKey: "your-api-key"
// )
```

## Custom Base URLs

For advanced use cases, you can specify a custom API endpoint:

```swift
let customClient = try Handles(
    network: .mainnet,
    apiKey: "your-api-key",
    basePath: "https://custom-api.example.com"
)
```

This is useful for:
- Using a proxy or API gateway
- Self-hosted API instances
- Development and testing with mock servers
- Load balancing across multiple endpoints

### Custom Base URL Example

```swift
// Point to a local development server
let devClient = try Handles(
    network: .mainnet,
    apiKey: "dev-key",
    basePath: "http://localhost:8080"
)

// Use a corporate proxy
let proxyClient = try Handles(
    network: .mainnet,
    apiKey: "your-api-key",
    basePath: "https://api-proxy.company.com/handles"
)
```

## Environment-Specific Configuration

### Using Configuration Files

Create environment-specific configurations:

```swift
struct HandlesConfig {
    let network: Network
    let apiKey: String
    let basePath: String?
    
    static let development = HandlesConfig(
        network: .mainnet,
        apiKey: ProcessInfo.processInfo.environment["DEV_API_KEY"] ?? "",
        basePath: "http://localhost:8080"
    )
    
    static let staging = HandlesConfig(
        network: .mainnet,
        apiKey: ProcessInfo.processInfo.environment["STAGING_API_KEY"] ?? "",
        basePath: "https://staging-api.example.com"
    )
    
    static let production = HandlesConfig(
        network: .mainnet,
        apiKey: ProcessInfo.processInfo.environment["PROD_API_KEY"] ?? "",
        basePath: nil  // Use default
    )
}

// Select config based on build configuration
#if DEBUG
let config = HandlesConfig.development
#elseif STAGING
let config = HandlesConfig.staging
#else
let config = HandlesConfig.production
#endif

let handles = try Handles(
    network: config.network,
    apiKey: config.apiKey,
    basePath: config.basePath
)
```

### Dynamic Network Selection

Select network at runtime based on user preferences or app state:

```swift
func createClient(for environment: String, apiKey: String) throws -> Handles {
    let network: Network
    
    switch environment.lowercased() {
    case "mainnet", "production":
        network = .mainnet
    // Future network support:
    // case "preprod":
    //     network = .preprod
    // case "preview":
    //     network = .preview
    default:
        throw HandlesError.valueError("Unknown network: \(environment)")
    }
    
    return try Handles(
        network: network,
        apiKey: apiKey
    )
}

// Usage
let client = try createClient(
    for: UserDefaults.standard.string(forKey: "network") ?? "mainnet",
    apiKey: storedAPIKey
)
```

## Network URLs

Each network maps to a specific API endpoint. The ``Network`` enum provides a `url()` method:

```swift
let network = Network.mainnet
let url = try network.url()
print(url)  // https://api.handle.me
```

The URLs are defined in the OpenAPI specification's `Servers` section.

## Error Handling

Handle network configuration errors:

```swift
do {
    let handles = try Handles(
        network: .mainnet,
        apiKey: "your-key",
        basePath: "invalid-url"
    )
} catch HandlesError.invalidBasePath(let message) {
    print("Invalid base path: \(message ?? "")")
} catch HandlesError.missingAPIKey(let message) {
    print("Missing API key: \(message ?? "")")
} catch {
    print("Configuration error: \(error)")
}
```

## Advanced: Custom Client

For maximum control, provide your own OpenAPI `Client` instance:

```swift
import OpenAPIRuntime
import OpenAPIURLSession

// Create custom transport with specific configuration
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30
configuration.timeoutIntervalForResource = 60

let session = URLSession(configuration: configuration)
let transport = URLSessionTransport(configuration: .init(session: session))

// Create custom middleware stack
let middleware = AuthenticationMiddleware(
    authorizationHeaderFieldValue: "your-api-key"
)

// Create custom client
let customClient = Client(
    serverURL: URL(string: "https://api.handle.me")!,
    transport: transport,
    middlewares: [middleware]
)

// Initialize Handles with custom client
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key",
    client: customClient
)
```

This approach allows you to:
- Customize timeout values
- Add custom middleware (logging, metrics, etc.)
- Configure URL session behavior
- Implement retry logic
- Add request/response interceptors

## Best Practices

### Use Environment Variables

Never hardcode network configuration:

```swift
// ❌ Don't hardcode
let handles = try Handles(
    network: .mainnet,
    apiKey: "sk_live_abc123..."
)

// ✅ Use environment variables
let handles = try Handles(
    network: .mainnet,
    environmentVariable: "HANDLES_API_KEY"
)
```

### Separate Configurations

Maintain separate API keys and configurations for each environment:

- **Development**: Use test/development API keys, mock data when possible
- **Staging**: Use staging-specific keys with production-like data
- **Production**: Use production keys with proper security measures

### Network-Specific Features

Be aware that different networks may have different data:

```swift
func fetchHandle(_ name: String, from network: Network) async throws -> Components.Schemas.Handle? {
    let client = try Handles(network: network, apiKey: apiKey)
    
    let response = try await client.client.getHandlesHandle(
        Operations.GetHandlesHandle.Input(
            path: .init(handle: name)
        )
    )
    
    return try response.ok.body.json
}

// Handle may exist on mainnet but not on testnet
let mainnetHandle = try await fetchHandle("adahandle", from: .mainnet)
// let testnetHandle = try await fetchHandle("adahandle", from: .preprod)
```

## See Also

- ``Network``
- ``Handles``
- ``HandlesError``
- <doc:GettingStarted>
- <doc:AuthenticationGuide>
