import SwiftUI
import AVFoundation
import AVKit

// ---------- 底层播放视图（AVPlayerLayer，铺满 + aspectFill） ----------
class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        super.init(frame: .zero)
        backgroundColor = .black
        layer.addSublayer(playerLayer)
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> UIView { PlayerUIView(player: player) }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// ---------- 首页竖屏视频流 ----------
struct FeedView: View {
    let dramas: [Drama]
    @State private var index = 0

    var body: some View {
        GeometryReader { geo in
            TabView(selection: $index) {
                ForEach(Array(dramas.enumerated()), id: \.element.id) { i, d in
                    FeedSlide(drama: d, isActive: i == index)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .rotationEffect(.degrees(-90))
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: geo.size.height, height: geo.size.width)
            .rotationEffect(.degrees(90))
            .offset(x: (geo.size.width - geo.size.height) / 2,
                    y: (geo.size.height - geo.size.width) / 2)
        }
        .ignoresSafeArea()
    }
}

// ---------- 单个剧集页 ----------
struct FeedSlide: View {
    let drama: Drama
    let isActive: Bool

    @EnvironmentObject private var store: Store
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var appState: AppState
    @State private var player: AVPlayer?
    @State private var paused = false
    @State private var liked = false
    @State private var showEps = false

    /// 只有「首页 Tab + 当前页 + 没弹选集」时才播放，切到别的页面必须静音
    private var shouldPlay: Bool {
        isActive && appState.tab == 0 && !showEps
    }

    var body: some View {
        ZStack {
            if let p = player {
                PlayerLayerView(player: p)
                    .ignoresSafeArea()
            } else {
                Color.black
            }
            // 上下渐隐
            LinearGradient(colors: [.black.opacity(0.55), .clear, .clear, .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    infoView
                    Spacer()
                    sideOps
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 92)
            }
            .allowsHitTesting(true)

            if paused {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { togglePlay() }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { withAnimation(.easeOut(duration: 0.3)) { liked = true } }
        )
        .onAppear {
            if player == nil, let url = URL(string: drama.video) {
                player = AVPlayer(url: url)
                player?.actionAtItemEnd = .none
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player?.currentItem, queue: .main
                ) { [weak player] _ in
                    player?.seek(to: .zero)
                    player?.play()
                }
            }
            if isActive { play() }
        }
        .onChange(of: shouldPlay) { v in
            if v { play() } else {
                player?.pause()
                paused = false
            }
        }
        .onChange(of: auth.username) { name in
            if name != nil && shouldPlay { play() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pauseFeedPlayback)) { _ in
            player?.pause()
            paused = false
        }
        .onDisappear {
            player?.pause()
            paused = false
        }
        .sheet(isPresented: $showEps) { EpisodeSheet(drama: drama) }
    }

    private func play() {
        guard auth.username != nil, shouldPlay else { return }   // 未登录 / 不在首页时不播，避免漏声音
        player?.play()
        paused = false
    }
    private func togglePlay() {
        if paused { play() } else {
            player?.pause()
            paused = true
        }
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(drama.title).font(.system(size: 17, weight: .bold)).lineLimit(2)
                Text("独播").font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color(hex: "FF4A57")).cornerRadius(4)
            }
            Text(drama.desc).font(.system(size: 13)).foregroundStyle(.white.opacity(0.9)).lineLimit(2)
            HStack(spacing: 10) {
                Text("#\(drama.tags[0])")
                Text("#\(drama.tags[1])")
                Text(String(format: "🔥 热度 %.1f万", drama.hot))
            }
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.65))

            Button {
                showEps = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                    Text("第 \(store.ep(of: drama.id)) 集 · 选集")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.white.opacity(0.16))
                .cornerRadius(18)
                .foregroundStyle(.white)
            }
        }
    }

    private var sideOps: some View {
        VStack(spacing: 20) {
            VStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(liked ? Color(hex: "FF4A57") : .white)
                    .scaleEffect(liked ? 1.15 : 1)
                Text(String(format: "%.1f万", drama.hot)).font(.system(size: 11))
            }
            VStack(spacing: 3) {
                Image(systemName: store.favorites.contains(drama.id) ? "star.fill" : "star")
                    .font(.system(size: 26))
                    .foregroundStyle(store.favorites.contains(drama.id) ? Color(hex: "FFD166") : .white)
                Text("收藏").font(.system(size: 11))
            }
            .onTapGesture { store.toggleFav(drama.id) }
            VStack(spacing: 3) {
                Image(systemName: "bubble.right.fill").font(.system(size: 26))
                Text("评论").font(.system(size: 11))
            }
            VStack(spacing: 3) {
                Image(systemName: "list.bullet.rectangle.fill").font(.system(size: 26))
                Text("选集").font(.system(size: 11))
            }
            .onTapGesture { showEps = true }
        }
        .foregroundStyle(.white)
    }
}

// ---------- 选集弹窗 ----------
struct EpisodeSheet: View {
    let drama: Drama
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(1...max(drama.eps, 1), id: \.self) { n in
                        let cur = store.ep(of: drama.id)
                        Text(n == cur ? "▶ \(n)" : "\(n)")
                            .font(.system(size: 13, weight: n == cur ? .bold : .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(n == cur ? Color(hex: "FF4A57").opacity(0.25) : Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(n == cur ? Color(hex: "FF4A57") : .clear, lineWidth: 1))
                            .onTapGesture {
                                store.setEp(drama.id, n)
                                dismiss()
                            }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .navigationTitle("选集 · 共\(drama.eps)集")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
