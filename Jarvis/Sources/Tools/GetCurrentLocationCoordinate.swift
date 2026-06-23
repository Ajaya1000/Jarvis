//
//  GetCurrentLocationCoordinate.swift
//  Jarvis
//
//  Created by Ajaya Mati on 23/06/26.
//

import LiteRTLM
import Foundation

struct GetCurrentLocationCoordinate: Tool {
    static let name = "get_current_location_coordinate"
    static let description: String = "Get current location coordinate"
    
    func run() async throws -> Any {
        let location = try await LocationUtil().getCurrentLocation()
        return ["latitude": location.latitude, "longitude": location.longitude]
    }
}
