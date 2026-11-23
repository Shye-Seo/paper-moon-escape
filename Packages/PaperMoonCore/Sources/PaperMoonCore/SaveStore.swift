import Foundation

/// 자동 저장 통로. 테스트는 메모리 구현을, 앱은 UserDefaults 구현을 쓴다.
public protocol SaveStore: AnyObject {
    func load() -> GameState?
    func save(_ state: GameState)
    func clear()
}

/// `UserDefaults`에 상태를 통째로 넣는 저장소. 앱이 실제로 쓰는 구현.
public final class UserDefaultsSaveStore: SaveStore {
    public static let defaultKey = "paperMoon.save.v1"

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = UserDefaultsSaveStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> GameState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return GameStateCodec.decode(data)
    }

    public func save(_ state: GameState) {
        guard let data = GameStateCodec.encode(state) else { return }
        defaults.set(data, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}

/// 테스트와 미리보기용 저장소.
public final class InMemorySaveStore: SaveStore {
    public private(set) var stored: GameState?
    public private(set) var saveCount: Int = 0

    public init(state: GameState? = nil) {
        self.stored = state
    }

    public func load() -> GameState? {
        stored
    }

    public func save(_ state: GameState) {
        stored = state
        saveCount += 1
    }

    public func clear() {
        stored = nil
    }
}

/// 저장 포맷. 버전이 바뀌어도 읽을 수 있도록 JSON으로 남긴다.
public enum GameStateCodec {
    public static func encode(_ state: GameState) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return try? encoder.encode(state)
    }

    public static func decode(_ data: Data) -> GameState? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GameState.self, from: data)
    }
}
