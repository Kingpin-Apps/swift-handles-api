# ``SwiftHandlesAPI/Network``

Cardano network environments supported by the API.

## Overview

The `Network` enum defines which Cardano network environment your client will connect to. Each network has its own set of handles, holders, and blockchain data.

### Available Networks

Currently supported:

- **``mainnet``** - The production Cardano network with real ADA and live handles

Additional networks planned for future releases:
- `preprod` - Pre-production testing environment
- `preview` - Preview testing environment
- `guild` - Guild development network
- `sancho` - Sancho testing network

### Network Selection

Choose a network when creating your client:

```swift
// Production: real handles and live data
let mainnetClient = try Handles(
    network: .mainnet,
    apiKey: "your-api-key"
)

// Future: testing environments
// let preprodClient = try Handles(network: .preprod, apiKey: "test-key")
```

### Network URLs

Each network maps to a specific API endpoint:

```swift
let network = Network.mainnet
let url = try network.url()
print(url) // https://api.handle.me
```

The network URLs are defined in the OpenAPI specification's server configuration.

## When to Use Each Network

### Mainnet

Use for:
- Production applications
- Real user data and transactions
- Apps published to the App Store
- Live blockchain queries

### Test Networks (Coming Soon)

Use for:
- Development and testing
- Integration tests
- Feature development
- QA environments

> Important: Handles minted on one network do not exist on other networks. Always use the appropriate network for your use case.

## Topics

### Network Cases

- ``mainnet``

### Network Methods

- ``url()``

### Related Documentation

- <doc:NetworkConfiguration>
- <doc:GettingStarted>
- ``Handles``
