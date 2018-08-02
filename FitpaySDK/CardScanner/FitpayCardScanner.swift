import Foundation

@objc public protocol FitpayCardScannerPresenterDelegate: NSObjectProtocol {
    func shouldPresentCardScanner(scanner: IFitpayCardScanner)
    func shouldDissmissCardScanner(scanner: IFitpayCardScanner)
}

@objc public protocol FitpayCardScannerDataSource: NSObjectProtocol {
    func cardScanner() -> IFitpayCardScanner
}

@objc public protocol FitpayCardScannerDelegate: NSObjectProtocol {
    func scanned(card: ScannedCardInfo?, error: Error?)
    func canceled()
}

@objc public protocol IFitpayCardScanner: NSObjectProtocol {
    weak var scanDelegate: FitpayCardScannerDelegate! { get set }
}
