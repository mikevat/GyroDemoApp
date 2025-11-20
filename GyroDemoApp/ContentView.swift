import SwiftUI

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    
    // sizes
    private let squareSize: CGFloat = 250
    private let ballSize: CGFloat = 60
    
    // 45 degrees in radians
    private let maxAngle: Double = .pi / 9
    
    func ballColor(x: CGFloat, y: CGFloat, maxOffset: CGFloat) -> Color {
        // distance from center
        let distance = sqrt(x*x + y*y)
        let t = min(distance / maxOffset, 1)
        
        return Color(
            red:   t,
            green: 1 - t,
            blue:  0
        )
    }

    func isAtEdge(x: CGFloat, y: CGFloat, maxOffset: CGFloat) -> Bool {
        abs(x) >= maxOffset || abs(y) >= maxOffset
    }
    
    var body: some View {
        let maxOffset = (squareSize - ballSize) / 2
        
        // raw offsets from gyro
        let sensitivity = maxOffset / maxAngle
        let rawX = motion.roll * sensitivity
        let rawY = motion.pitch * sensitivity
        
        // 👉 CLAMP THEM HERE
        let clampedX = clamp(rawX, maxOffset: maxOffset)
        let clampedY = clamp(rawY, maxOffset: maxOffset)
        
        let hitEdge = isAtEdge(x: clampedX, y: clampedY, maxOffset: maxOffset)

        VStack(spacing: 32) {
            Text("Gyro Demo")
                .font(.largeTitle)
                .bold()
            
            let pitchDeg = motion.pitch * 180 / .pi
            let rollDeg  = motion.roll  * 180 / .pi

            VStack(spacing: 8) {
                Text(String(format: "Pitch: %.0f°", pitchDeg))
                Text(String(format: "Roll:  %.0f°", rollDeg))
            }
            .font(.title2)
            
            ZStack {
                Rectangle()
                    .frame(width: squareSize, height: squareSize)
                    .foregroundStyle(hitEdge ? Color.red.opacity(0.3) : Color.gray.opacity(0.1))
                    .animation(.easeOut(duration: 0.15), value: hitEdge)
                    .border(Color.gray.opacity(0.7), width: 4)

                Circle()
                    .frame(width: ballSize, height: ballSize)
                    .foregroundStyle(
                        ballColor(
                            x: clampedX,
                            y: clampedY,
                            maxOffset: maxOffset
                        )
                    )
                    .offset(x: clampedX, y: clampedY)
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
