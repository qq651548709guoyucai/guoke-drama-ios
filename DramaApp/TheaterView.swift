import SwiftUI
import AVKit
import AVFoundation

struct TheaterView: View {
    @State private var cat = "全部"
    private let cats = ["全部", "逆袭", "甜宠", "悬疑", "古装", "重生", "都市", "脑洞"]

    private var list: [Drama] {
        sampleDramas.filter { cat == "全部" || $0.cat == cat }.sorted { $0.hot > $1.hot }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("果壳短剧")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(colors: [Color(hex: "FF4A57"), Color(hex: "FF8A3D")],
                                               startPoint: .leading, endPoint: .trailing))
                        Text("免费看短剧 · 追剧不花钱")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(cats, id: \.self) { c in
                                Text(c)
                                    .font(.system(size: 13, weight: cat == c ? .semibold : .regular))
                                    .padding(.horizontal, 14).padding(.vertical, 6)
                                    .background(cat == c ? Color(hex: "FF4A57").opacity(0.2) : Color(.secondarySystemBackground))
                                    .foregroundStyle(cat == c ? Color(hex: "FF4A57") : .secondary)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(cat == c ? Color(hex: "FF4A57") : .clear, lineWidth: 1))
                                    .onTapGesture { cat = c }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    ForEach(Array(list.enumerated()), id: \.element.id) { i, d in
                        NavigationLink { DramaDetail(drama: d) } label: { DramaRow(drama: d, rank: i + 1) }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

struct DramaRow: View {
    let drama: Drama
    let rank: Int

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD166")
        case 2: return Color(hex: "C9B8FF")
        case 3: return Color(hex: "7FC0FF")
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(rank <= 3 ? ["🥇", "🥈", "🥉"][rank - 1] : "\(rank)")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(rank <= 3 ? rankColor : .secondary)
                .frame(width: 26)

            RoundedRectangle(cornerRadius: 10)
                .fill(drama.gradient)
                .frame(width: 92, height: 122)
                .overlay(
                    ZStack(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("全\(drama.eps)集").font(.system(size: 10))
                            Text(drama.title).font(.system(size: 12, weight: .bold)).lineLimit(2)
                        }
                        .foregroundStyle(.white)
                        .padding(8)
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.85))
                    },
                    alignment: .center
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(drama.title).font(.system(size: 15, weight: .bold)).lineLimit(1)
                Text(drama.desc).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
                HStack(spacing: 6) {
                    ForEach(drama.tags, id: \.self) { t in
                        Text("#\(t)").font(.system(size: 10))
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(4)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(String(format: "🔥 热度 %.1f万", drama.hot))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF8A3D"))
            }
            Spacer(minLength: 0)
        }
    }
}

// ---------- 剧集详情 ----------
struct DramaDetail: View {
    let drama: Drama
    @EnvironmentObject private var store: Store
    @State private var playerDrama: Drama?
    @State private var startEp = 1

    var body: some View {
        ScrollView {
            ZStack(alignment: .bottomLeading) {
                Rectangle().fill(drama.gradient).frame(height: 210).blur(radius: 2)
                LinearGradient(colors: [.clear, .black.opacity(0.6)],
                               startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 8) {
                    Text(drama.title).font(.system(size: 22, weight: .heavy)).foregroundStyle(.white)
                    HStack(spacing: 12) {
                        Text("⭐ 9.\(Int.random(in: 2...9))").font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: "FFD166"))
                        Text("全\(drama.eps)集 · 每集2分钟")
                        Text("免费观看")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("简介：" + drama.desc).font(.system(size: 13)).foregroundStyle(.secondary)
                Text("选集 · 共 \(drama.eps) 集").font(.system(size: 15, weight: .bold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(1...max(drama.eps, 1), id: \.self) { n in
                        let cur = store.ep(of: drama.id)
                        Text(n == cur ? "▶ \(n)" : "\(n)")
                            .font(.system(size: 13, weight: n == cur ? .bold : .regular))
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(n == cur ? Color(hex: "FF4A57").opacity(0.25) : Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .onTapGesture { store.setEp(drama.id, n) }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                startEp = store.ep(of: drama.id)
                playerDrama = drama
            } label: {
                Text("立即免费播放 · 第 \(store.ep(of: drama.id)) 集")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient(colors: [Color(hex: "FF4A57"), Color(hex: "FF8A3D")],
                                               startPoint: .leading, endPoint: .trailing))
                    .foregroundStyle(.white).cornerRadius(24)
            }
            .padding(.horizontal, 16).padding(.bottom, 10)
        }
        .fullScreenCover(item: $playerDrama) { d in
            SinglePlayerCover(drama: d, startEp: startEp)
        }
    }
}

/// 整剧连播（上下滑切换集数）
struct SinglePlayerCover: View {
    let drama: Drama
    let startEp: Int
    @Environment(\.dismiss) private var dismiss
    @State private var epIndex: Int

    init(drama: Drama, startEp: Int) {
        self.drama = drama
        self.startEp = startEp
        _epIndex = State(initialValue: max(1, startEp) - 1)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                TabView(selection: $epIndex) {
                    ForEach(1...max(drama.eps, 1), id: \.self) { n in
                        EpisodePlayer(drama: drama, episode: n, isActive: n - 1 == epIndex)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .rotationEffect(.degrees(-90))
                            .tag(n - 1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: geo.size.height, height: geo.size.width)
                .rotationEffect(.degrees(90))
                .offset(x: (geo.size.width - geo.size.height) / 2,
                        y: (geo.size.height - geo.size.width) / 2)
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white).padding(8)
                    }
                    Text(drama.title).font(.system(size: 15, weight: .bold)).lineLimit(1)
                }
                Text("第 \(epIndex + 1) / \(drama.eps) 集")
                    .font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
                    .padding(.leading, 12)
            }
            .padding(.top, 8)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

/// 单集播放
struct EpisodePlayer: View {
    let drama: Drama
    let episode: Int
    let isActive: Bool
    @State private var player: AVPlayer?
    @State private var paused = false

    var body: some View {
        ZStack {
            if let p = player {
                PlayerLayerView(player: p).ignoresSafeArea()
            } else {
                Color.black
            }
            if paused {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 60)).foregroundStyle(.white.opacity(0.85))
            }
            Text("第 \(episode) 集")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if paused {
                player?.play(); paused = false
            } else {
                player?.pause(); paused = true
            }
        }
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
            if isActive { player?.play() }
        }
        .onChange(of: isActive) { active in
            if active { player?.play(); paused = false } else { player?.pause() }
        }
    }
}
