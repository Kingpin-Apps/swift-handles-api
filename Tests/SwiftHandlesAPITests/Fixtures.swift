import Testing
import OpenAPIRuntime
import Foundation
import HTTPTypes
@testable import SwiftHandlesAPI

struct MockTransport: ClientTransport {
    func send(_ request: HTTPTypes.HTTPRequest, body: OpenAPIRuntime.HTTPBody?, baseURL: URL, operationID: String) async throws -> (
        HTTPTypes.HTTPResponse,
        OpenAPIRuntime.HTTPBody?
    ) {
        print("MockTransport sending request for operationID: \(operationID)")
        switch operationID {
            case "get/handles/{handle}":
                // JSON fixture for Components.Schemas.Handle
                let json = """
                {
                  "hex": "string",
                  "name": "my.handle",
                  "handle_type": "handle",
                  "virtual": {
                    "expires_time": 0,
                    "public_mint": true
                  },
                  "holder": "stake1uxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
                  "holder_type": "wallet",
                  "image": "ipfs://hash_of_personalized_image",
                  "standard_image": "ipfs://hash_of_default_image",
                  "image_hash": "05dbb47e32ad6b89074c286a73543bdb957c01f7abf82b2f106584dc99432bb1",
                  "standard_image_hash": "05dbb47e32ad6b89074c286a73543bdb957c01f7abf82b2f106584dc99432bb1",
                  "length": 9,
                  "og": true,
                  "og_number": 0,
                  "rarity": "ultra_rare",
                  "characters": "letters,numbers,special",
                  "numeric_modifiers": "negative,decimal",
                  "sub_length": 0,
                  "sub_rarity": "ultra_rare",
                  "sub_characters": "letters,numbers,special",
                  "sub_numeric_modifiers": "negative,decimal",
                  "default_in_wallet": "my_default_hndl",
                  "pfp_image": "ipfs://Q2de4Fg56tNHy82300000001",
                  "bg_image": "ipfs://Q2de4Fg56tNHy82300000001",
                  "pfp_asset": "94da605878403d07c144fe96cd50fe20c16186dd8d171c78ed6a8768436c6179436861726c6f74746538353338",
                  "bg_asset": "b8842fe3a0eae5011252c16566995d2c8f1bae85d380410cd21ea91f000de140556e646572776f726c645f48616e646c65735f6267",
                  "resolved_addresses": {
                    "ada": "addr1e00000000000000000000000000000000000001",
                    "eth": "addr1e00000000000000000000000000000000000002",
                    "btc": "addr1e00000000000000000000000000000000000003"
                  },
                  "original_address": "addr1e00000000000000000000000000000000000001",
                  "version": "1",
                  "svg_version": "1",
                  "utxo": "8f1d7ec063ce83d93d1bad658886e81568d19ca9bd8dd0e6e268d7be3e33c653#1",
                  "lovelace": 0,
                  "has_datum": true,
                  "created_slot_number": 0,
                  "updated_slot_number": 0
                }
                """
                
                let handle = try JSONDecoder().decode(Components.Schemas.Handle.self, from: Data(json.utf8))
                
                let data = try JSONEncoder().encode(handle)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
            default:
                return (
                    HTTPResponse(status: .notFound),
                    nil
                )
        }
    }
}

