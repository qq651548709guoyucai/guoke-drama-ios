import SwiftUI

@main
struct DramaAppApp: App {
    @StateObject private var auth = Auth()
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
        }
    }
}

/// 根视图：三个 Tab + 未登录时强制弹登录
struct RootView: View {
    @EnvironmentObject private var auth: Auth

    var body: some View {
        TabView {
            FeedView(dramas: sampleDramas)
                .tabItem { Label("首页", systemImage: "house.fill") }
            TheaterView()
                .tabItem { Label("剧场", systemImage: "film.stack.fill") }
            MineView()
                .tabItem { Label("我的", systemImage: "person.fill") }
        }
        .accentColor(Color(hex: "FF4A57"))
        .fullScreenCover(isPresented: Binding(
            get: { auth.username == nil && auth.checked },
            set: { _ in auth.checked = true }
        )) {
            LoginView()
        }
        .preferredColorScheme(.dark)
    }
}
