import SwiftUI
import WebKit

struct ExamHTMLWebView: UIViewRepresentable {
    let content: String
    var baseURL: URL? = nil
    var revealsHiddenContent = false
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(ExamMediaURLSchemeHandler(), forURLScheme: "examup-media")
        // Weak proxy prevents retain cycle: WKUserContentController → coordinator
        configuration.userContentController.add(
            ScriptMessageProxy(context.coordinator),
            name: "height"
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        let signature = content + "|" + (baseURL?.absoluteString ?? "") + "|\(revealsHiddenContent)"
        guard context.coordinator.loadedSignature != signature else { return }
        context.coordinator.loadedSignature = signature
        webView.loadHTMLString(wrapHTML(content), baseURL: baseURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ExamHTMLWebView
        var loadedSignature: String?

        init(parent: ExamHTMLWebView) {
            self.parent = parent
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            revealHiddenContentIfNeeded(webView)
            wrapTablesAndMeasure(webView)   // atomic: wrap + measure in one JS call
            hookImageLoadListeners(webView)  // re-measure when each image finishes loading

            // Extra passes for MathJax and late-loading content
            for delay in [0.35, 0.9, 2.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak webView, weak self] in
                    guard let webView, let self else { return }
                    self.revealHiddenContentIfNeeded(webView)
                    self.measure(webView)
                }
            }
        }

        // MARK: - WKScriptMessageHandler (image load callbacks → height update)

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "height", let n = message.body as? NSNumber else { return }
            apply(height: CGFloat(truncating: n))
        }

        // MARK: - Private helpers

        /// Wraps tables first, then measures actual content bottom via getBoundingClientRect.
        /// Single JS call — tables are guaranteed wrapped before measurement runs.
        private func wrapTablesAndMeasure(_ webView: WKWebView) {
            webView.evaluateJavaScript("""
            (function() {
                function contentHeight() {
                    var body = document.body;
                    var bodyTop = body.getBoundingClientRect().top;
                    var bottom = 0;
                    body.querySelectorAll('*').forEach(function(el) {
                        bottom = Math.max(bottom, el.getBoundingClientRect().bottom - bodyTop);
                    });
                    var pb = parseFloat(getComputedStyle(body).paddingBottom) || 0;
                    return Math.ceil(Math.max(
                        bottom + pb,
                        body.scrollHeight,
                        document.documentElement.scrollHeight
                    ));
                }
                document.querySelectorAll('table').forEach(function(t) {
                    if (t.parentElement && t.parentElement.classList.contains('table-wrap')) return;
                    var w = document.createElement('div');
                    w.className = 'table-wrap';
                    t.parentNode.insertBefore(w, t);
                    w.appendChild(t);
                });
                return contentHeight();
            })()
            """) { [weak self] result, _ in
                guard let self, let n = result as? NSNumber else { return }
                self.apply(height: CGFloat(truncating: n))
            }
        }

        /// Attaches load/error listeners to every image that hasn't finished loading.
        /// On load, posts the measured height back via the 'height' message handler.
        private func hookImageLoadListeners(_ webView: WKWebView) {
            webView.evaluateJavaScript("""
            (function() {
                function contentHeight() {
                    var body = document.body;
                    var bodyTop = body.getBoundingClientRect().top;
                    var bottom = 0;
                    body.querySelectorAll('*').forEach(function(el) {
                        bottom = Math.max(bottom, el.getBoundingClientRect().bottom - bodyTop);
                    });
                    var pb = parseFloat(getComputedStyle(body).paddingBottom) || 0;
                    return Math.ceil(Math.max(
                        bottom + pb,
                        body.scrollHeight,
                        document.documentElement.scrollHeight
                    ));
                }
                var report = function() {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.height) {
                        window.webkit.messageHandlers.height.postMessage(contentHeight());
                    }
                };
                document.querySelectorAll('img').forEach(function(img) {
                    if (img.complete && img.naturalHeight > 0) return;
                    img.addEventListener('load', report);
                    img.addEventListener('error', report);
                });
                if (!window.examUpResizeObserver && window.ResizeObserver) {
                    window.examUpResizeObserver = new ResizeObserver(report);
                    window.examUpResizeObserver.observe(document.body);
                }
            })();
            """)
        }

        private func revealHiddenContentIfNeeded(_ webView: WKWebView) {
            guard parent.revealsHiddenContent else { return }
            webView.evaluateJavaScript("""
            document.querySelectorAll('.solution, [id^="sol"]').forEach(function(el) {
                el.style.setProperty('display', 'block', 'important');
                el.hidden = false;
            });
            """)
        }

        private func measure(_ webView: WKWebView) {
            webView.evaluateJavaScript("""
            (function() {
                var body = document.body;
                var bodyTop = body.getBoundingClientRect().top;
                var bottom = 0;
                body.querySelectorAll('*').forEach(function(el) {
                    bottom = Math.max(bottom, el.getBoundingClientRect().bottom - bodyTop);
                });
                var pb = parseFloat(getComputedStyle(body).paddingBottom) || 0;
                return Math.ceil(Math.max(
                    bottom + pb,
                    body.scrollHeight,
                    document.documentElement.scrollHeight
                ));
            })()
            """) { [weak self] result, _ in
                guard let self, let n = result as? NSNumber else { return }
                self.apply(height: CGFloat(truncating: n))
            }
        }

        private func apply(height: CGFloat) {
            let h = max(height, 1)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if abs(self.parent.height - h) > 1 {
                    self.parent.height = h
                }
            }
        }
    }

    private func wrapHTML(_ content: String) -> String {
        let revealStyle = revealsHiddenContent
            ? ".solution, [id^='sol'] { display: block !important; visibility: visible !important; }"
            : ""

        return """
        <!doctype html>
        <html lang="ru">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js" async></script>
            <style>
                html, body {
                    height: auto !important;
                    min-height: 0 !important;
                    margin: 0;
                    padding: 0;
                    background: transparent;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 17px;
                    line-height: 1.48;
                    color: #20242D;
                    padding: 14px;
                    overflow-x: hidden;
                }
                /* Horizontal scroll for wide content */
                .MathJax, .MathJax_Display, mjx-container,
                .MJXc-display, .MJX_Assistive_MathML,
                pre, code {
                    overflow-x: auto;
                    -webkit-overflow-scrolling: touch;
                    max-width: 100%;
                    display: block;
                    box-sizing: border-box;
                }
                /* Tables scroll horizontally instead of overflowing */
                .table-wrap { overflow-x: auto; -webkit-overflow-scrolling: touch; width: 100%; }
                table { border-collapse: collapse; min-width: 100%; }
                th, td { border: 1px solid #CBD1DD; padding: 7px; vertical-align: top; white-space: nowrap; }
                img, svg, canvas { max-width: 100%; height: auto; }
                .exam-drawing { margin: 0; padding: 0; text-align: center; }
                .exam-drawing img { display: block; margin: 0 auto; border-radius: 14px; }
                \(revealStyle)
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }
}

/// Weak proxy for WKScriptMessageHandler — breaks the retain cycle
/// WKUserContentController → handler → coordinator → view.
private final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
    weak var delegate: (WKScriptMessageHandler & AnyObject)?

    init(_ delegate: WKScriptMessageHandler & AnyObject) {
        self.delegate = delegate
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(controller, didReceive: message)
    }
}

/// Serves examup-media://{mediaID} requests from bundled media files.
final class ExamMediaURLSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let mediaID = url.host ?? (url.path.isEmpty ? nil : String(url.path.dropFirst())) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        guard let fileURL = ExamBundleMediaResolver.fileURL(forMediaID: mediaID),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let mimeType = Self.mimeType(for: fileURL.pathExtension)
        let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "webp": return "image/webp"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "svg": return "image/svg+xml"
        case "gif": return "image/gif"
        case "m4a": return "audio/mp4"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        default: return "application/octet-stream"
        }
    }
}
