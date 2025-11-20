import SwiftUI
import UIKit
import AudioToolbox
import AVFoundation

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    
    // sizes
    private let squareSize: CGFloat = 250
    private let ballSize: CGFloat = 60
    
    // 45 degrees in radians
    private let maxAngle: Double = .pi / 12
    
    func ballColor(x: CGFloat, y: CGFloat, maxOffset: CGFloat) -> Color {
        let distance = sqrt(x*x + y*y)
        let t = min(distance / maxOffset, 1)   // 0 = center, 1 = edge

        let dangerStart: CGFloat = 0.8         // 80% of the way to the edge

        if t < dangerStart {
            // safely away from the wall → solid green
            return .green
        } else {
            // in the last 20% → fade from green to red
            let localT = (t - dangerStart) / (1 - dangerStart)   // 0...1 in danger zone
            return Color(
                red:   localT,        // goes to 1 at edge
                green: 1 - localT,    // goes to 0 at edge
                blue:  0
            )
        }
    }


    func isAtEdge(x: CGFloat, y: CGFloat, maxOffset: CGFloat) -> Bool {
        abs(x) >= maxOffset || abs(y) >= maxOffset
    }

    private func vibrateOnHit() {
        // heavy haptic
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        // activate audio session
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)

        // reliable system sound
        AudioServicesPlaySystemSound(1106)
    }

    var body: some View {
        let maxOffset = (squareSize - ballSize) / 2
        
        // raw offsets from gyro
        let sensitivity = maxOffset / maxAngle
        let rawX = motion.roll * sensitivity
        let rawY = motion.pitch * sensitivity
        
        // clamp so ball never leaves the box
        let clampedX = clamp(rawX, maxOffset: maxOffset)
        let clampedY = clamp(rawY, maxOffset: maxOffset)
        
        let hitEdge = isAtEdge(x: clampedX, y: clampedY, maxOffset: maxOffset)
        
        // degrees just for display
        let pitchDeg = motion.pitch * 180 / .pi
        let rollDeg  = motion.roll  * 180 / .pi
        
        VStack(spacing: 32) {
            Text("Gyro Demo")
                .font(.largeTitle)
                .bold()
            
            // fixed-height label area
            ZStack {
                // "Ding!" when hitting the box
                Text("Ding!")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.red)
                    .opacity(hitEdge ? 1 : 0)
                
                // degrees when inside
                VStack(spacing: 8) {
                    Text(String(format: "Pitch: %.1f°", pitchDeg))
                    Text(String(format: "Roll:  %.1f°", rollDeg))
                }
                .font(.title2)
                .opacity(hitEdge ? 0 : 1)
            }
            .frame(height: 60)
            
            ZStack {
                Rectangle()
                    .frame(width: squareSize, height: squareSize)
                    .foregroundStyle(hitEdge ? Color.red.opacity(0.3) : Color.gray.opacity(0.1))
                    .border(Color.gray.opacity(0.7), width: 4)
                    .animation(.easeOut(duration: 0.15), value: hitEdge)

                Image(systemName: "airplane")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: ballSize, height: ballSize)
                    .foregroundStyle(
                        ballColor(
                            x: clampedX,
                            y: clampedY,
                            maxOffset: maxOffset
                        )
                    )
                    // optional: tilt the plane with roll
                    .rotationEffect(.radians(motion.roll - .pi/2))
                    .offset(x: clampedX, y: clampedY)
                    .animation(.easeOut(duration: 0.1), value: motion.pitch)
                    .animation(.easeOut(duration: 0.1), value: motion.roll)
            }
        }
        .padding()
        // 👇 haptic on transition to "hitEdge == true"
        .onChange(of: hitEdge) { _, newValue in
            if newValue { vibrateOnHit() }
        }

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
