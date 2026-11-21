import UIKit

// ==================================================================
//  ★★★ 服务器地址配置 ★★★
//  改成你运行「短剧后台」的电脑/服务器 IP，手机和电脑要在同一局域网。
//  例：后台跑在电脑 192.168.1.8 上 → "http://192.168.1.8:5000"
// ==================================================================
enum API {
    static var baseURL = "https://a1b500e225e2978b3.app.workbuddy.host"
    /// 在线后台的访问凭据（换自建后台后可置空）
    static var sharecode = "UDXMUMOTVJ"

    private static func makeURL(_ path: String) -> URL? {
        let sep = path.contains("?") ? "&" : "?"
        let full = sharecode.isEmpty ? baseURL + path : baseURL + path + sep + "sharecode=" + sharecode
        return URL(string: full)
    }

    static var token: String? {
        get { UserDefaults.standard.string(forKey: "api_token") }
        set { UserDefaults.standard.set(newValue, forKey: "api_token") }
    }

    struct AuthResp: Decodable {
        let code: Int
        let msg: String?
        let token: String?
        let username: String?
    }
    struct MeResp: Decodable {
        let code: Int
        let msg: String?
        let username: String?
    }
    struct DramasResp: Decodable {
        let code: Int
        let list: [Drama]
    }

    enum APIError: LocalizedError {
        case bad(String)
        var errorDescription: String? {
            switch self {
            case .bad(let m): return m
            }
        }
    }

    private static func post(_ path: String, body: [String: Any]) async throws -> Data {
        guard let url = makeURL(path) else { throw APIError.bad("服务器地址无效") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 20
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }

    /// 注册，成功返回用户名并保存 token
    static func register(username: String, password: String) async throws -> String {
        let data = try await post("/api/register", body: [
            "username": username, "password": password,
            "device": UIDevice.current.model
        ])
        let r = try JSONDecoder().decode(AuthResp.self, from: data)
        guard r.code == 0, let t = r.token else { throw APIError.bad(r.msg ?? "注册失败") }
        token = t
        return r.username ?? username
    }

    /// 登录，成功返回用户名并保存 token
    static func login(username: String, password: String) async throws -> String {
        let data = try await post("/api/login", body: [
            "username": username, "password": password
        ])
        let r = try JSONDecoder().decode(AuthResp.self, from: data)
        guard r.code == 0, let t = r.token else { throw APIError.bad(r.msg ?? "登录失败") }
        token = t
        return r.username ?? username
    }

    /// 校验 token，返回用户名；无效返回 nil
    static func me() async -> String? {
        guard let t = token,
              let url = makeURL("/api/me") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 8
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let r = try? JSONDecoder().decode(MeResp.self, from: data),
              r.code == 0, let name = r.username else {
            return nil
        }
        return name
    }

    /// 拉取后台动态剧集库（后台 dramas.json / 未来对接 CPS 短剧 API）
    static func loadDramas() async -> [Drama]? {
        guard let url = makeURL("/api/dramas") else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 15
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let wrapped = try? JSONDecoder().decode(DramasResp.self, from: data),
              !wrapped.list.isEmpty else {
            return nil
        }
        return wrapped.list
    }

    struct CPSResp: Decodable {
        let code: Int
        let list: [CPSItem]
    }

    /// 拉取 CPS 正版短剧专区（后台 cps.json 配置的推广链接）
    static func loadCPS() async -> [CPSItem] {
        guard let url = makeURL("/api/cps") else { return [] }
        var req = URLRequest(url: url)
        req.timeoutInterval = 12
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let wrapped = try? JSONDecoder().decode(CPSResp.self, from: data) else {
            return []
        }
        return wrapped.list
    }

    /// 记录 CPS 点击（用于后台统计引流效果、对账分成）
    static func clickCPS(id: Int) {
        Task { _ = try? await post("/api/cps/click", body: ["cps_id": id]) }
    }

    /// 上报观看进度（静默，失败不影响使用）
    static func saveProgress(dramaId: Int, episode: Int) {
        Task {
            _ = try? await post("/api/progress",
                                body: ["drama_id": dramaId, "episode": episode])
        }
    }
}

/// 登录状态
final class Auth: ObservableObject {
    @Published var username: String?
    @Published var checked = false

    init() {
        Task { [weak self] in
            let name = await API.me()
            await MainActor.run {
                self?.username = name
                self?.checked = true
            }
        }
    }

    func onLogin(_ name: String) {
        username = name
        checked = true
    }

    func logout() {
        API.token = nil
        username = nil
        checked = true
    }
}

/// 本地数据（收藏 / 进度 / 剧集库），并同步到后台
final class Store: ObservableObject {
    @Published var dramas: [Drama] = sampleDramas {
        didSet { if let data = try? JSONEncoder().encode(dramas) { UserDefaults.standard.set(data, forKey: "dramas_cache") } }
    }
    @Published var favorites: Set<Int> {
        didSet { UserDefaults.standard.set(Array(favorites), forKey: "favs") }
    }
    @Published var progress: [Int: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(progress) {
                UserDefaults.standard.set(data, forKey: "progress")
            }
        }
    }

    init() {
        favorites = Set(UserDefaults.standard.array(forKey: "favs") as? [Int] ?? [])
        if let data = UserDefaults.standard.data(forKey: "progress"),
           let p = try? JSONDecoder().decode([Int: Int].self, from: data) {
            progress = p
        } else {
            progress = [:]
        }
        // 启动时优先用本地缓存的剧集库，随后从后台刷新
        if let data = UserDefaults.standard.data(forKey: "dramas_cache"),
           let cached = try? JSONDecoder().decode([Drama].self, from: data), !cached.isEmpty {
            dramas = cached
        }
        refreshDramas()
        refreshCPS()
    }

    /// 从后台拉取剧集库，失败保持现有内容
    func refreshDramas() {
        Task {
            if let list = await API.loadDramas() {
                await MainActor.run { self.dramas = list }
            }
        }
    }

    /// 拉取 CPS 专区
    @Published var cps: [CPSItem] = []
    func refreshCPS() {
        Task {
            let list = await API.loadCPS()
            await MainActor.run { self.cps = list }
        }
    }

    func toggleFav(_ id: Int) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
    }

    func ep(of dramaId: Int) -> Int { progress[dramaId] ?? 1 }

    func setEp(_ dramaId: Int, _ ep: Int) {
        progress[dramaId] = ep
        API.saveProgress(dramaId: dramaId, episode: ep)
    }
}
