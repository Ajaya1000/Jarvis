//
//  Constants.swift
//  Jarvis
//
//  Created by Ajaya Mati on 23/06/26.
//

enum Constants {
    static let weatherBaseURL = "https://api.open-meteo.com/v1/forecast"
    
    enum QueryParamNames {
        static let lat = "latitude"
        static let long = "longitude"
        static let hourly = "hourly"
        static let temp_2m = "temperature_2m"
        static let forecast_days = "forecast_days"
    }
}
