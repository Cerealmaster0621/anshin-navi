import Network
import Foundation

class NetworkReachability: ObservableObject {
    @Published private(set) var isConnected = false
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkReachability")
    
    init() {
        self.monitor = NWPathMonitor()
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
