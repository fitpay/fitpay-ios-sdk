import Foundation

open class ImageWithOptions: Image {

    private static let selfResourceKey = "self"

    open func retrieveAssetWith(options: [ImageAssetOption] = [], completion: @escaping RestClient.AssetsHandler) {
        let resource = ImageWithOptions.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client, let urlString = updateUrlAssetWith(urlString: url, options: options) {
            client.assets(urlString, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: Image.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
    
    func updateUrlAssetWith(urlString: String, options: [ImageAssetOption]) -> String? {
        guard var url = URLComponents(string: urlString) else { return urlString }
        guard url.queryItems != nil else { return urlString }
        
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
    
}
