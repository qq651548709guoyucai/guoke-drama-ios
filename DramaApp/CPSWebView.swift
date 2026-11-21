import SwiftUI
import WebKit

/// CPS 推广落地页容器：App 内打开分销平台的短剧落地页，用户在上面付费/充值即计入你的渠道
struct CPSWebView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var loading = true

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                WebContainer(url: url, progress: $progress, loading: $loading)
                    .ignoresSafeArea(edges: .bottom)

                if loading {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(Color(hex: "FF4A57"))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(Color(hex: "FF4A57"))
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    @Binding var progress: Double
    @Binding var loading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = true
        wv.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
        uiView.stopLoading()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: WebContainer
        init(_ parent: WebContainer) { self.parent = parent }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                   change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            guard keyPath == "estimatedProgress", let wv = object as? WKWebView else { return }
            DispatchQueue.main.async {
                self.parent.progress = wv.estimatedProgress
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.loading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.loading = false
            }
        }
    }
}
