import Foundation

/// 기울기 한 값. -1...1로 정규화해서 화면의 빛줄기 각도로 그대로 쓴다.
public struct MotionTilt: Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }

    public var magnitude: Double { (x * x + y * y).squareRoot() }

    public var invertedX: Double { -x }
}

/// 자이로·가속도 입력이 만들어 낸 사건.
public enum MotionSignal: Equatable, Sendable {
    case none
    case tilt
    case shake
}

/// `CMMotionManager`가 보내 주는 원시 값을 게임이 쓰는 형태로 다듬는 순수 값.
///
/// UIKit 없이도 계산되므로 Core 테스트에서 흔들기/기울이기를 그대로 검증할 수 있고,
/// 앱 레이어의 `MotionManager`는 이 값에 CoreMotion 결과만 흘려 넣는다.
public struct MotionInput: Equatable, Sendable {
    /// 이 크기(중력 포함 g)를 넘으면 흔든 것으로 본다.
    public let shakeThreshold: Double
    /// 이 기울기(라디안)에서 화면 빛줄기가 끝까지 간다.
    public let tiltRange: Double
    /// 흔들기가 연달아 잡히지 않도록 두는 최소 간격(초).
    public let shakeCooldown: Double

    public private(set) var tilt: MotionTilt
    public private(set) var shakes: Int
    public private(set) var lastShakeTime: Double

    public init(
        shakeThreshold: Double = 2.0,
        tiltRange: Double = 0.55,
        shakeCooldown: Double = 0.7
    ) {
        self.shakeThreshold = shakeThreshold
        self.tiltRange = max(0.05, tiltRange)
        self.shakeCooldown = max(0, shakeCooldown)
        self.tilt = MotionTilt()
        self.shakes = 0
        self.lastShakeTime = -.infinity
    }

    /// 가속도계 한 샘플. 흔들림으로 판정되면 `.shake`.
    public mutating func feed(
        accelerationX x: Double,
        y: Double,
        z: Double,
        at time: Double
    ) -> MotionSignal {
        let magnitude = (x * x + y * y + z * z).squareRoot()
        guard magnitude >= shakeThreshold else { return .none }
        guard time - lastShakeTime >= shakeCooldown else { return .none }
        lastShakeTime = time
        shakes += 1
        return .shake
    }

    /// 자세(roll/pitch) 한 샘플. 화면의 빛줄기 방향을 정한다.
    @discardableResult
    public mutating func feedTilt(roll: Double, pitch: Double) -> MotionSignal {
        let normalizedX = clamp(roll / tiltRange)
        let normalizedY = clamp(pitch / tiltRange)
        let next = MotionTilt(x: normalizedX, y: normalizedY)
        guard next != tilt else { return .none }
        tilt = next
        return .tilt
    }

    /// 기울기를 -1...1로 자른 값. 빛줄기 x 오프셋.
    public var beamOffsetX: Double { tilt.x }

    /// 기울기를 -1...1로 자른 값. 빛줄기 y 오프셋.
    public var beamOffsetY: Double { tilt.y }

    public var isTilted: Bool { tilt.magnitude > 0.18 }

    public mutating func reset() {
        tilt = MotionTilt()
        shakes = 0
        lastShakeTime = -.infinity
    }

    private func clamp(_ value: Double) -> Double {
        if value > 1 { return 1 }
        if value < -1 { return -1 }
        return value
    }
}
