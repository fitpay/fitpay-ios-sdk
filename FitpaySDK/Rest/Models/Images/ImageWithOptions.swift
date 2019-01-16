import Foundation

open class ImageWithOptions: Image {

    private static let selfResourceKey = "self"

    // MARK: - Public Functions
    
    open func retrieveAssetWith(options: [ImageAssetOption] = [], completion: @escaping RestClient.AssetsHandler) {
        let resource = ImageWithOptions.selfResourceKey

        guard let url = links?.url(resource), let client = client, var urlString = updateUrlAssetWith(urlString: url, options: options) else {
            completion(nil, composeError(resource))
            return
        }
        
        urlString += "&embossedText=%E2%80%A2%E2%80%A2%E2%80%A2%E2%80%A2+1114"
        
        client.assets(urlString, completion: completion)

    }
    
    // MARK: - Private Functions
    
    private func updateUrlAssetWith(urlString: String, options: [ImageAssetOption]) -> String? {
        guard var url = URLComponents(string: urlString), url.queryItems != nil else { return urlString }
        
        for option in options {
            var optionFound = false
            for (i, queryItem) in url.queryItems!.enumerated() {
                if queryItem.name == option.urlKey {
                    url.queryItems?[i].value = String(option.urlValue)
                    optionFound = true
                    break
                }
            }
            
            if !optionFound {
                url.queryItems?.append(URLQueryItem(name: option.urlKey, value: option.urlValue))
            }
        }
        
        return (try? url.asURL())?.absoluteString
    }
    
    private func composeError(_ resource: String) -> ErrorResponse? {
        return ErrorResponse.clientUrlError(domain: VerificationMethod.self, client: client, url: links?.url(resource), resource: resource)
    }
    
}
