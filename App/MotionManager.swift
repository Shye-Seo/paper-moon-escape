import Foundation
import Combine
import PaperMoonCore

#if canImport(CoreMotion)
import CoreMotion
#endif

/// 기기의 기울이기와 흔들기를 게임 입력으로 바꾼다.
///
/// - 기울이면 빛 투과 퍼즐의 빛줄기가 따라 움직인다(`tiltX`, `tiltY`).
/// - 흔들면 먼지 닦기 판이 조금씩 닦인다(`shakes`가 늘어난다).
///
/// 시뮬레이터처럼 자이로가 없는 환경에서는 `available`이 false로 남고,
/// 화면은 같은 일을 하는 단추·드래그 대안을 보여 준다.
final class MotionManager: ObservableObject {
    @Published private(set) var available = false
    @Published private(set) var shakes = 0
    @Published private(set) var tiltX: Double = 0
    @Published private(set) var tiltY: Double = 0

    private var input = MotionInput(shakeThreshold: 1.25, tiltRange: 0.6)
    private var running = false

    #if canImport(CoreMotion)
    private let manager = CMMotionManager()
    #endif

    func start() {
        guard !running else { return }
        running = true
        #if canImport(CoreMotion)
        guard manager.isDeviceMotionAvailable else {
            available = false
            return
        }
        available = true
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.handle(motion)
        }
        #else
        available = false
        #endif
    }

    func stop() {
        #if canImport(CoreMotion)
        manager.stopDeviceMotionUpdates()
        #endif
        running = false
    }

    func reset() {
        input.reset()
        shakes = 0
        tiltX = 0
        tiltY = 0
    }

    #if canImport(CoreMotion)
    private func handle(_ motion: CMDeviceMotion) {
        let acceleration = motion.userAcceleration
        let signal = input.feed(
            accelerationX: acceleration.x,
            y: acceleration.y,
            z: acceleration.z,
            at: motion.timestamp
        )
        if signal == .shake {
            shakes = input.shakes
        }
        input.feedTilt(roll: motion.attitude.roll, pitch: motion.attitude.pitch)
        tiltX = input.beamOffsetX
        tiltY = input.beamOffsetY
    }
    #endif
}
