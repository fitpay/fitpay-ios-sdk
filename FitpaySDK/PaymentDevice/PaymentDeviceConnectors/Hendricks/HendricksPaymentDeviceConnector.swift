import Foundation
import CoreBluetooth

/// Currently for internal use only and subject to breaking changes at any time.
@objc open class HendricksPaymentDeviceConnector: NSObject {
    
    public var foundPeripherals: [CBPeripheral] = []
    public var connectionPeripheralId: UUID?
    
    public var bleState: CBManagerState = .unknown
    
    private var centralManager: CBCentralManager!
    private var wearablePeripheral: CBPeripheral?
    private var _deviceInfo: Device?
    private var paymentDevice: PaymentDevice?
    
    private let genericServiceId = CBUUID(string: "00001800-0000-1000-8000-00805f9b34fb")
    private let deviceServiceId = CBUUID(string: "7DB2E9EA-ADF6-4F18-A110-61055D64B287")
    
    // in generic service
    private let deviceNameCharacteristicId = CBUUID(string: "00002a00-0000-1000-8000-00805f9b34fb")
    private let appearanceCharacteristicId = CBUUID(string: "00002a01-0000-1000-8000-00805f9b34fb")
    private let preferredParametersCharacteristicId = CBUUID(string: "00002a04-0000-1000-8000-00805f9b34fb")
    private let centralAddressCharacteristicId = CBUUID(string: "00002aa6-0000-1000-8000-00805f9b34fb")
    
    // in device service
    private let statusCharacteristicId = CBUUID(string: "7DB2134A-ADF6-4F18-A110-61055D64B287")
    private let commandCharacteristicId = CBUUID(string: "7DB20256-ADF6-4F18-A110-61055D64B287")
    private let dataCharacteristicId = CBUUID(string: "7DB2E528-ADF6-4F18-A110-61055D64B287")
    private let eventCharacteristicId = CBUUID(string: "7DB2AE05-ADF6-4F18-A110-61055D64B287")
    
    private var expectedDataSize = 0
    private var returnedData: [UInt8] = []
    private var currentPackage: BLEPackage?
    private var packageQueue: [BLEPackage] = []
    
    private var apduCompletion: ((Error?) -> Void)?
    private var apduCommands: [APDUCommand]?
    
    private var commandTimer: Timer?
    private var connectTimer: Timer?
    private var noactivityTimer: Timer?

    private var connectedAndPinged = false
    private var shouldScanOnConnect = false
    
    // MARK: - Lifecycle
    
    @objc public init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Functions
    
    public func addPackagetoQueue(_ blePackage: BLEPackage) {
        packageQueue.enqueue(blePackage)
        processNextCommand()
    }

    public func startScan() {
        foundPeripherals = []
        if bleState == .poweredOn {
            centralManager.scanForPeripherals(withServices: [deviceServiceId], options: nil)
        } else {
            shouldScanOnConnect = true
        }
    }
    
    public func disconnect() {
        if wearablePeripheral != nil {
            centralManager.cancelPeripheralConnection(wearablePeripheral!)
            wearablePeripheral = nil
        }
    }
    
    public func enterBootloader(completion: @escaping () -> Void) {
        let package = BLEPackage(.bootLoader) { _ in
            completion()
        }
        addPackagetoQueue(package)
    }
    
    // Categories
    
    public func getCategories(completion: @escaping ([HendricksCategory]?) -> Void) {
        let package = BLEPackage(.getCategories) { result in
            let categories = result as? [HendricksCategory]
            completion(categories)
        }
        addPackagetoQueue(package)
    }
    
    public func getCategoryObjects(categoryId: Int, completion: @escaping ([HendricksObject]?) -> Void) {
        var catId = categoryId
        let catIdData = Data(bytes: &catId, count: 2)
        
        let package = BLEPackage(.getCatData, commandData: catIdData) { result in
            let objects = result as? [HendricksObject]
            completion(objects)
        }
        
        addPackagetoQueue(package)
    }
    
    public func removeCategoryObject(categoryId: Int, objectId: Int, completion: @escaping () -> Void) {
        var catId = categoryId
        let catIdData = Data(bytes: &catId, count: 2)
        var objId = objectId
        let objIdData = Data(bytes: &objId, count: 2)
        
        let package = BLEPackage(.removeCatObj, commandData: catIdData + objIdData) { _ in
            completion()
        }
        
        addPackagetoQueue(package)
    }
    
    // Credit Card
    
    public func addCreditCard(_ hendricksCard: HendricksCard, completion: @escaping () -> Void) {
        hendricksCard.getCreditCardData { (commandData, data) in
            let package = BLEPackage(.addCard, commandData: commandData, data: data) { _ in
                completion()
            }
            self.addPackagetoQueue(package)
        }
    }
    
    public func activateCreditCard(cardId: String, completion: @escaping () -> Void) {
        guard let cardIdData = cardId.data(using: .utf8)?.paddedTo(byteLength: 37) else { return }
        
        let package = BLEPackage(.activateCard, commandData: cardIdData, data: nil) { _ in
            completion()
        }
        addPackagetoQueue(package)
    }
    
    public func suspendCreditCard(cardId: String, completion: @escaping () -> Void) {
        guard let cardIdData = cardId.data(using: .utf8)?.paddedTo(byteLength: 37) else { return }

        let package = BLEPackage(.suspendCard, commandData: cardIdData, data: nil) { _ in
            completion()
        }
        addPackagetoQueue(package)
    }
    
    // Favorites
    
    public func favoriteObject(categoryId: Int, objectId: Int, completion: @escaping () -> Void) {
        var catId = categoryId
        let catIdData = Data(bytes: &catId, count: 2)
        var objId = objectId
        let objIdData = Data(bytes: &objId, count: 2)
        
        let package = BLEPackage(.addFavCatObj, commandData: catIdData + objIdData) { _ in
            completion()
        }
        
        addPackagetoQueue(package)
    }
    
    // MARK: - Private Functions
    
    private func addCommandtoFrontOfQueue(_ blePackage: BLEPackage) {
        packageQueue.insert(blePackage, at: 0)
        processNextCommand()
    }
    
    private func runCommand() {
        guard currentPackage == nil else {
            log.error("HENDRICKS: Cannot run command while one is already running")
            return
        }
        
        currentPackage = packageQueue.dequeue()
        
        guard let command = currentPackage else {
            // start timer
            log.debug("HENDRICKS: commandQueue is empty")
            return
        }
        
        guard let wearablePeripheral = wearablePeripheral else { return }
        guard let deviceService = wearablePeripheral.services?.first(where: { $0.uuid == deviceServiceId }) else { return }
        
        guard let statusCharacteristic = deviceService.characteristics?.first(where: { $0.uuid == statusCharacteristicId }) else { return }
        guard let commandCharacteristic = deviceService.characteristics?.first(where: { $0.uuid == commandCharacteristicId }) else { return }
        guard let dataCharacteristic = deviceService.characteristics?.first(where: { $0.uuid == dataCharacteristicId }) else { return }
        
        log.debug("HENDRICKS: Running command: \(String(format: "%02X", command.command.rawValue))")
        
        DispatchQueue.global(qos: .background).async {
            if command.command == .factoryReset {
                wearablePeripheral.writeValue(StatusCommand.abort.rawValue.data, for: statusCharacteristic, type: .withResponse)
            }
            
            // start
            wearablePeripheral.writeValue(StatusCommand.start.rawValue.data, for: statusCharacteristic, type: .withResponse)
            
            // add data
            var fullCommandData = command.command.rawValue.data
            if let commandData = command.commandData {
                fullCommandData += commandData
            }
            
            log.debug("HENDRICKS: Running full command: \(fullCommandData.hex)")
            wearablePeripheral.writeValue(fullCommandData, for: commandCharacteristic, type: .withResponse)
            
            if let data = command.data {
                let maxLength = 182
                var startIndex = 0
                while startIndex < data.count {
                    let end = min(startIndex + maxLength, data.count)
                    let parsedData = data[startIndex ..< end]
                    log.verbose("HENDRICKS: putting parsed data: \(parsedData.hex) + \(parsedData.count)")
                    wearablePeripheral.writeValue(parsedData, for: dataCharacteristic, type: .withResponse)
                    startIndex += maxLength
                }
            }
            
            // end
            wearablePeripheral.writeValue(StatusCommand.end.rawValue.data, for: statusCharacteristic, type: .withResponse)
            
            self.commandTimer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(HendricksPaymentDeviceConnector.handleBleIssue), userInfo: nil, repeats: false)
        }
        
    }

    private func resetVariableState() {
        expectedDataSize = 0
        returnedData = []
        currentPackage = nil
        commandTimer?.invalidate()
        commandTimer = nil
        
        processNextCommand()
    }
    
    private func processNextCommand() {
        if currentPackage == nil {
            runCommand()
            
            noactivityTimer?.invalidate()
            noactivityTimer = nil
            noactivityTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(HendricksPaymentDeviceConnector.handleNoActiviy), userInfo: nil, repeats: false)
        }
    }
    
    private func connectTo(peripheral: CBPeripheral) {
        guard centralManager.retrieveConnectedPeripherals(withServices: [deviceServiceId]).isEmpty else {
            //already connected
            return
        }
        
        wearablePeripheral = peripheral
        wearablePeripheral?.delegate = self
        centralManager.connect(wearablePeripheral!, options: nil)
        connectTimer?.invalidate()
        connectTimer = nil
        connectTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(HendricksPaymentDeviceConnector.handleConnectionIssue), userInfo: nil, repeats: false)
        centralManager.stopScan()
        paymentDevice?.connectionState = PaymentDevice.ConnectionState.connecting
    }
    
    // MARK: - Timer Functions
    
    @objc private func handleBleIssue() {
        log.warning("HENDRICKS: Reseting due to no response or invalid response status")
        
        resetVariableState()
    }
    
    @objc private func handleConnectionIssue() {
        log.info("HENDRICKS: Timed out trying to connect to device")
        if wearablePeripheral != nil {
            centralManager.cancelPeripheralConnection(wearablePeripheral!)
            wearablePeripheral = nil
        }
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        paymentDevice?.connectionState = PaymentDevice.ConnectionState.disconnected

       startScan()
    }
    
    @objc private func handleNoActiviy() {
        log.info("HENDRICKS: Disconnecting due to no activity")
        if wearablePeripheral != nil {
            centralManager.cancelPeripheralConnection(wearablePeripheral!)
            wearablePeripheral = nil
        }
        
        foundPeripherals = []
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Response Handlers
    
    private func handleStatusResponse(value: [UInt8]) {
        let status = Data(bytes: Array([value[0]]))
        guard status == BLEResponses.ok.rawValue.data else {
            log.error("HENDRICKS: BLE Response Status not OK")
            handleBleIssue()
            return
        }
        
        if value.count == 1 { //status
            log.debug("HENDRICKS: BLE Response OK with no length")
            currentPackage?.completion?(nil)
            resetVariableState()
            
        } else if value.count == 5 { //length
            log.debug("HENDRICKS: BLE Response OK with length")
            let lengthData = Data(bytes: Array(value[1...4])).hex
            expectedDataSize = Int(UInt32(lengthData, radix: 16)!.bigEndian)
        }
        
    }
    
    private func handleDataResponse(value: [UInt8]) {
        returnedData.append(contentsOf: value)
        
        guard returnedData.count == expectedDataSize else { return }
        guard let currentPackage = currentPackage else { return }

        log.verbose("HENDRICKS: all data received \(Data(bytes: returnedData).hex)")
        
        switch currentPackage.command {
        case .ping:
            handlePingResponse()
            
        case .apduPackage:
            handleAPDUResponse()
            
        case .getCategories:
            handleGetCategoriesResponse()
            
        case .getCatData:
            handleGetCatDataResponse()
            
        default:
            currentPackage.completion?(nil)

        }
        
        resetVariableState()
    }
    
    private func handlePingResponse() {
        var index = 0
        let device = deviceInfo() ?? Device()
        
        device.deviceName = "Hendricks"
        device.osName = "Hendricks OS"
        device.deviceType = "WATCH"
        device.manufacturerName = "Fitpay"
        
        while index < expectedDataSize {
            guard returnedData[index] == 0x24 else { return }
            
            let length = Int(returnedData[index + 2])
            let nextIndex = index + 3 + length
            
            guard let type = PingResponse(rawValue: returnedData[index + 1]) else {
                index = nextIndex
                continue
            }
            
            let hex = Data(bytes: Array(returnedData[index + 3 ..< nextIndex])).hex
            
            switch type {
            case .serial:
                device.serialNumber = hex
            case .version:
                var version = "v"
                for i in index + 3 ..< nextIndex {
                    version += String(returnedData[i]) + "."
                }
                device.firmwareRevision = String(version.dropLast())
            case .deviceMode:
                guard returnedData[index + 3 ..< nextIndex] == [0x02] else { return }
                
            case .bootVersion:
                device.hardwareRevision = hex
                
            case .bleMac:
                device.bdAddress = hex
                
            default:
                break
            }
            
            index = nextIndex
        }
        
        self._deviceInfo = device
        paymentDevice?.connectionState = PaymentDevice.ConnectionState.connected
        connectedAndPinged = true
        connectTimer?.invalidate()
        connectTimer = nil
    }
    
    private func handleAPDUResponse() {
        var index = 0
        while index < expectedDataSize {
            let groupId = returnedData[index]
            let sequence = returnedData[index + 1] + returnedData[index + 2] << 8 // shift second bit
            let length = Int(returnedData[index + 4])
            let apduBytes = returnedData[index + 5 ..< index + length + 5]
            index += 5 + length
            
            let packet = ApduResultMessage(responseData: Data(bytes: apduBytes))
            
            // update responseData on the appropriate apduCommand
            apduCommands?.first(where: { $0.groupId == groupId && $0.sequence == sequence })?.responseData = packet.responseData
        }
        
        apduCompletion?(nil)
        apduCompletion = nil
        apduCommands = nil
    }
    
    private func handleGetCategoriesResponse() {
        let categoryCount = returnedData[0]
        var categories: [HendricksCategory] = []
        
        var index = 1
        for _ in 0..<categoryCount {
            let category = HendricksCategory(returnedData, index: index)
            categories.append(category)
            index += 16 + (category.objects.count * 2)
        }
        
        currentPackage?.completion?(categories)
    }
    
    private func handleGetCatDataResponse() {
        guard let commandData = currentPackage?.commandData else { return }
        let categoryId = Int(commandData[0] + commandData[1] << 8)
        
        let objectCount = returnedData[0]
        var objects: [HendricksObject] = []
        
        var index = 1
        for _ in 0..<objectCount {
            let objectId = Int(returnedData[index] + returnedData[index + 1] << 8)
            guard let type = HendricksObjectType(rawValue: Int(returnedData[index + 2])) else {
                currentPackage?.completion?(nil)
                return
            }
            
            switch type {
            case .identity:
                let identity = HendricksIdentity(categoryId: categoryId, objectId: objectId, returnedData: returnedData, index: index + 3)
                objects.append(identity)
                
                index += identity.totalLength + 4
            case .card:
                let card = HendricksCard(categoryId: categoryId, objectId: objectId, returnedData: returnedData, index: index + 3)
                objects.append(card)

                index += card.totalLength + 4
            case .favorite:
                let favorite = HendricksFavorite(categoryId: categoryId, objectId: objectId, returnedData: returnedData, index: index + 3)
                print(returnedData)
                objects.append(favorite)

                index += 11
            default:
                break
            }
        }
        
        currentPackage?.completion?(objects)
    }
    
}

@objc extension HendricksPaymentDeviceConnector: PaymentDeviceConnectable {
    
    public func connect() {
        if !centralManager.isScanning {
            startScan()
        }
        
        guard let connectionPeripheralId = connectionPeripheralId else { return }
        guard let peripheral = foundPeripherals.first(where: { $0.identifier == connectionPeripheralId }) else { return }
        
        connectTo(peripheral: peripheral)
    }
    
    public func isConnected() -> Bool {
        return wearablePeripheral?.state == CBPeripheralState.connected && connectedAndPinged
    }
    
    public func validateConnection(completion: @escaping (Bool, NSError?) -> Void) {
        completion(isConnected(), nil)
    }
    
    public func executeAPDUPackage(_ apduPackage: ApduPackage, completion: @escaping (Error?) -> Void) {
        log.debug("HENDRICKS: executeAPDUPackage started")
        guard let apdus = apduPackage.apduCommands else { return }
        
        apduCompletion = completion
        apduCommands = apduPackage.apduCommands
        
        let data = HendricksUtils.buildAPDUData(apdus: apdus)
        
        var apdusCount = apdus.count
        var dataCount = data.count
        
        let apduCountData = Data(bytes: &apdusCount, count: 2)
        let apduLengthData = Data(bytes: &dataCount, count: 4)
        
        let commandData = apduCountData + apduLengthData
        
        let bleCommand = BLEPackage(.apduPackage, commandData: commandData, data: data)
        
        addPackagetoQueue(bleCommand)
    }
    
    public func executeAPDUCommand(_ apduCommand: APDUCommand) {
        log.error("HENDRICKS: Not implemented. using packages instead")
    }
    
    public func deviceInfo() -> Device? {
        return _deviceInfo
    }
    
    public func resetToDefaultState() {
        addCommandtoFrontOfQueue(BLEPackage(.factoryReset))
    }
    
}

@objc extension HendricksPaymentDeviceConnector: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        connectedAndPinged = false
        bleState = central.state

        switch central.state {
        case .unknown:
            
            log.debug("HENDRICKS: central.state is .unknown")
        case .resetting:
            log.debug("HENDRICKS: central.state is .resetting")
        case .unsupported:
            log.debug("HENDRICKS: central.state is .unsupported")
        case .unauthorized:
            log.debug("HENDRICKS: central.state is .unauthorized")
        case .poweredOff:
            log.debug("HENDRICKS: central.state is .poweredOff")
        case .poweredOn:
            log.debug("HENDRICKS: central.state is .poweredOn")
            if shouldScanOnConnect {
                centralManager.scanForPeripherals(withServices: [deviceServiceId], options: nil)
                shouldScanOnConnect = false
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        log.verbose("HENDRICKS: didDiscover peripheral: \(peripheral)")
        foundPeripherals.append(peripheral)
        
        // TODO: more elegant way with connection state?
        NotificationCenter.default.post(name: Notification.Name(rawValue: "peripheralFound"), object: nil, userInfo: nil)

        if peripheral.identifier == connectionPeripheralId {
            connectTo(peripheral: peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.debug("HENDRICKS: Connected")
        wearablePeripheral?.discoverServices([deviceServiceId])
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.warning("HENDRICKS: Failed to Connect")
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.debug("HENDRICKS: didDisconnect")
        paymentDevice?.connectionState = PaymentDevice.ConnectionState.disconnected
    }
    
}

@objc extension HendricksPaymentDeviceConnector: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        guard let deviceService = services.filter({ $0.uuid == deviceServiceId }).first else { return }
        
        peripheral.discoverCharacteristics(nil, for: deviceService)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let statusCharacteristic = service.characteristics?.filter({ $0.uuid == statusCharacteristicId }).first else { return }
        guard let dataCharacteristic = service.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }
        
        wearablePeripheral?.writeValue(StatusCommand.abort.rawValue.data, for: statusCharacteristic, type: .withResponse)
        
        peripheral.setNotifyValue(true, for: statusCharacteristic)
        peripheral.setNotifyValue(true, for: dataCharacteristic)
        
        addPackagetoQueue(BLEPackage(.ping))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value: [UInt8] = characteristic.value!.bytesArray
        
        switch characteristic.uuid {
            
        case statusCharacteristicId:
            handleStatusResponse(value: value)
            
        case dataCharacteristicId:
            handleDataResponse(value: value)
            
        default:
            log.warning("HENDRICKS: Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
}

// MARK: - Nested Data

extension HendricksPaymentDeviceConnector {
    
    public enum Command: UInt8 {
        case ping           = 0x01
        case restart        = 0x02
        case bootLoader     = 0x03
        case setDeviceId    = 0x05
        case unsetDeviceId  = 0x06
        case factoryReset   = 0x07
        case sleep          = 0x08
        case lock           = 0x09
        case unlock         = 0x0A
        case heartbeat      = 0x0B
        
        case addIdentity    = 0x10
        
        case getUser        = 0x12
        case addCard        = 0x13
        case addCardCont    = 0x14

        case activateCard   = 0x16
        case getCardInfo    = 0x17
        case suspendCard    = 0x18

        case addMiscCat     = 0x1A
        case removeCatObj   = 0x1B
        case getCategories  = 0x1C
        case getCatData     = 0x1D
        case addFavCatObj   = 0x1E
        
        case apduPackage    = 0x20 // + 0xXX - apdu count
    }
    
    enum StatusCommand: UInt8 {
        case start  = 0x01
        case end    = 0x02
        case abort  = 0x03
    }
    
    enum PingResponse: UInt8 {
        case serial             = 0x00
        case version            = 0x01
        case deviceId           = 0x02
        case deviceMode         = 0x03
        case bootVersion        = 0x04
        
        case ack                = 0x06
        
        case bootloaderVersion  = 0x17
        case appVersion         = 0x18
        case d21BlVersion       = 0x19
        case hardwareVersion    = 0x1A
        case bleMac             = 0x1B
    }
    
    enum BLEResponses: UInt8 {
        case ok     = 0x01
        case error  = 0x02
    }
    
    public typealias RequestHandler = (Any?) -> Void
    
    public struct BLEPackage {
        var command: Command
        var commandData: Data?
        var data: Data?
        var completion: RequestHandler?
        
        public init(_ command: Command, commandData: Data? = nil, data: Data? = nil, completion: RequestHandler? = nil) {
            self.command = command
            self.commandData = commandData
            self.data = data
            self.completion = completion
        }
        
    }
    
}
