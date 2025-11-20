import SwiftUI

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    
    // sizes
    private let squareSize: CGFloat = 250
    private let ballSize: CGFloat = 60
    
    // 45 degrees in radians
    private let maxAngle: Double = .pi / 9
    
    func ballColor(x: CGFloat, y: CGFloat, maxOffset: CGFloat) -> Color {
        // distance from center (0...maxOffset)
        let distance = sqrt(x*x + y*y)
        
        // normalize 0...1
        let t = min(distance / maxOffset, 1)
        
        // blend from green → red
        return Color(
            red:   t,          // more red toward edge
            green: 1 - t,      // less green toward edge
            blue:  0
        )
    }

    func isAtEdge(x: CGFloat, y: CGFloat, maxOffset: CGFloat) -> Bool {
        abs(x) >= maxOffset || abs(y) >= maxOffset
    }
    
    var body: some View {
        // max distance from center to edge where the BALL center can go
        let maxOffset = (squareSize - ballSize) / 2   // e.g. (250 - 60)/2 = 95
        
        // how many points per radian so that 45° → edge
        let sensitivity = maxOffset / maxAngle        // ≈ 121
        let xOffset = motion.roll * sensitivity
        let yOffset = motion.pitch * sensitivity
        let hitEdge = isAtEdge(x: CGFloat(xOffset), y: CGFloat(yOffset), maxOffset: maxOffset)

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
                    .foregroundStyle(hitEdge ? Color.red.opacity(0.3) : Color.gray.opacity(0.1))
                    .animation(.easeOut(duration: 0.15), value: hitEdge)

                Circle()
                    .frame(width: ballSize, height: ballSize)
                    .foregroundStyle(
                        ballColor(
                            x: CGFloat(motion.roll * sensitivity),
                            y: CGFloat(motion.pitch * sensitivity),
                            maxOffset: maxOffset
                        )
                    )
                    .offset(
                        x: motion.roll * sensitivity,
                        y: motion.pitch * sensitivity
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
