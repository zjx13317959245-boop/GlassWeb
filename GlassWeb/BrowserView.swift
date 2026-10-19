import SwiftUI
import WebKit

private enum AppConfig {
    // Replace this with the website you want to wrap.
    static let defaultURL = "https://example.com"
}

final class BrowserModel: ObservableObject {
    @Published var address: String
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var pageTitle = "网页"
    @Published var errorMessage: String?

    weak var webView: WKWebView?

    private let defaults = UserDefaults.standard
    private let homeKey = "GlassWeb.homeURL"
    private let bookmarksKey = "GlassWeb.bookmarks"

    init() {
        address = UserDefaults.standard.string(forKey: "GlassWeb.homeURL") ?? AppConfig.defaultURL
    }

    var homeURL: String {
        defaults.string(forKey: homeKey) ?? AppConfig.defaultURL
    }

    func normalizedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else { return nil }
        return url
    }

    func loadAddress() {
        guard let url = normalizedURL(address) else {
            errorMessage = "请输入有效的网址，例如 https://example.com"
            return
        }
        address = url.absoluteString
        webView?.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
        errorMessage = nil
    }

    func goHome() {
        address = homeURL
        loadAddress()
    }

    func saveHome() {
        guard let url = normalizedURL(address) else {
            errorMessage = "当前网址无效，无法保存为主页。"
            return
        }
        defaults.set(url.absoluteString, forKey: homeKey)
        address = url.absoluteString
    }

    func addBookmark() {
        guard let url = normalizedURL(address) else { return }
        var bookmarks = defaults.stringArray(forKey: bookmarksKey) ?? []
        if !bookmarks.contains(url.absoluteString) {
            bookmarks.insert(url.absoluteString, at: 0)
            defaults.set(bookmarks, forKey: bookmarksKey)
        }
    }

    func sync(_ webView: WKWebView) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        pageTitle = webView.title?.isEmpty == false ? (webView.title ?? "网页") : "网页"
        if let current = webView.url?.absoluteString { address = current }
    }
}

struct BrowserView: View {
    @StateObject private var model = BrowserModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.91, green: 0.96, blue: 1.0),
                         Color(red: 0.97, green: 0.98, blue: 1.0),
                         Color(red: 0.88, green: 0.93, blue: 1.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 10) {
                header
                WebViewContainer(model: model)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
            }
        }
        .alert("提示", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear {
            if model.webView == nil { model.loadAddress() }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                TextField("输入网址", text: $model.address)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .onSubmit { model.loadAddress() }
                if model.isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button(action: model.loadAddress) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1))
            .padding(.horizontal, 14)

            HStack(spacing: 0) {
                toolbarButton("chevron.left", enabled: model.canGoBack) { model.webView?.goBack() }
                toolbarButton("chevron.right", enabled: model.canGoForward) { model.webView?.goForward() }
                toolbarButton("house", enabled: true) { model.goHome() }
                toolbarButton("bookmark", enabled: true) { model.addBookmark() }
                toolbarButton("square.and.arrow.down", enabled: true) { model.saveHome() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.75), lineWidth: 1))
            .padding(.horizontal, 38)
        }
        .padding(.top, 8)
    }

    private func toolbarButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .foregroundColor(enabled ? .blue : .gray.opacity(0.5))
    }
}

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var model: BrowserModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.isOpaque = false
        view.backgroundColor = .white
        view.scrollView.backgroundColor = .white
        model.webView = view
        if let url = model.normalizedURL(model.address) {
            view.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let model: BrowserModel
        init(model: BrowserModel) { self.model = model }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { self.model.sync(webView) }
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.model.sync(webView) }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.model.sync(webView)
                self.model.errorMessage = "网页加载失败：\(error.localizedDescription)"
            }
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.model.sync(webView)
                if (error as NSError).code != NSURLErrorCancelled {
                    self.model.errorMessage = "无法连接网页：\(error.localizedDescription)"
                }
            }
        }
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async { self.model.sync(webView) }
        }
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            // Avoid silently hanging JavaScript alert() calls.
            completionHandler()
        }
    }
}
