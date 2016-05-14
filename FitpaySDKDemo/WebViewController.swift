
import UIKit
import WebKit
import FitpaySDK
import ObjectMapper

class WebViewController: UIViewController {
    @IBOutlet var containerView : UIView! = nil
    var webView = WKWebView()
    var fp: FPWebView?
    
    override func viewDidLoad() {
        let device = PaymentDevice();
        device.changeDeviceInterface(MockPaymentDeviceInterface(paymentDevice: device))

        fp = FPWebView(clientId: "pagare", redirectUri: "http://example.com", paymentDevice: device)
        let config:WKWebViewConfiguration = fp!.wvConfig()
        
        self.view.frame = self.view.bounds
        self.webView = WKWebView(frame: self.view.frame, configuration: config)
        
        self.view = self.webView
        self.webView.loadRequest((fp!.wvRequest()))
        fp?.setWebView(webView)

        bindToEvents()
    }

    private func bindToEvents() {
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CARD_ADDED, completion: {
            (event) in
            print("got card added event")
        })

        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CARD_DELETED, completion: {
            (event) in
            print("got card deleted event")
        })

        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CARD_REACTIVATED, completion: {
            (event) in
            print("got card reactivated event")
        })

        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CARD_DEACTIVATED, completion: {
            (event) in
            print("got card deactivated event")
        })

        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SET_DEFAULT_CARD, completion: {
            (event) in
            print("got card set default event")
        })

        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.RESET_DEFAULT_CARD, completion: {
            (event) in
            print("got card reset default event")
        })
    }
}