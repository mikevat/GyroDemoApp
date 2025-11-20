import SwiftUI

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    
    // sizes
    private let squareSize: CGFloat = 250
    private let ballSize: CGFloat = 60
    
    // 45 degrees in radians
    private let maxAngle: Double = .pi / 9
    
    var body: some View {
        // max distance from center to edge where the BALL center can go
        let maxOffset = (squareSize - ballSize) / 2   // e.g. (250 - 60)/2 = 95
        
        // how many points per radian so that 45° → edge
        let sensitivity = maxOffset / maxAngle        // ≈ 121
        
        VStack(spacing: 32) {
            Text("Gyro Demo")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 8) {
                Text(String(format: "Pitch: %.2f", motion.pitch))
                Text(String(format: "Roll:  %.2f", motion.roll))
            }
            .font(.title2)
            
            ZStack {
                Rectangle()
                    .frame(width: squareSize, height: squareSize)
                    .opacity(0.1)
                
                Circle()
                    .frame(width: ballSize, height: ballSize)
                    .offset(
                        x: clamp(motion.roll * sensitivity, maxOffset: maxOffset),
                        y: clamp(motion.pitch * sensitivity, maxOffset: maxOffset)
                    )
                    .animation(.easeOut(duration: 0.1), value: motion.pitch)
                    .animation(.easeOut(duration: 0.1), value: motion.roll)
            }
        }
        .padding()
    }
}

// helper: don’t let it go outside the square
private func clamp(_ value: Double, maxOffset: CGFloat) -> CGFloat {
    let v = CGFloat(value)
    return min(max(v, -maxOffset), maxOffset)
}

#Preview {
    ContentView()
}
