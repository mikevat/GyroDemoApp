import SwiftUI
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let manager = CMMotionManager()
    
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
    private let alpha = 0.1
    
    init() {
        startDeviceMotion()
    }
    
    private func startDeviceMotion() {
        guard manager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        manager.deviceMotionUpdateInterval = 0.02
        
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            let newPitch = motion.attitude.pitch
            let newRoll  = motion.attitude.roll
            
            self.pitch = self.pitch + self.alpha * (newPitch - self.pitch)
            self.roll  = self.roll  + self.alpha * (newRoll - self.roll)
        }
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
    }
}
