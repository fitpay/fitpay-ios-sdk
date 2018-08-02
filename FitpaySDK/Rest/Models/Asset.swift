import Foundation

/// Only one Asset item available for specific context
open class Asset: NSObject {
    
    open var text: String?
    open var image: UIImage?
    open var data: Data?

    init(text: String) {
        self.text = text
    }

    init(image: UIImage) {
        self.image = image
    }

    init(data: Data) {
        self.data = data
    }
}
