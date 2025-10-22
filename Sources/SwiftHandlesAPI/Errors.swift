import Foundation

/// Errors specific to the SwiftHandlesAPI library.
///
/// `HandlesError` defines configuration and initialization errors that occur before
/// any API requests are made. These errors are thrown during client setup when
/// invalid parameters are provided or required configuration is missing.
///
/// For errors that occur during API operations (network errors, HTTP status codes,
/// or JSON decoding failures), use standard Swift error types like `URLError` and
/// `DecodingError`.
///
/// ## Error Handling Pattern
///
/// ```swift
/// do {
///     let handles = try Handles(
///         network: .mainnet,
///         environmentVariable: "HANDLES_API_KEY"
///     )
///
///     let response = try await handles.client.getHandlesHandle(
///         Operations.GetHandlesHandle.Input(
///             path: .init(handle: "my.handle")
///         )
///     )
///
/// } catch HandlesError.invalidBasePath(let message) {
///     print("Invalid URL: \(message ?? "")")
///
/// } catch HandlesError.missingAPIKey(let message) {
///     print("API key not configured: \(message ?? "")")
///
/// } catch HandlesError.valueError(let message) {
///     print("Invalid parameter: \(message ?? "")")
///
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
///
/// ## Topics
/// ### Error Cases
/// - ``invalidBasePath(_:)``
/// - ``missingAPIKey(_:)``
/// - ``valueError(_:)``
enum HandlesError: Error, CustomStringConvertible, Equatable {
    /// An invalid base URL was provided.
    ///
    /// This error is thrown when the `basePath` parameter cannot be converted to a valid URL.
    ///
    /// ## Common Causes
    ///
    /// - Malformed URL string (e.g., "not a url")
    /// - Missing protocol (e.g., "api.handle.me" instead of "https://api.handle.me")
    /// - Invalid characters in the URL
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let handles = try Handles(
    ///         network: .mainnet,
    ///         apiKey: "key",
    ///         basePath: "invalid url"
    ///     )
    /// } catch HandlesError.invalidBasePath(let message) {
    ///     print("Configuration error: \(message ?? "")")
    /// }
    /// ```
    case invalidBasePath(String?)
    
    /// A required API key environment variable is not set or is empty.
    ///
    /// This error is thrown when you specify an environment variable name for API key configuration,
    /// but the environment variable doesn't exist or contains an empty string.
    ///
    /// ## Common Causes
    ///
    /// - Environment variable not set before running the application
    /// - Typo in the environment variable name
    /// - Variable set but contains an empty or whitespace-only value
    ///
    /// ## Example
    ///
    /// ```swift
    /// // HANDLES_API_KEY environment variable not set
    /// do {
    ///     let handles = try Handles(
    ///         network: .mainnet,
    ///         environmentVariable: "HANDLES_API_KEY"
    ///     )
    /// } catch HandlesError.missingAPIKey(let message) {
    ///     print("Please set your API key: \(message ?? "")")
    ///     // Guide user to configure their environment
    /// }
    /// ```
    ///
    /// ## Resolution
    ///
    /// Set the environment variable before running:
    /// ```bash
    /// export HANDLES_API_KEY="your-api-key"
    /// ```
    case missingAPIKey(String?)
    
    /// An invalid parameter or configuration value was provided.
    ///
    /// This error is thrown for general validation failures or invalid parameter values
    /// that don't fit into more specific error categories.
    ///
    /// ## Common Causes
    ///
    /// - Invalid handle name format
    /// - Unsupported network name
    /// - Out-of-range parameter values
    /// - Invalid configuration combinations
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     // Some operation with invalid input
    ///     throw HandlesError.valueError("Handle name cannot be empty")
    /// } catch HandlesError.valueError(let message) {
    ///     print("Validation failed: \(message ?? "")")
    /// }
    /// ```
    case valueError(String?)
    
    var description: String {
        switch self {
            case .invalidBasePath(let message):
                return message ?? "Invalid base path."
            case .missingAPIKey(let message):
                return message ?? "The API Key is missing."
            case .valueError(let message):
                return message ?? "The value is invalid."
        }
    }
}
