import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes

/// Cardano network environments supported by the API.
///
/// Select the appropriate network when initializing a ``Handles`` client. Each network has its own
/// set of handles, holders, and blockchain data.
///
/// ## Example
///
/// ```swift
/// // Production network with live handles
/// let handles = try Handles(network: .mainnet, apiKey: "your-key")
/// ```
///
/// ## Topics
/// ### Network Cases
/// - ``mainnet``
public enum Network {
    /// The production Cardano network.
    ///
    /// Use mainnet for production applications with real ADA and live handle data.
    /// This network contains all minted handles and actual blockchain transactions.
    case mainnet
//    case preprod
//    case preview
//    case guild
//    case sancho
    
    /// Returns the API base URL for this network.
    ///
    /// Each network maps to a specific API endpoint defined in the OpenAPI specification.
    ///
    /// - Returns: The base URL for the network's API endpoint.
    /// - Throws: An error if the network URL cannot be determined.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let url = try Network.mainnet.url()
    /// print(url) // https://api.handle.me
    /// ```
    public func url() throws -> URL {
        switch self {
            case .mainnet:
                return try Servers.Server1.url()
//            case .guild:
//                return try Servers.Server2.url()
//            case .preview:
//                return try Servers.Server3.url()
//            case .preprod:
//                return try Servers.Server4.url()
//            case .sancho:
//                return try Servers.Server5.url()
        }
    }
}

extension HTTPField.Name {
    /// The Authorization HTTP header field name.
    public static var authorization: Self { .init("authorization")! }
}

/// OpenAPI middleware that injects Bearer token authentication into API requests.
///
/// This middleware automatically adds an `Authorization` header with a Bearer token to all
/// outgoing requests. It's configured automatically when you provide an API key to the
/// ``Handles`` initializer.
///
/// ## Authentication Flow
///
/// 1. You provide an API key to ``Handles``
/// 2. `AuthenticationMiddleware` is created with your key
/// 3. The middleware intercepts every request
/// 4. Adds `Authorization: Bearer <your-key>` to the request headers
/// 5. The API server validates the token
///
/// ## Example
///
/// ```swift
/// // Automatic configuration via Handles
/// let handles = try Handles(network: .mainnet, apiKey: "your-key")
///
/// // Manual configuration (advanced)
/// let middleware = AuthenticationMiddleware(
///     authorizationHeaderFieldValue: "your-key"
/// )
/// let client = Client(
///     serverURL: serverURL,
///     transport: URLSessionTransport(),
///     middlewares: [middleware]
/// )
/// ```
///
/// > Warning: Requests without authentication are subject to strict rate limiting.
package struct AuthenticationMiddleware {
    
    /// The value for the `Authorization` header field.
    private let authorization: String
    
    /// Creates authentication middleware with the specified API key.
    ///
    /// The API key is automatically formatted as a Bearer token.
    ///
    /// - Parameter authorization: The API key to use for authentication.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let middleware = AuthenticationMiddleware(
    ///     authorizationHeaderFieldValue: "your-api-key"
    /// )
    /// // Requests will include: Authorization: Bearer your-api-key
    /// ```
    package init(authorizationHeaderFieldValue authorization: String) { self.authorization = "Bearer \(authorization)" }
}

extension AuthenticationMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        // Adds the `Authorization` header field with the provided value.
        request.headerFields[.authorization] = authorization
        return try await next(request, body, baseURL)
    }
}

/// A convenience wrapper for the ADA Handle Public API client.
///
/// `Handles` simplifies initialization and configuration of the OpenAPI-generated client,
/// providing easy access to handle data, holder information, and blockchain statistics
/// for the Cardano ecosystem.
///
/// ## Features
///
/// - Type-safe API operations generated from OpenAPI specification
/// - Automatic Bearer token authentication
/// - Multiple network support (mainnet, testnets)
/// - Environment variable-based API key configuration
/// - Custom base URL support for proxies and self-hosted instances
///
/// ## Basic Usage
///
/// ```swift
/// import SwiftHandlesAPI
///
/// // Create client with API key
/// let handles = try Handles(
///     network: .mainnet,
///     apiKey: "your-api-key"
/// )
///
/// // Fetch a handle
/// let response = try await handles.client.getHandlesHandle(
///     Operations.GetHandlesHandle.Input(
///         path: .init(handle: "adahandle")
///     )
/// )
///
/// let handle = try response.ok.body.json
/// print("Handle: \(handle.name ?? "")")
/// ```
///
/// ## Environment Variables
///
/// ```swift
/// // Set environment variable first:
/// // export HANDLES_API_KEY="your-api-key"
///
/// let handles = try Handles(
///     network: .mainnet,
///     environmentVariable: "HANDLES_API_KEY"
/// )
/// ```
///
/// ## Topics
/// ### Creating a Client
/// - ``init(network:apiKey:basePath:environmentVariable:client:)``
///
/// ### Properties
/// - ``client``
/// - ``network``
/// - ``apiKey``
public struct Handles {
    /// The underlying OpenAPI-generated client for making API requests.
    ///
    /// Use this property to access all API operations defined in the OpenAPI specification.
    /// Operations are organized in the `Operations` namespace with type-safe inputs and outputs.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let response = try await handles.client.getHandlesHandle(
    ///     Operations.GetHandlesHandle.Input(
    ///         path: .init(handle: "my.handle")
    ///     )
    /// )
    /// let handle = try response.ok.body.json
    /// ```
    public let client: Client
    
    /// The Cardano network this client is configured for.
    ///
    /// Each network (mainnet, preprod, etc.) has its own set of handles and blockchain data.
    public let network: Network
    
    /// The API key used for authentication, if provided.
    ///
    /// Returns `nil` if the client was created without authentication.
    /// Requests without an API key are subject to strict rate limiting.
    public let apiKey: String?
    
    /// Creates a new Handles API client.
    ///
    /// Initialize a client by specifying the network and providing an API key either directly,
    /// via an environment variable, or by passing a pre-configured OpenAPI client.
    ///
    /// - Parameters:
    ///   - network: The Cardano network to connect to (e.g., `.mainnet`).
    ///   - apiKey: Optional API key for authentication. If provided, all requests will
    ///     include Bearer token authentication.
    ///   - basePath: Optional custom base URL. Useful for proxies, self-hosted instances,
    ///     or development servers. If omitted, uses the default URL for the selected network.
    ///   - environmentVariable: Optional name of an environment variable containing the API key.
    ///     If specified, the API key will be read from this environment variable.
    ///   - client: Optional pre-configured OpenAPI `Client` instance. Use this for advanced
    ///     customization of transport, middleware, or timeout configuration.
    ///
    /// - Throws:
    ///   - ``HandlesError/invalidBasePath(_:)`` if the `basePath` is not a valid URL.
    ///   - ``HandlesError/missingAPIKey(_:)`` if `environmentVariable` is specified but the
    ///     environment variable is not set or empty.
    ///
    /// ## Examples
    ///
    /// Basic initialization:
    /// ```swift
    /// let handles = try Handles(
    ///     network: .mainnet,
    ///     apiKey: "your-api-key"
    /// )
    /// ```
    ///
    /// Using environment variable:
    /// ```swift
    /// // Set first: export HANDLES_API_KEY="your-key"
    /// let handles = try Handles(
    ///     network: .mainnet,
    ///     environmentVariable: "HANDLES_API_KEY"
    /// )
    /// ```
    ///
    /// Custom base URL:
    /// ```swift
    /// let handles = try Handles(
    ///     network: .mainnet,
    ///     apiKey: "your-key",
    ///     basePath: "https://api-proxy.example.com"
    /// )
    /// ```
    ///
    /// Advanced: custom client:
    /// ```swift
    /// let customClient = Client(
    ///     serverURL: URL(string: "https://api.handle.me")!,
    ///     transport: customTransport,
    ///     middlewares: [customMiddleware]
    /// )
    /// let handles = try Handles(
    ///     network: .mainnet,
    ///     apiKey: "your-key",
    ///     client: customClient
    /// )
    /// ```
    public init(
        network: Network,
        apiKey: String? = nil,
        basePath: String? = nil,
        environmentVariable: String? = nil,
        client: Client? = nil
    ) throws {
        self.network = network
        
        if let apiKey = apiKey {
            self.apiKey = apiKey
        } else if let environmentVariable = environmentVariable {
            guard let apiKey = ProcessInfo.processInfo.environment[environmentVariable],
                  !apiKey.isEmpty else {
                throw HandlesError.missingAPIKey("Environment variable \(environmentVariable) is not set or empty.")
            }
            self.apiKey = apiKey
        } else {
            self.apiKey = apiKey
        }
        
        let serverURL: URL
        if let basePath = basePath {
            guard let url = URL(string: basePath) else {
                throw HandlesError.invalidBasePath("Invalid base path: \(basePath)")
            }
            serverURL = url
        } else {
            guard let url = try? network.url() else {
                throw HandlesError.invalidBasePath("Could not determine server URL for network \(network).")
            }
            serverURL = url
        }
        
        self.client = client ?? Client(
            serverURL: serverURL,
            transport: URLSessionTransport(),
            middlewares: (self.apiKey != nil) ? [AuthenticationMiddleware(authorizationHeaderFieldValue: self.apiKey!)] : []
        )
    }
    
}
