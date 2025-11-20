import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    
    // sound handling
    @State private var soundURL: URL?
    @State private var activePlayers: [AVAudioPlayer] = []
    
    // moving object (airplane or captured photo)
    @State private var objectImage: UIImage? = nil
    @State private var showingCamera = false
    
    // object size
    private let objectSize: CGFloat = 60
    
    // 45 degrees in radians
    private let maxAngle: Double = .pi / 18
    
    func isAtEdge(x: CGFloat, y: CGFloat, maxOffsetWidth: CGFloat, maxOffsetHeight: CGFloat) -> Bool {
        abs(x) >= maxOffsetWidth || abs(y) >= maxOffsetHeight
    }
    
    func ballColor(x: CGFloat, y: CGFloat, maxOffset: CGFloat) -> Color {
        let distance = sqrt(x*x + y*y)
        let t = min(distance / maxOffset, 1)
        
        if t < 0.9 { return .green }
        
        let localT = (t - 0.9) / 0.1
        return Color(red: localT, green: 1 - localT, blue: 0)
    }
    
    private func loadSound() {
        guard let url = Bundle.main.url(forResource: "ep", withExtension: "m4a") else {
            print("⚠️ Could not find ep.m4a in bundle")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            soundURL = url
            print("✅ Sound URL loaded: \(url.lastPathComponent)")
        } catch {
            print("⚠️ Error setting up audio session: \(error.localizedDescription)")
        }
    }
    
    private func playHitSound() {
        guard let url = soundURL else {
            print("⚠️ No sound URL")
            return
        }
        
        activePlayers = activePlayers.filter { $0.isPlaying }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            activePlayers.append(player)
        } catch {
            print("⚠️ Error creating player: \(error.localizedDescription)")
        }
    }
    
    private func vibrateOnHit() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        playHitSound()
    }
    
    var body: some View {
        GeometryReader { geo in
            let fullWidth = geo.size.width
            let fullHeight = geo.size.height
            
            let maxOffsetWidth = (fullWidth - objectSize) / 2
            let maxOffsetHeight = (fullHeight - objectSize) / 2
            
            let sensitivityX = maxOffsetWidth / maxAngle
            let sensitivityY = maxOffsetHeight / maxAngle
            
            let rawX = motion.roll * sensitivityX
            let rawY = motion.pitch * sensitivityY
            
            let clampedX = clamp(rawX, maxOffset: maxOffsetWidth)
            let clampedY = clamp(rawY, maxOffset: maxOffsetHeight)
            
            let hitEdge = isAtEdge(
                x: clampedX,
                y: clampedY,
                maxOffsetWidth: maxOffsetWidth,
                maxOffsetHeight: maxOffsetHeight
            )
            
            let centerX = fullWidth / 2
            let centerY = fullHeight / 2
            
            ZStack {
                // FULL SCREEN BOX (not tappable)
                Rectangle()
                    .foregroundStyle(hitEdge ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                    .border(Color.gray.opacity(0.7), width: 4)
                    .animation(.easeOut(duration: 0.15), value: hitEdge)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // VISIBLE OBJECT
                Group {
                    if let img = objectImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "airplane")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .rotationEffect(.radians(0 - .pi/2))
                    }
                }
                .frame(width: objectSize, height: objectSize)
                .foregroundStyle(
                    ballColor(
                        x: clampedX,
                        y: clampedY,
                        maxOffset: min(maxOffsetWidth, maxOffsetHeight)
                    )
                )
                .position(x: centerX + clampedX, y: centerY + clampedY)
                .animation(.easeOut(duration: 0.1), value: motion.pitch)
                .animation(.easeOut(duration: 0.1), value: motion.roll)
                .onTapGesture {
                    showingCamera = true
                }
            }
            .onAppear {
                loadSound()
            }
            .onChange(of: hitEdge) { _, newValue in
                if newValue {
                    vibrateOnHit()
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $objectImage)
        }
    }
}

// ImagePicker stays the same as you have it

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// clamp helper
private func clamp(_ value: Double, maxOffset: CGFloat) -> CGFloat {
    let v = CGFloat(value)
    return min(max(v, -maxOffset), maxOffset)
}

#Preview {
    ContentView()
}
