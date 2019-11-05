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

    public static func getApiStatus(completion: @escaping StatusHandler) {
        Alamofire.request("\(FitpayConfig.apiURL)/health").responseJSON { response in
            if response.error != nil {
                completion(nil, response.error)
            } else if let json = response.value as? [String: Any] {
                if response.response?.statusCode == 503, let maintenanceMode = json["Maintenance-Mode"] as? Bool {
                    if maintenanceMode {
                        log.error("FITPAY_HEALTH: API health check found that the API is in Maintenence Mode!")
                        completion(.MAINTENANCE, nil)
                    }
                } else {
                    switch json["status"] as? String {
                    case "OK":
                        completion(.OK, nil)
                    case "DEGRADED":
                        log.warning("FITPAY_HEALTH: API health is Degraded")
                        completion(.DEGRADED, nil)
                    default:
                        completion(.UNAVAILABLE, nil)
                    }
                }
            } else {
                log.warning("FITPAY_HEALTH: Unable to retrieve api health. Assumeing api is unavailable.")
                completion(.UNAVAILABLE, nil)
            }
        }
    }
    
    public static func getMaintenanceMode(completion: @escaping (_ maintenanceMode: Bool) -> Void) {
        getApiStatus {status, err in completion(status == APIStatus.MAINTENANCE)}
    }
}
