# Authentication Guide

Learn how to securely authenticate with the ADA Handle Public API using API keys and environment variables.

## Overview

SwiftHandlesAPI uses Bearer token authentication via the ``AuthenticationMiddleware``. This guide covers different methods for providing your API key and best practices for secure credential management.

### How Authentication Works

When you provide an API key to the ``Handles`` initializer, the library automatically:

1. Wraps your API key in a Bearer token format
2. Injects the token into the `Authorization` header of every request
3. Handles authentication transparently for all API operations

The ``AuthenticationMiddleware`` intercepts each request and adds:

```
Authorization: Bearer your-api-key
```

### Getting an API Key

To obtain an API key:

1. Visit the [ADA Handle API Portal](https://api.handle.me)
2. Sign up or log in to your account
3. Generate a new API key from your dashboard
4. Store the key securely (see best practices below)

> Important: API keys provide higher rate limits and access to additional features. Without an API key, you'll be subject to stricter rate limiting.

## Authentication Methods

### Direct API Key

The simplest approach is passing the API key directly:

```swift
import SwiftHandlesAPI

let handles = try Handles(
    network: .mainnet,
    apiKey: "your-api-key-here"
)
```

**Use this for:**
- Quick prototyping and testing
- Scripts where the key is injected at runtime
- Situations where environment variables aren't practical

**Avoid this for:**
- Production code with hardcoded keys
- Code that will be committed to version control
- Shared codebases

### Environment Variable (Recommended)

The most secure approach for production:

```swift
// 1. Set environment variable before running your app
// export HANDLES_API_KEY="your-api-key"

// 2. Initialize client with environment variable name
let handles = try Handles(
    network: .mainnet,
    environmentVariable: "HANDLES_API_KEY"
)
```

The library will:
- Read the environment variable at runtime
- Throw ``HandlesError/missingAPIKey(_:)`` if the variable isn't set or is empty
- Keep your key out of source code

#### Setting Environment Variables

**macOS/Linux:**

```bash
# Temporary (current session only)
export HANDLES_API_KEY="your-api-key"

# Permanent (add to ~/.zshrc or ~/.bash_profile)
echo 'export HANDLES_API_KEY="your-api-key"' >> ~/.zshrc
source ~/.zshrc
```

**Xcode:**

1. Select your scheme → Edit Scheme
2. Go to Run → Arguments
3. Add to "Environment Variables":
   - Name: `HANDLES_API_KEY`
   - Value: `your-api-key`

**Docker:**

```dockerfile
ENV HANDLES_API_KEY=your-api-key
```

Or use docker-compose:

```yaml
environment:
  - HANDLES_API_KEY=your-api-key
```

### No Authentication

You can create a client without authentication, but you'll face strict rate limits:

```swift
let handles = try Handles(network: .mainnet)
// No apiKey parameter provided
```

## Error Handling

Handle authentication errors appropriately:

```swift
do {
    let handles = try Handles(
        network: .mainnet,
        environmentVariable: "HANDLES_API_KEY"
    )
    
    let response = try await handles.client.getHandlesHandle(
        Operations.GetHandlesHandle.Input(
            path: .init(handle: "my.handle")
        )
    )
    
    let handle = try response.ok.body.json
    
} catch HandlesError.missingAPIKey(let message) {
    print("API key not found: \(message ?? "")")
    // Guide user to set up their API key
    
} catch HandlesError.invalidBasePath(let message) {
    print("Configuration error: \(message ?? "")")
    
} catch {
    print("Request failed: \(error)")
    // May indicate authentication failure (401)
    // or other API errors
}
```

### HTTP 401 Unauthorized

If your API key is invalid or expired, the API will return a 401 status. Handle this by:

1. Verifying your API key is correct
2. Checking if the key has expired
3. Generating a new key from the API portal

### HTTP 429 Rate Limited

Even with an API key, you may hit rate limits with excessive requests:

```swift
// Implement exponential backoff
func fetchWithRetry(handle: String, maxRetries: Int = 3) async throws -> Components.Schemas.Handle {
    var retries = 0
    var delay: TimeInterval = 1.0
    
    while retries < maxRetries {
        do {
            let response = try await handles.client.getHandlesHandle(
                Operations.GetHandlesHandle.Input(
                    path: .init(handle: handle)
                )
            )
            return try response.ok.body.json
            
        } catch {
            retries += 1
            if retries >= maxRetries { throw error }
            
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay *= 2  // Exponential backoff
        }
    }
    
    fatalError("Max retries exceeded")
}
```

## Security Best Practices

### Never Commit API Keys

Add sensitive files to `.gitignore`:

```
# .gitignore
.env
*.env
secrets/
```

### Use Secrets Management

For production deployments:

- **iOS/macOS Apps**: Use Keychain for storing API keys
- **CI/CD**: Use encrypted secrets (GitHub Secrets, GitLab CI/CD variables)
- **Cloud**: Use secret managers (AWS Secrets Manager, Azure Key Vault)
- **Backend Services**: Use environment-specific config files that aren't version controlled

### Rotate Keys Regularly

1. Generate a new API key
2. Update your environment variables
3. Test with the new key
4. Revoke the old key from the API portal

### Limit Key Permissions

If the API supports scoped permissions, create keys with minimal required access:

- Read-only keys for apps that only fetch data
- Separate keys for different environments (dev, staging, prod)

## See Also

- ``AuthenticationMiddleware``
- ``Handles``
- ``HandlesError``
- <doc:GettingStarted>
- <doc:ErrorHandling>
