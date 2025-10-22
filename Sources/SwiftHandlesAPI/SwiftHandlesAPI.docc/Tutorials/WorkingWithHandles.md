# Working With Handles

Discover all the API operations available for fetching and searching ADA Handles on the Cardano blockchain.

## Overview

The SwiftHandlesAPI client provides access to a rich set of operations for working with ADA Handles. This guide covers common use cases including fetching specific handles, searching, pagination, and retrieving holder and statistics data.

All operations are type-safe and automatically generated from the OpenAPI specification, with types organized in the `Operations` and `Components.Schemas` namespaces.

## Fetching a Specific Handle

The most common operation is fetching a single handle by its name:

```swift
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "adahandle")
    )
)

let handle = try response.ok.body.json

// Access handle properties
print("Name: \(handle.name ?? "")")
print("Holder: \(handle.holder ?? "")")
print("Rarity: \(handle.rarity?.rawValue ?? "")")
print("Length: \(handle.length ?? 0)")
print("OG Status: \(handle.og ?? false)")

// Access resolved addresses
if let addresses = handle.resolved_addresses {
    print("ADA: \(addresses.ada ?? "")")
    print("ETH: \(addresses.eth ?? "")")
    print("BTC: \(addresses.btc ?? "")")
}
```

### Handle Properties

The `Components.Schemas.Handle` type includes:

- `name` - The handle name (e.g., "my.handle")
- `hex` - Hexadecimal representation
- `holder` - Current holder's address
- `holder_type` - Type of holder (wallet, script, enterprise, other)
- `rarity` - Rarity classification (basic, common, rare, ultra_rare, legendary)
- `length` - Character length
- `og` - Original/OG status
- `personalized` - Personalization status
- `resolved_addresses` - Resolved addresses for various chains
- `utxo` - Transaction hash and output index

## Searching and Filtering Handles

### Basic Search

Search for handles by name pattern:

```swift
let response = try await handles.client.getHandles(
    Operations.GetHandles.Input(
        query: .init(
            search: "ada",
            records_per_page: 50,
            page: 1
        )
    )
)

let handlesList = try response.ok.body.json

for handle in handlesList {
    print("\(handle.name ?? "") - Rarity: \(handle.rarity?.rawValue ?? "")")
}
```

### Advanced Filtering

Apply multiple filters to narrow results:

```swift
let response = try await handles.client.getHandles(
    Operations.GetHandles.Input(
        query: .init(
            length: 5,                                    // Exactly 5 characters
            rarity: .rare,                                // Rare handles only
            og: true,                                      // OG handles only
            characters: .letters,                         // Letters only
            sort: .asc,                                   // Ascending order
            records_per_page: 100,
            page: 1
        )
    )
)

let filtered = try response.ok.body.json
```

### Filter by Holder

Find all handles owned by a specific address:

```swift
let response = try await handles.client.getHandles(
    Operations.GetHandles.Input(
        query: .init(
            holder_address: "stake1u...",
            records_per_page: 50,
            page: 1
        )
    )
)

let holderHandles = try response.ok.body.json
```

### Length Ranges

Search for handles within a length range:

```swift
// Use length parameter with range (e.g., "2-7" for handles between 2 and 7 characters)
// Note: This requires constructing the query parameter appropriately
let response = try await handles.client.getHandles(
    Operations.GetHandles.Input(
        query: .init(
            length: 3,  // Specific length
            records_per_page: 50,
            page: 1
        )
    )
)
```

## Pagination

### Page-Based Pagination

Standard page-based pagination ordered by handle name:

```swift
func fetchAllHandles(searchTerm: String) async throws -> [Components.Schemas.Handle] {
    var allHandles: [Components.Schemas.Handle] = []
    var currentPage = 1
    let pageSize = 100
    
    while true {
        let response = try await handles.client.getHandles(
            Operations.GetHandles.Input(
                query: .init(
                    search: searchTerm,
                    records_per_page: pageSize,
                    page: currentPage
                )
            )
        )
        
        let batch = try response.ok.body.json
        
        if batch.isEmpty {
            break  // No more results
        }
        
        allHandles.append(contentsOf: batch)
        currentPage += 1
        
        // Respect rate limits
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
    }
    
    return allHandles
}
```

### Slot-Based Pagination

For consistent pagination when handles are being created/updated, use slot-based pagination:

```swift
var slotNumber: Int? = nil
let pageSize = 100

repeat {
    let response = try await handles.client.getHandles(
        Operations.GetHandles.Input(
            query: .init(
                slot_number: slotNumber,
                records_per_page: pageSize
            )
        )
    )
    
    let batch = try response.ok.body.json
    
    // Process batch
    for handle in batch {
        print(handle.name ?? "")
    }
    
    // Update slot number for next page
    // The API response should indicate the next slot
    slotNumber = /* extract from response headers or last item */
    
} while batch.count == pageSize
```

### Pagination Metadata

Check response headers for total results:

```swift
let response = try await handles.client.getHandles(
    Operations.GetHandles.Input(
        query: .init(
            search: "cardano",
            records_per_page: 50,
            page: 1
        )
    )
)

// The API includes x-handles-search-total header with total count
// Access via response headers if needed
```

## Fetching Handle UTxO Information

Get the current UTxO for a handle:

```swift
let response = try await handles.client.getHandlesHandleUtxo(
    Operations.GetHandlesHandleUtxo.Input(
        path: .init(handle: "my.handle")
    )
)

let utxo = try response.ok.body.json

print("Transaction: \(utxo.tx_id ?? "")")
print("Index: \(utxo.index ?? 0)")
print("Lovelace: \(utxo.lovelace ?? 0)")
print("Address: \(utxo.address ?? "")")
```

## Working with Holders

### Get Holder Information

Fetch information about a handle holder:

```swift
let response = try await handles.client.getHoldersHolderAddress(
    Operations.GetHoldersHolderAddress.Input(
        path: .init(holder_address: "stake1u...")
    )
)

let holder = try response.ok.body.json

print("Address: \(holder.address ?? "")")
print("Type: \(holder._type?.rawValue ?? "")")
print("Total Handles: \(holder.total_handles ?? 0)")
print("Default Handle: \(holder.default_handle ?? "")")
print("Known Owner: \(holder.known_owner_name ?? "")")
```

## Getting Statistics

Retrieve global handle statistics:

```swift
let response = try await handles.client.getStats()

let stats = try response.ok.body.json

print("Total Handles: \(stats.total_handles ?? 0)")
print("Total Holders: \(stats.total_holders ?? 0)")
print("Total OG Handles: \(stats.og_count ?? 0)")

// Access rarity breakdown if available
if let rarityBreakdown = stats.rarity_breakdown {
    print("Common: \(rarityBreakdown.common ?? 0)")
    print("Rare: \(rarityBreakdown.rare ?? 0)")
    print("Ultra Rare: \(rarityBreakdown.ultra_rare ?? 0)")
    print("Legendary: \(rarityBreakdown.legendary ?? 0)")
}
```

## Handling Different Response Types

### Successful Responses

```swift
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "my.handle")
    )
)

// Parse successful response
let handle = try response.ok.body.json
```

### Checking Response Status

```swift
let response = try await handles.client.getHandlesHandle(
    Operations.GetHandlesHandle.Input(
        path: .init(handle: "my.handle")
    )
)

switch response {
case .ok(let okResponse):
    let handle = try okResponse.body.json
    print("Success: \(handle.name ?? "")")
    
case .accepted(let acceptedResponse):
    // 202: Data may be slightly outdated (blockchain catching up)
    let handle = try acceptedResponse.body.json
    print("Accepted (catching up): \(handle.name ?? "")")
    
case .badRequest:
    print("Invalid request parameters")
    
case .notFound:
    print("Handle not found")
    
case .undocumented(statusCode: let code, _):
    print("Unexpected status: \(code)")
}
```

## Best Practices

### Batch Operations

When fetching multiple handles, batch your requests:

```swift
let handleNames = ["handle1", "handle2", "handle3", "handle4"]

// Use TaskGroup for concurrent requests
await withThrowingTaskGroup(of: Components.Schemas.Handle?.self) { group in
    for name in handleNames {
        group.addTask {
            let response = try await handles.client.getHandlesHandle(
                Operations.GetHandlesHandle.Input(
                    path: .init(handle: name)
                )
            )
            return try? response.ok.body.json
        }
    }
    
    var results: [Components.Schemas.Handle] = []
    for try await handle in group {
        if let handle = handle {
            results.append(handle)
        }
    }
    return results
}
```

### Caching

Implement caching for frequently accessed handles:

```swift
actor HandleCache {
    private var cache: [String: (handle: Components.Schemas.Handle, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 300 // 5 minutes
    
    func get(_ name: String) -> Components.Schemas.Handle? {
        guard let entry = cache[name] else { return nil }
        
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: name)
            return nil
        }
        
        return entry.handle
    }
    
    func set(_ name: String, handle: Components.Schemas.Handle) {
        cache[name] = (handle, Date())
    }
}
```

### Error Handling

See <doc:ErrorHandling> for comprehensive error handling patterns.

## See Also

- ``Handles``
- <doc:ErrorHandling>
- <doc:GettingStarted>
- <doc:AuthenticationGuide>
