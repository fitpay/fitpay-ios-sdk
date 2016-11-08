
import ObjectMapper

open class Asset : NSObject
{
    // Only one item available for specific context
    var text:String?
    var image:UIImage?
    var data:Data?
    
    init(text:String)
    {
        self.text = text
    }
    
    init(image:UIImage)
    {
        self.image = image
    }
    
    init(data:Data)
    {
        self.data = data
    }
}
