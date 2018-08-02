public protocol FitpayEventListener {
    func dispatchEvent(_ event: FitpayEvent)
    func invalidate()
}
