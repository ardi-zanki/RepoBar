import AppKit
import RepoBarCore
import WebKit

@MainActor
final class IssueNavigatorBrowserStore: NSObject, WKNavigationDelegate, WKUIDelegate {
    private var webViews: [URL: WKWebView] = [:]
    private var accessOrder: [URL] = []

    func preload(_ url: URL) {
        _ = self.webView(for: url)
    }

    func preload(_ urls: [URL]) {
        for url in urls {
            self.preload(url)
        }
    }

    func clear() {
        for webView in self.webViews.values {
            webView.stopLoading()
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            webView.removeFromSuperview()
        }
        self.webViews.removeAll()
        self.accessOrder.removeAll()
    }

    func webView(for url: URL) -> WKWebView {
        if let webView = self.webViews[url] {
            self.markAccessed(url)
            return webView
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.load(URLRequest(url: url))

        self.webViews[url] = webView
        self.markAccessed(url)
        self.trimCache()
        return webView
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation) {
        let script = "if (window.scrollY < 80) window.scrollTo(0, 170);"
        webView.evaluateJavaScript(script)
    }

    private func markAccessed(_ url: URL) {
        self.accessOrder.removeAll { $0 == url }
        self.accessOrder.append(url)
    }

    private func trimCache() {
        while self.webViews.count > AppLimits.IssueNavigator.webPreviewCacheLimit {
            guard let evictedURL = self.accessOrder.first else { break }

            self.accessOrder.removeFirst()
            guard let webView = self.webViews.removeValue(forKey: evictedURL) else { continue }

            webView.stopLoading()
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            webView.removeFromSuperview()
        }
    }
}
