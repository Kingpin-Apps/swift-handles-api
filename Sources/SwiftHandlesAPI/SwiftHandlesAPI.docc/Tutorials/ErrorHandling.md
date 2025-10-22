# Error Handling

Learn how to handle errors effectively when working with the ADA Handle Public API.

## Overview

SwiftHandlesAPI provides structured error handling through the ``HandlesError`` enum and standard Swift error handling patterns. This guide covers common error scenarios, error types, and best practices for robust error handling.

## Error Types

### HandlesError

The ``HandlesError`` enum defines library-specific errors:

```swift
enum HandlesError: Error {
    case invalidBasePath(String?)
    case missingAPIKey(String?)
    case valueError(String?)
}
```

#### invalidBasePath

Thrown when an invalid base URL is provided:

```swift
do {
    let handles = try Handles(
        network: .mainnet,
        apiKey: "key",
        basePath: "not-a-valid-url"
    )
} catch HandlesError.invalidBasePath(let message) {
    print("Invalid URL: \(message ?? "")")
}
```

#### missingAPIKey

Thrown when an environment variable for the API key is not set:

```swift
do {
    // HANDLES_API_KEY environment variable is not set
    let handles = try Handles(
        network: .mainnet,
        environmentVariable: "HANDLES_API_KEY"
    )
} catch HandlesError.missingAPIKey(let message) {
    print("API key missing: \(message ?? "")")
    // Guide user to set up their API key
}
```

#### valueError

Thrown for invalid parameter values:

```swift
do {
    // Some operation with invalid input
    throw HandlesError.valueError("Invalid handle name format")
} catch HandlesError.valueError(let message) {
    print("Value error: \(message ?? "")")
}
```

## API Response Errors

### HTTP Status Codes

The OpenAPI-generated client handles different HTTP responses:

```swift
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "my.handle")
    )
)

switch response {
case .ok(let okResponse):
    // 200: Success
    let handle = try okResponse.body.json
    print("Found: \(handle.name ?? "")")
    
case .accepted(let acceptedResponse):
    // 202: Success, but data may be slightly outdated
    let handle = try acceptedResponse.body.json
    print("Data (blockchain catching up): \(handle.name ?? "")")
    
case .badRequest(let badResponse):
    // 400: Invalid request parameters
    print("Bad request - check your parameters")
    
case .notFound:
    // 404: Handle doesn't exist
    print("Handle not found")
    
case .undocumented(statusCode: let code, _):
    // Other status codes
    print("Unexpected response: \(code)")
}
```

### Network Errors

Handle network connectivity issues:

```swift
do {
    let response = try await handles.client.getHandlesHandle(
        Operations.GetHandles Handle.Input(
            path: .init(handle: "my.handle")
        )
    )
    let handle = try response.ok.body.json
    
} catch let error as URLError {
    switch error.code {
    case .notConnectedToInternet:
        print("No internet connection")
    case .timedOut:
        print("Request timed out")
    case .cannotFindHost:
        print("Cannot reach API server")
    case .networkConnectionLost:
        print("Connection lost")
    default:
        print("Network error: \(error.localizedDescription)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Decoding Errors

Handle JSON parsing failures:

```swift
do {
    let response = try await handles.client.getHandlesHandle(
        Operations.GetHandlesHandle.Input(
            path: .init(handle: "my.handle")
        )
    )
    let handle = try response.ok.body.json
    
} catch let error as DecodingError {
    switch error {
    case .keyNotFound(let key, let context):
        print("Missing key '\(key.stringValue)': \(context.debugDescription)")
    case .typeMismatch(let type, let context):
        print("Type mismatch for \(type): \(context.debugDescription)")
    case .valueNotFound(let type, let context):
        print("Missing value for \(type): \(context.debugDescription)")
    case .dataCorrupted(let context):
        print("Data corrupted: \(context.debugDescription)")
    @unknown default:
        print("Decoding error: \(error)")
    }
}
```

## Comprehensive Error Handling Pattern

### Unified Error Handler

Create a comprehensive error handler:

```swift
func handleAPIError(_ error: Error) {
    switch error {
    // Library-specific errors
    case HandlesError.invalidBasePath(let message):
        print("Configuration error: \(message ?? "Invalid base path")")
        
    case HandlesError.missingAPIKey(let message):
        print("Authentication error: \(message ?? "API key not found")")
        
    case HandlesError.valueError(let message):
        print("Invalid input: \(message ?? "Value error")")
        
    // Network errors
    case let urlError as URLError:
        handleNetworkError(urlError)
        
    // Decoding errors
    case let decodingError as DecodingError:
        handleDecodingError(decodingError)
        
    // Generic errors
    default:
        print("Unexpected error: \(error.localizedDescription)")
    }
}

func handleNetworkError(_ error: URLError) {
    switch error.code {
    case .notConnectedToInternet:
        showAlert("No internet connection. Please check your network.")
    case .timedOut:
        showAlert("Request timed out. Please try again.")
    case .cannotFindHost, .cannotConnectToHost:
        showAlert("Cannot reach the API server.")
    default:
        showAlert("Network error: \(error.localizedDescription)")
    }
}

func handleDecodingError(_ error: DecodingError) {
    print("Failed to parse API response: \(error)")
    showAlert("Received unexpected data from the server.")
}
```

### Usage

```swift
do {
    let response = try await handles.client.getHandlesHandle(
        Operations.GetHandlesHandle.Input(
            path: .init(handle: "my.handle")
        )
    )
    let handle = try response.ok.body.json
    // Process handle
    
} catch {
    handleAPIError(error)
}
```

## Retry Logic

### Simple Retry

Implement basic retry logic:

```swift
func fetchHandleWithRetry(
    _ name: String,
    maxAttempts: Int = 3
) async throws -> Components.Schemas.Handle {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            let response = try await handles.client.getHandlesHandle(
                Operations.GetHandlesHandle.Input(
                    path: .init(handle: name)
                )
            )
            return try response.ok.body.json
            
        } catch {
            lastError = error
            print("Attempt \(attempt) failed: \(error)")
            
            if attempt < maxAttempts {
                // Wait before retrying
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    throw lastError ?? HandlesError.valueError("All retry attempts failed")
}
```

### Exponential Backoff

Implement exponential backoff for rate limiting:

```swift
func fetchHandleWithBackoff(
    _ name: String,
    maxAttempts: Int = 5
) async throws -> Components.Schemas.Handle {
    var attempt = 0
    var delay: TimeInterval = 1.0
    
    while attempt < maxAttempts {
        do {
            let response = try await handles.client.getHandlesHandle(
                Operations.GetHandlesHandle.Input(
                    path: .init(handle: name)
                )
            )
            return try response.ok.body.json
            
        } catch let error as URLError where error.code == .cannotConnectToHost {
            // Don't retry connection errors
            throw error
            
        } catch {
            attempt += 1
            
            if attempt >= maxAttempts {
                throw error
            }
            
            print("Attempt \(attempt) failed, retrying in \(delay)s...")
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Exponential backoff with jitter
            delay = min(delay * 2, 30) // Cap at 30 seconds
            delay += Double.random(in: 0...1) // Add jitter
        }
    }
    
    throw HandlesError.valueError("Max retry attempts reached")
}
```

## User-Friendly Error Messages

### Convert Errors to User Messages

```swift
func userFriendlyMessage(for error: Error) -> String {
    switch error {
    case HandlesError.missingAPIKey:
        return "API key is not configured. Please check your settings."
        
    case HandlesError.invalidBasePath:
        return "Invalid API configuration. Please contact support."
        
    case let urlError as URLError where urlError.code == .notConnectedToInternet:
        return "You appear to be offline. Please check your internet connection."
        
    case let urlError as URLError where urlError.code == .timedOut:
        return "The request took too long. Please try again."
        
    case is DecodingError:
        return "Received unexpected data from the server. Please try again later."
        
    default:
        return "An unexpected error occurred. Please try again."
    }
}

// Usage in SwiftUI
struct HandleView: View {
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            // ... your view content
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            do {
                try await fetchHandle()
            } catch {
                errorMessage = userFriendlyMessage(for: error)
            }
        }
    }
}
```

## Logging and Debugging

### Debug Logging

Add logging for debugging:

```swift
import os.log

let logger = Logger(subsystem: "com.example.app", category: "HandlesAPI")

func fetchHandle(_ name: String) async throws -> Components.Schemas.Handle {
    logger.info("Fetching handle: \(name)")
    
    do {
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: name)
            )
        )
        
        let handle = try response.ok.body.json
        logger.info("Successfully fetched handle: \(name)")
        return handle
        
    } catch {
        logger.error("Failed to fetch handle \(name): \(error.localizedDescription)")
        throw error
    }
}
```

## Best Practices

### 1. Always Handle Errors

Never silently ignore errors:

```swift
// ❌ Don't ignore errors
_ = try? await handles.client.getHandlesHandle(...)

// ✅ Handle errors appropriately
do {
    let response = try await handles.client.getHandlesHandle(...)
    let handle = try response.ok.body.json
    // Process handle
} catch {
    handleAPIError(error)
}
```

### 2. Provide Context

Add context to errors:

```swift
do {
    let response = try await handles.client.getHandlesHandle(
        Operations.GetHandlesHandle.Input(
            path: .init(handle: handleName)
        )
    )
    return try response.ok.body.json
} catch {
    throw HandlesError.valueError(
        "Failed to fetch handle '\(handleName)': \(error.localizedDescription)"
    )
}
```

### 3. Fail Gracefully

Provide fallbacks when appropriate:

```swift
func fetchHandleOrDefault(_ name: String) async -> Components.Schemas.Handle? {
    do {
        let response = try await handles.client.getHandlesHandle(
            Operations.GetHandlesHandle.Input(
                path: .init(handle: name)
            )
        )
        return try response.ok.body.json
    } catch {
        logger.warning("Failed to fetch handle, using fallback: \(error)")
        return nil  // Or return a default/cached value
    }
}
```

### 4. Test Error Paths

Write tests for error scenarios (see <doc:TestingYourCode>):

```swift
@Test("Handle missing API key error")
func testMissingAPIKey() async throws {
    #expect(throws: HandlesError.missingAPIKey) {
        try Handles(
            network: .mainnet,
            environmentVariable: "NONEXISTENT_KEY"
        )
    }
}
```

## See Also

- ``HandlesError``
- ``Handles``
- <doc:AuthenticationGuide>
- <doc:TestingYourCode>
- <doc:WorkingWithHandles>
