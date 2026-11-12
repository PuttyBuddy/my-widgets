import Foundation

/// 单日预报
struct DayForecast: Codable, Identifiable {
    var weekday: String
    var symbol: String
    var min: Double
    var max: Double

    var id: String { weekday }
}

/// 天气数据（Open-Meteo 免费接口，无需 API Key）
struct WeatherData: Codable {
    var city: String
    var temp: Double
    var tempMin: Double
    var tempMax: Double
    var humidity: Int
    var windDir: String
    var precipProb: Int
    var uvIndex: Double
    var sunrise: String
    var sunset: String
    var conditionSymbol: String
    var conditionText: String
    var hourlyTemps: [Double]
    var daily: [DayForecast]?
    var fetchedAt: Date

    var tempText: String { String(format: "%.0f°", temp) }
    var uvText: String { String(format: "%.0f", uvIndex) }
}

enum WeatherService {
    /// 把城市名变成坐标，再拉取当前天气
    static func fetchWeather(city: String) async throws -> WeatherData {
        var clean = city.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { clean = "北京" }

        // 1. 地理编码
        let geoURL = "https://geocoding-api.open-meteo.com/v1/search?name=\(clean.urlEncoded)&count=1&language=zh&format=json"
        let geoData = try await jsonData(from: geoURL)
        let geo = try JSONDecoder().decode(GeoResponse.self, from: geoData)
        guard let place = geo.results?.first else {
            throw URLError(.cannotFindHost)
        }

        // 2. 天气预报
        let lat = place.latitude, lon = place.longitude
        let url = "https://api.open-meteo.com/v1/forecast" +
            "?latitude=\(lat)&longitude=\(lon)" +
            "&current=temperature_2m,relative_humidity_2m,weather_code,wind_direction_10m,uv_index" +
            "&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weather_code" +
            "&hourly=precipitation_probability,temperature_2m" +
            "&forecast_days=7&timezone=auto"
        let data = try await jsonData(from: url)
        let resp = try JSONDecoder().decode(ForecastResponse.self, from: data)

        let displayName = place.name
        let current = resp.current
        let symbolInfo = Self.symbolInfo(code: current.weatherCode)
        let hourIndex = Self.currentHourIndex(times: resp.hourly.time)

        // 一周预报
        var daily: [DayForecast] = []
        let count = min(7, resp.daily.time.count)
        for i in 0..<count {
            let code = i < resp.daily.weatherCode.count ? resp.daily.weatherCode[i] : 0
            daily.append(DayForecast(
                weekday: Self.weekday(resp.daily.time[i]),
                symbol: Self.symbolInfo(code: code).symbol,
                min: resp.daily.temperature2mMin.indices.contains(i) ? resp.daily.temperature2mMin[i] : 0,
                max: resp.daily.temperature2mMax.indices.contains(i) ? resp.daily.temperature2mMax[i] : 0
            ))
        }

        return WeatherData(
            city: displayName,
            temp: current.temperature2m,
            tempMin: resp.daily.temperature2mMin.first ?? current.temperature2m,
            tempMax: resp.daily.temperature2mMax.first ?? current.temperature2m,
            humidity: current.relativeHumidity2m,
            windDir: Self.compass(degrees: current.windDirection10m),
            precipProb: hourIndex < resp.hourly.precipitationProbability.count
                ? (resp.hourly.precipitationProbability[hourIndex] ?? 0) : 0,
            uvIndex: current.uvIndex ?? 0,
            sunrise: Self.hhmm(resp.daily.sunrise.first),
            sunset: Self.hhmm(resp.daily.sunset.first),
            conditionSymbol: symbolInfo.symbol,
            conditionText: symbolInfo.text,
            hourlyTemps: Array(resp.hourly.temperature2m.prefix(12)),
            daily: daily,
            fetchedAt: Date()
        )
    }

    /// "2026-11-12" → "周五"
    static func weekday(_ iso: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        guard let date = inFmt.date(from: iso) else { return "" }
        let outFmt = DateFormatter()
        outFmt.locale = Locale(identifier: "zh_CN")
        outFmt.dateFormat = "EEE"
        return outFmt.string(from: date)
    }

    // MARK: - 内部

    private static func jsonData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    static func symbolInfo(code: Int) -> (symbol: String, text: String) {
        switch code {
        case 0: return ("sun.max.fill", "晴")
        case 1, 2: return ("cloud.sun.fill", "局部多云")
        case 3: return ("cloud.fill", "阴")
        case 45, 48: return ("cloud.fog.fill", "雾")
        case 51...57: return ("cloud.drizzle.fill", "毛毛雨")
        case 61...67: return ("cloud.rain.fill", "雨")
        case 71...77: return ("cloud.snow.fill", "雪")
        case 80...82: return ("cloud.heavyrain.fill", "阵雨")
        case 85, 86: return ("cloud.snow.fill", "阵雪")
        case 95...99: return ("cloud.bolt.rain.fill", "雷阵雨")
        default: return ("cloud.sun.fill", "多云")
        }
    }

    static func compass(degrees: Int) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int((Double(degrees) / 45).rounded()) % 8
        return dirs[idx]
    }

    private static func currentHourIndex(times: [String]) -> Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:'00'"
        let key = fmt.string(from: Date())
        if let idx = times.firstIndex(of: key) { return idx }
        return min(times.count - 1, max(0, Calendar.current.component(.hour, from: Date())))
    }

    private static func hhmm(_ iso: String?) -> String {
        guard let iso, let t = iso.split(separator: "T").last else { return "--:--" }
        return String(t.prefix(5))
    }

    // MARK: - 响应模型

    private struct GeoResponse: Decodable {
        struct Place: Decodable {
            let name: String
            let latitude: Double
            let longitude: Double
        }
        let results: [Place]?
    }

    private struct ForecastResponse: Decodable {
        struct Current: Decodable {
            let temperature2m: Double
            let relativeHumidity2m: Int
            let weatherCode: Int
            let windDirection10m: Int
            let uvIndex: Double?

            enum CodingKeys: String, CodingKey {
                case temperature2m = "temperature_2m"
                case relativeHumidity2m = "relative_humidity_2m"
                case weatherCode = "weather_code"
                case windDirection10m = "wind_direction_10m"
                case uvIndex = "uv_index"
            }
        }
        struct Daily: Decodable {
            let time: [String]
            let temperature2mMax: [Double]
            let temperature2mMin: [Double]
            let sunrise: [String]
            let sunset: [String]
            let weatherCode: [Int]

            enum CodingKeys: String, CodingKey {
                case time
                case temperature2mMax = "temperature_2m_max"
                case temperature2mMin = "temperature_2m_min"
                case sunrise, sunset
                case weatherCode = "weather_code"
            }
        }
        struct Hourly: Decodable {
            let time: [String]
            let precipitationProbability: [Int?]
            let temperature2m: [Double]

            enum CodingKeys: String, CodingKey {
                case time
                case precipitationProbability = "precipitation_probability"
                case temperature2m = "temperature_2m"
            }
        }
        let current: Current
        let daily: Daily
        let hourly: Hourly
    }
}

extension String {
    var urlEncoded: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
