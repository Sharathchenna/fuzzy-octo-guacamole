import Combine
import Dispatch
import Foundation
import WebKit

@MainActor
final class BrowserViewModel: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var pageTitle = "ArcBrowser"
    @Published var displayURL = ""

    weak var webView: WKWebView?
    var onStateChange: ((String, String) -> Void)?
    var onDownloadRequested: ((String, URL?) -> Void)?
    var onDownloadFinished: ((URL) -> Void)?
    var onDownloadFailed: ((String, URL?) -> Void)?

    func attach(webView: WKWebView) {
        let shouldSync = self.webView !== webView
        self.webView = webView

        guard shouldSync else { return }

        DispatchQueue.main.async { [weak self, weak webView] in
            guard let self, let webView else { return }
            self.syncState(from: webView)
        }
    }

    func load(_ input: String) {
        guard let webView, let url = normalizedURL(from: input) else { return }

        webView.load(URLRequest(url: url))
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        guard let webView else { return }

        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }

    func syncState(from webView: WKWebView) {
        let nextCanGoBack = webView.canGoBack
        let nextCanGoForward = webView.canGoForward
        let nextIsLoading = webView.isLoading
        let nextPageTitle = webView.title ?? "ArcBrowser"
        let nextDisplayURL = webView.url?.absoluteString ?? displayURL

        let didChange =
            canGoBack != nextCanGoBack ||
            canGoForward != nextCanGoForward ||
            isLoading != nextIsLoading ||
            pageTitle != nextPageTitle ||
            displayURL != nextDisplayURL

        canGoBack = nextCanGoBack
        canGoForward = nextCanGoForward
        isLoading = nextIsLoading
        pageTitle = nextPageTitle
        displayURL = nextDisplayURL

        guard didChange else { return }

        DispatchQueue.main.async { [onStateChange, pageTitle, displayURL] in
            onStateChange?(pageTitle, displayURL)
        }
    }

    private func normalizedURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        if trimmed.contains(" ") {
            let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            return URL(string: "https://www.google.com/search?q=\(encodedQuery)")
        }

        return URL(string: "https://\(trimmed)")
    }
}
