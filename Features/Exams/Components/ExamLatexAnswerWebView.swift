import SwiftUI
import WebKit

struct ExamLatexAnswerWebView: UIViewRepresentable {
    let latex: String
    let keepsActiveFormulaOnOneLine: Bool
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrapHTML(latex), baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: ExamLatexAnswerWebView

        init(parent: ExamLatexAnswerWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                webView.evaluateJavaScript("window.examupMeasureAndFocusCursor()") { result, _ in
                    guard let metrics = result as? [String: Any],
                          let rawHeight = metrics["height"] as? NSNumber else { return }

                    let clampedHeight = min(max(CGFloat(truncating: rawHeight) + 8, 76), 170)
                    DispatchQueue.main.async {
                        self.parent.height = clampedHeight
                    }
                }
            }
        }
    }

    private func wrapHTML(_ latex: String) -> String {
        let escaped = latex
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: " ")
        let activeFormulaClass = keepsActiveFormulaOnOneLine ? " examup-active-formula" : ""

        return """
        <!doctype html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css" rel="stylesheet">
            <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
            <style>
                html, body { margin: 0; padding: 0; background: transparent; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    color: #20242D;
                    font-size: 22px;
                    line-height: 1.35;
                    padding: 10px;
                    overflow-x: hidden;
                    overflow-y: auto;
                    box-sizing: border-box;
                    -webkit-overflow-scrolling: touch;
                }
                #mathRender {
                    width: 100%;
                    max-width: calc(100vw - 20px);
                    overflow-x: hidden;
                    overflow-y: visible;
                    white-space: normal;
                    box-sizing: border-box;
                    -webkit-overflow-scrolling: touch;
                }
                #mathRender.examup-active-formula {
                    overflow-x: auto;
                    white-space: nowrap;
                }
                .katex { font-size: 1em; }
                .katex-html {
                    white-space: normal;
                    overflow-wrap: break-word;
                    word-break: normal;
                }
                .katex-html > .base {
                    display: inline;
                    max-width: 100%;
                    vertical-align: baseline;
                    white-space: normal;
                }
                #mathRender.examup-active-formula .katex-html,
                #mathRender.examup-active-formula .katex-html > .base {
                    white-space: nowrap;
                }
                .katex .mord.text,
                .katex .mord.text span {
                    white-space: normal;
                    overflow-wrap: break-word;
                    word-break: normal;
                }
                .examup-cursor {
                    display: inline-block;
                    width: 2px;
                    height: 1.05em;
                    margin: 0 1px;
                    background: #7257F4;
                    vertical-align: -0.12em;
                    animation: blink 1s steps(2, start) infinite;
                }
                @keyframes blink {
                    0%, 45% { opacity: 1; }
                    46%, 100% { opacity: 0; }
                }
            </style>
        </head>
        <body>
            <div id="mathRender" class="\(activeFormulaClass)"></div>
            <script>
                function replaceCursorMarkers(root) {
                    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
                    const nodes = [];
                    while (walker.nextNode()) {
                        if (walker.currentNode.nodeValue.includes('⌈') || walker.currentNode.nodeValue.includes('\\\\lceil')) {
                            nodes.push(walker.currentNode);
                        }
                    }

                    nodes.forEach(function(node) {
                        const fragment = document.createDocumentFragment();
                        const parts = node.nodeValue.split(/(⌈|\\\\lceil)/g);
                        parts.forEach(function(part) {
                            if (part === '⌈' || part === '\\\\lceil') {
                                const cursor = document.createElement('span');
                                cursor.className = 'examup-cursor';
                                cursor.setAttribute('aria-hidden', 'true');
                                fragment.appendChild(cursor);
                            } else if (part.length > 0) {
                                fragment.appendChild(document.createTextNode(part));
                            }
                        });
                        node.parentNode.replaceChild(fragment, node);
                    });
                }

                window.addEventListener('load', function() {
                    const latex = '\(escaped)';
                    const target = document.getElementById('mathRender');
                    try {
                        katex.render(latex, target, {
                            throwOnError: false,
                            displayMode: false
                        });
                    } catch (e) {
                        target.textContent = latex;
                    }
                    replaceCursorMarkers(target);

                    window.examupMeasureAndFocusCursor = function() {
                        const cursor = document.querySelector('.examup-cursor');
                        const render = document.getElementById('mathRender');
                        const isActiveFormula = render.classList.contains('examup-active-formula');

                        if (cursor) {
                            cursor.scrollIntoView({
                                block: 'nearest',
                                inline: 'end',
                                behavior: 'instant'
                            });
                        }

                        if (isActiveFormula && render.scrollWidth > render.clientWidth + 2) {
                            render.scrollLeft = render.scrollWidth;
                            window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);
                        } else {
                            window.scrollTo(0, document.body.scrollHeight);
                        }

                        return {
                            height: document.body.scrollHeight,
                            width: render.scrollWidth,
                            containerWidth: render.clientWidth,
                            isActiveFormula: isActiveFormula
                        };
                    };

                    window.examupMeasureAndFocusCursor();
                });
            </script>
        </body>
        </html>
        """
    }
}
