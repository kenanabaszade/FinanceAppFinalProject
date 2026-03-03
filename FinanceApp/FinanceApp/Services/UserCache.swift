import Foundation

protocol UserCacheProtocol: AnyObject {
    func getCachedUser(uid: String) -> User?
    func setCachedUser(_ user: User)
    func clearCache()
}

final class UserCache: UserCacheProtocol {
    static let shared = UserCache()
    private let key = "mandarin_cached_user"
    private let defaults = UserDefaults.standard
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    func getCachedUser(uid: String) -> User? {
        guard let data = defaults.data(forKey: key) else { return nil }
        guard let payload = try? decoder.decode(UserPayload.self, from: data),
              payload.uid == uid else { return nil }
        return User(uid: payload.uid, payload: payload)
    }

    func setCachedUser(_ user: User) {
        let payload = user.toPayload()
        guard let data = try? encoder.encode(payload) else { return }
        defaults.set(data, forKey: key)
    }

    func clearCache() {
        defaults.removeObject(forKey: key)
    }
}
