//
//  GetCurrentWeatherTool.swift
//  Jarvis
//
//  Created by Ajaya Mati on 22/06/26.
//

import Foundation
import LiteRTLM

struct GetCurrentWeatherTool: Tool {
    static let name: String = "get_current_weather"
    static let description: String = "Get current weather for a location. Requires latitude and longitude as decimal numbers."
    
    @ToolParam(description: "Latitude of the location (required, e.g., 40.7128)")
    var lat: Double
    
    @ToolParam(description: "Longitude of the location (required, e.g., -74.0060)")
    var long: Double
    
    func run() async throws -> Any {
        guard var url = URL(string: Constants.weatherBaseURL) else {
            throw NSError(domain: "com.location", code: 404, userInfo: [NSLocalizedDescriptionKey: "URL is invalid"])
        }
                
        let queryItems = [
            URLQueryItem(name: Constants.QueryParamNames.lat,
                         value: "\(lat)"),
            URLQueryItem(name: Constants.QueryParamNames.long,
                         value: "\(long)"),
            URLQueryItem(name: Constants.QueryParamNames.hourly,
                         value: "temperature_2m,rain,wind_speed_10m"),
            URLQueryItem(name: Constants.QueryParamNames.forecast_days,
                         value: "1"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        url = url.appending(queryItems: queryItems)
        
        let response: OpenMeteoResponse = try await NetworkClient.shared.request(url: url)
        
        return preProcess(response: response)
    }
    
    func preProcess(response: OpenMeteoResponse) -> Any {
        var data: [String: Any] = ["temperature_unit": response.hourly_units.temperature_2m,
                                   "rain_unit": response.hourly_units.rain,
                                   "wind_speed_unit": response.hourly_units.wind_speed_10m]
        let l = response.hourly.time.count
        
        var weather_data: [[String: Any]] = []
        for i in 0..<l {
            let hour = response.hourly.time[i]
            let temp = response.hourly.temperature_2m[i]
            let rain = response.hourly.rain[i]
            let wind_speed = response.hourly.wind_speed_10m[i]
            
            weather_data.append(["time_of_day": hour, "temperature": temp, "rain": rain, "wind_speed": wind_speed ])
        }
        
        data["weather_data"] = weather_data
        
        return data
    }
}

struct OpenMeteoResponse: Decodable {
    let hourly_units: HourlyUnit
    let hourly: HourlyData
}

extension OpenMeteoResponse {
    struct HourlyUnit: Decodable {
        let time: String
        let temperature_2m: String
        let rain: String
        let wind_speed_10m: String
    }
    
    struct HourlyData: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let rain: [Double]
        let wind_speed_10m: [Double]
    }
}
