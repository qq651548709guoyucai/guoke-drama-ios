import SwiftUI

struct MineView: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var store: Store
    @State private var showPlayer: Drama?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 用户信息
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "845EF7"), Color(hex: "FF4A57")],
                                                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(auth.username ?? "未登录")
                                .font(.system(size: 19, weight: .heavy))
                            Text(auth.username != nil ? "欢迎回来，追剧愉快" : "登录后同步收藏与进度")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if auth.username != nil {
                            Button("退出登录") { auth.logout() }
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)

                    // VIP 卡片
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("果壳 VIP").font(.system(size: 15, weight: .heavy)).foregroundStyle(Color(hex: "FFD166"))
                            Text("全场免广告 · 优先看新剧").font(.system(size: 11)).foregroundStyle(Color(hex: "B7A877"))
                        }
                        Spacer()
                        Text("开通").font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 16).padding(.vertical, 7)
                            .background(LinearGradient(colors: [Color(hex: "FFD166"), Color(hex: "FFB347")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .foregroundStyle(Color(hex: "3A2D00")).cornerRadius(16)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(
                        LinearGradient(colors: [Color(hex: "3A2D18"), Color(hex: "4A3518")],
                                       startPoint: .leading, endPoint: .trailing)))
                    .padding(.horizontal, 16)

                    // 收藏
                    VStack(alignment: .leading, spacing: 10) {
                        Text("⭐ 我的收藏")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if store.favorites.isEmpty {
                            Text("收藏夹空空如也，去首页点点星星吧")
                                .font(.system(size: 13)).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(store.dramas.filter { store.favorites.contains($0.id) }) { d in
                                        VStack(alignment: .leading, spacing: 5) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(d.gradient)
                                                .frame(width: 86, height: 114)
                                                .overlay(Text(d.title)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .padding(6), alignment: .bottomLeading)
                                                .onTapGesture { showPlayer = d }
                                            Text(d.title).font(.system(size: 11)).lineLimit(1)
                                        }
                                        .frame(width: 86)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // 菜单
                    VStack(spacing: 0) {
                        MenuRow(icon: "clock", label: "观看历史")
                        Divider().padding(.leading, 46)
                        MenuRow(icon: "coins", label: "任务中心（看剧赚金币）")
                        Divider().padding(.leading, 46)
                        MenuRow(icon: "gearshape", label: "设置")
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .fullScreenCover(item: $showPlayer) { d in
                SinglePlayerCover(drama: d, startEp: store.ep(of: d.id))
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct MenuRow: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).frame(width: 26)
                .foregroundStyle(Color(hex: "FF4A57"))
            Text(label).font(.system(size: 14))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .padding(14)
    }
}

// ---------- 登录 / 注册 ----------
struct LoginView: View {
    @EnvironmentObject private var auth: Auth
    @State private var mode = 0   // 0 登录 1 注册
    @State private var username = ""
    @State private var password = ""
    @State private var loading = false
    @State private var err = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1A1024"), Color(hex: "2B1A2E"), Color(hex: "331A20")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("果壳短剧")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "FF4A57"), Color(hex: "FF8A3D")],
                                                       startPoint: .leading, endPoint: .trailing))
                    Text("登录后开启免费追剧之旅")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
                .padding(.bottom, 16)

                Picker("", selection: $mode) {
                    Text("登录").tag(0)
                    Text("注册").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 34)

                VStack(spacing: 14) {
                    TextField("用户名", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("密码（\(mode == 1 ? "至少 6 位" : "输入密码")）", text: $password)
                        .textFieldStyle(.roundedBorder)
                    if !err.isEmpty {
                        Text(err).font(.system(size: 13)).foregroundStyle(Color(hex: "FF4A57"))
                    }
                    Button {
                        submit()
                    } label: {
                        if loading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                        } else {
                            Text(mode == 0 ? "登 录" : "注 册 并 登 录")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                        }
                    }
                    .foregroundStyle(.white)
                    .background(LinearGradient(colors: [Color(hex: "FF4A57"), Color(hex: "FF8A3D")],
                                               startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(22)
                    .disabled(loading || username.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 34)

                Text("v3 · 在线后台版")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
    }

    private func submit() {
        loading = true
        err = ""
        Task {
            do {
                let name = mode == 0
                    ? try await API.login(username: username, password: password)
                    : try await API.register(username: username, password: password)
                await MainActor.run { auth.onLogin(name) }
            } catch {
                await MainActor.run {
                    err = friendly(error)
                    loading = false
                }
            }
        }
    }

    /// 把网络错误翻译成能看懂的中文，方便排查
    private func friendly(_ e: Error) -> String {
        if let ae = e as? API.APIError {
            return ae.errorDescription ?? "请求失败"
        }
        let ns = e as NSError
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorTimedOut:
                return "请求超时，检查网络"
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return "连不上服务器"
            case NSURLErrorNotConnectedToInternet:
                return "手机未联网"
            default:
                return "网络错误 \(ns.code)"
            }
        }
        return e.localizedDescription
    }
}
