import Foundation

class NSTimeIntervalTypeTransform: CodingContainerTransformer {
    typealias Output = TimeInterval
    typealias Input = Int64

    func transform(_ decoded: Input?) -> Output? {
        if let timeInt = decoded {
            return TimeInterval(timeInt / 1000)
        }
        return nil
    }

    func transform(_ encoded: Output?) -> Input? {
        if let epoch = encoded {
            let timeInt = Int64(epoch * 1000)
            return timeInt as NSTimeIntervalTypeTransform.Input
        }
        return nil
    }
}

class DecimalNumberTypeTransform: CodingContainerTransformer {
    typealias Output = NSDecimalNumber
    typealias Input = Any

    func transform(_ decoded: Input?) -> Output? {
        if let string = decoded as? String {
            return NSDecimalNumber(string: string)
        } else if let number = decoded as? NSNumber {
            let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 3, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            return NSDecimalNumber(decimal: number.decimalValue).rounding(accordingToBehavior: handler)
        } else if let double = decoded as? Double {
            return NSDecimalNumber(floatLiteral: double)
        }
        return nil
    }

    func transform(_ encoded: Output?) -> Input? {
        guard let value = encoded else { return nil }
        return value.description
    }
}

class CustomDateFormatTransform: CodingContainerTransformer {
    typealias Output = Date
    typealias Input = String

    let dateFormatter: DateFormatter

    public init(formatString: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = formatString

        self.dateFormatter = formatter
    }

    func transform(_ decoded: Input?) -> Output? {
        if let dateString = decoded {
            return dateFormatter.date(from: dateString)
        }
        return nil
    }

    func transform(_ encoded: Output?) -> Input? {
        if let date = encoded {
            return dateFormatter.string(from: date)
        }
        return nil
    }
}

class DateToIntTransform: CodingContainerTransformer {
    typealias Output = Date
    typealias Input = Int
    
    func transform(_ decoded: Input?) -> Output? {
        if let dateInt = decoded {
            let calendar = Calendar.current
            let today = Date()
            return calendar.date(byAdding: .day, value: -dateInt, to: today)
        }
        return nil
    }
    
    func transform(_ encoded: Output?) -> Input? {
        if let date = encoded {
            let calendar = Calendar.current
            
            let date1 = calendar.startOfDay(for: date)
            let date2 = calendar.startOfDay(for: Date())
            
            let components = calendar.dateComponents([.day], from: date1, to: date2)
            return components.day
        }
        return nil
    }
}

