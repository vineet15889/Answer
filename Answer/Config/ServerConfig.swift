import Foundation

struct ServerConfig {
    static let baseURL = "https://answers-ai-ios.replit.app"
    
    struct Endpoints {
        static let translate = "/translate"
    }
    
    static func getTranslateURL() -> String {
        return baseURL + Endpoints.translate
    }
}