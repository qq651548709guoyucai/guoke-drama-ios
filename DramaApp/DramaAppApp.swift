import SwiftUI

// 全局状态：当前 Tab、CPS 网页弹层
final class AppState: ObservableObject {
    @Published var tab: Int = 0
    @Published var web: WebTarget? = nil
}

struct WebTarget: Identifiable {
    let id: Int
    let url: URL
    let title: String
}

@main
struct DramaAppApp: App {
    @StateObject private var auth = Auth()
    @StateObject private var store = Store()
    @StateObject private var app = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
                .environmentObject(app)
                .onChange(of: scenePhase) { phase in
                    if phase != .active {
                        // 退到后台 / 锁屏时暂停播放
                        NotificationCenter.default.post(name: .pauseFeedPlayback, object: nil)
                    }
                }
        }
    }
}

extension Notification.Name {
    static let pauseFeedPlayback = Notification.Name("pauseFeedPlayback")
}

/// 根视图：三个 Tab + 未登录时强制弹登录
struct RootView: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var app: AppState

    var body: some View {
        TabView(selection: $app.tab) {
            FeedView(dramas: store.dramas)
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(0)
            TheaterView()
                .tabItem { Label("剧场", systemImage: "film.stack.fill") }
                .tag(1)
            MineView()
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(2)
        }
        .accentColor(Color(hex: "FF4A57"))
        .fullScreenCover(item: $app.web) { t in
            CPSWebView(url: t.url, title: t.title)
        }
        .fullScreenCover(isPresented: Binding(
            get: { auth.username == nil && auth.checked },
            set: { _ in auth.checked = true }
        )) {
            LoginView()
        }
        .preferredColorScheme(.dark)
    }
}
