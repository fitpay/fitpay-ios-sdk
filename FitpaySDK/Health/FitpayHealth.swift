import Foundation
import Alamofire

public class FitpayHealth {
    public enum APIStatus {
        case OK
        case DEGRADED
        case MAINTENANCE
        case UNAVAILABLE
    }
    
    public typealias StatusHandler = (_ status: APIStatus?, _ error: Error?) -> Void
    
    // custom session manager avoids results being cached
    private static let manager: SessionManager = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return SessionManager(configuration: config)
    }()

    public static func getApiStatus(completion: @escaping StatusHandler) {
        manager.request("\(FitpayConfig.apiURL)/health")
            .validate()
            .responseJSON { response in
            switch response.result {
            case .success:
                if response.error != nil {
                    completion(nil, response.error)
                } else if let json = response.value as? [String: Any] {
                    switch json["status"] as? String {
                    case "OK":
                        completion(.OK, nil)
                    case "DEGRADED":
                        log.warning("FITPAY_HEALTH: API health is Degraded")
                        completion(.DEGRADED, nil)
                    default:
                        log.warning("FITPAY_HEALTH: API health is Unavailable")
                        completion(.UNAVAILABLE, nil)
                    }
                } else {
                    log.warning("FITPAY_HEALTH: Unable to retrieve api health. Assumeing api is unavailable.")
                    completion(.UNAVAILABLE, nil)
                }
            case let .failure(error):
                switch response.response?.statusCode {
                case 503:
                    let headers = response.response?.allHeaderFields
                    if ((headers?["maintenance-mode"] ?? headers?["Maintenance-Mode"]) as? String) ?? "" == "true" {
                        log.error("FITPAY_HEALTH: API health check found that the API is in Maintenence Mode!")
                        completion(.MAINTENANCE, nil)
                    } else {
                        fallthrough
                    }
                default:
                    log.error("FITPAY_HEALTH: Unable to check API health. Error: \(error)")
                    completion(nil, error)
                }
            }
        }
    }
    
    /**
     Check if Fitpay is in maintenance mode
     
     - parameter completion: closure which gets true passed to it if we are in maintenance mode
     
     - note: If services are unavailable for a reason other than maintenance mode, this returns false. To check for overall health, use `getApiStatus` instead
     */
    public static func getMaintenanceMode(completion: @escaping (_ maintenanceMode: Bool) -> Void) {
        getApiStatus {status, err in completion(status == APIStatus.MAINTENANCE)}
    }
}
