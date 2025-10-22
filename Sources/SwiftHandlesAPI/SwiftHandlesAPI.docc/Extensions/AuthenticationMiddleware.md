# ``SwiftHandlesAPI/AuthenticationMiddleware``

OpenAPI middleware that injects Bearer token authentication into API requests.

## Overview

`AuthenticationMiddleware` is an internal component that automatically adds authentication headers to all API requests. When you provide an API key to the ``Handles`` initializer, this middleware is configured automatically.

You typically don't interact with this type directly—it's managed by the ``Handles`` client.

### How It Works

The middleware intercepts every outgoing API request and adds an `Authorization` header with your API key formatted as a Bearer token:

```
Authorization: Bearer your-api-key
```

This happens transparently for all operations on the `client` property.

### Automatic Configuration

When you create a ``Handles`` instance with an API key, the middleware is configured automatically:

```swift
// The middleware is set up internally
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key"
)

// All requests now include: Authorization: Bearer your-api-key
let response = try await handles.client.getHandlesHandle(...)
```

### Manual Configuration (Advanced)

For advanced use cases, you can create a custom client with the middleware:

```swift
import OpenAPIRuntime
import OpenAPIURLSession

// Create middleware manually
let authMiddleware = AuthenticationMiddleware(
    authorizationHeaderFieldValue: "your-api-key"
)

// Create custom client
let customClient = Client(
    serverURL: URL(string: "https://api.handle.me")!,
    transport: URLSessionTransport(),
    middlewares: [authMiddleware]
)

// Use custom client
let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key",
    client: customClient
)
```

## Authentication Flow

1. You provide an API key to ``Handles/init(network:apiKey:basePath:environmentVariable:client:)``
2. `AuthenticationMiddleware` is created with your key
3. The middleware is added to the OpenAPI client's middleware stack
4. For every API request:
   - The middleware intercepts the request
   - Adds `Authorization: Bearer <your-key>` header
   - Passes the request to the transport layer
5. The API server validates the token and processes your request

## Without Authentication

If you don't provide an API key, no middleware is added:

```swift
// No authentication - subject to rate limiting
let handles = try Handles(network: .mainnet)

// Requests made without Authorization header
```

> Warning: Requests without authentication are subject to strict rate limiting. Always use an API key for production applications.

## Troubleshooting

### 401 Unauthorized

If you receive 401 errors:

1. Verify your API key is correct
2. Check if the key has expired
3. Ensure the environment variable is set correctly
4. Generate a new key from the [API portal](https://api.handle.me)

### 429 Rate Limited

Even with authentication, you may hit rate limits:

- Implement exponential backoff
- Cache responses when appropriate
- Batch requests efficiently
- Consider upgrading your API plan

See <doc:ErrorHandling> for comprehensive error handling strategies.

## Topics

### Initialization

- ``init(authorizationHeaderFieldValue:)``

### Related Documentation

- <doc:AuthenticationGuide>
- <doc:ErrorHandling>
- ``Handles``
- ``HandlesError``
