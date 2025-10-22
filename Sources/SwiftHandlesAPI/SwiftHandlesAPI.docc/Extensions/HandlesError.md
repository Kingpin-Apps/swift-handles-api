# ``SwiftHandlesAPI/HandlesError``

Errors specific to the SwiftHandlesAPI library.

## Overview

`HandlesError` defines errors that can occur during client initialization and configuration. These errors are thrown before any API requests are made.

For errors that occur during API operations (network errors, HTTP status codes, decoding errors), refer to standard Swift error types like `URLError` and `DecodingError`.

### Error Cases

The three types of configuration errors:

1. **``invalidBasePath(_:)``** - The provided base URL is malformed
2. **``missingAPIKey(_:)``** - Required environment variable for API key is not set
3. **``valueError(_:)``** - Invalid parameter or configuration value

### Error Handling Pattern

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
    
} catch HandlesError.invalidBasePath(let message) {
    print("Configuration error: \(message ?? "Invalid base path")")
    
} catch HandlesError.missingAPIKey(let message) {
    print("API key not found: \(message ?? "Set your API key")")
    // Guide user to configure API key
    
} catch HandlesError.valueError(let message) {
    print("Invalid value: \(message ?? "Check your configuration")")
    
} catch {
    print("Other error: \(error)")
}
```

### Comprehensive Error Handling

For production apps, handle all error types:

```swift
func fetchHandle(_ name: String) async throws -> Components.Schemas.Handle {
    do {
        let handles = try Handles(
            network: .mainnet,
            environmentVariable: "HANDLES_API_KEY"
        )
        
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: name)
            )
        )
        
        return try response.ok.body.json
        
    } catch let error as HandlesError {
        // Library configuration errors
        print("Configuration failed: \(error)")
        throw error
        
    } catch let error as URLError {
        // Network errors
        print("Network error: \(error.localizedDescription)")
        throw error
        
    } catch let error as DecodingError {
        // JSON parsing errors
        print("Failed to parse response: \(error)")
        throw error
        
    } catch {
        // Unexpected errors
        print("Unexpected error: \(error)")
        throw error
    }
}
```

## Topics

### Error Cases

- ``invalidBasePath(_:)``
- ``missingAPIKey(_:)``
- ``valueError(_:)``

### Related Documentation

- <doc:ErrorHandling>
- <doc:AuthenticationGuide>
- <doc:NetworkConfiguration>
- ``Handles``
