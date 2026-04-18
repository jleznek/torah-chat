import SwiftUI
import WebKit

/// Renders a Markdown string using WKWebView so that rich formatting —
/// Hebrew text, tables, headings, code blocks, and clickable Sefaria links —
/// all display correctly.
struct MarkdownView: UIViewRepresentable {
    let markdown: String
    var isStreaming: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(buildHTML(markdown), baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator (handles link taps)

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    // MARK: - HTML builder

    private func buildHTML(_ md: String) -> String {
        let escaped = md
            .replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")

        // Minimal client-side markdown rendering via marked.js CDN
        // For production, bundle the JS locally instead.
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          :root {
            color-scheme: light dark;
          }
          body {
            font-family: -apple-system, system-ui;
            font-size: 16px;
            line-height: 1.6;
            margin: 0; padding: 8px 12px;
            color: #1c1c1e;
            word-wrap: break-word;
          }
          @media (prefers-color-scheme: dark) {
            body { color: #f2f2f7; }
            a { color: #0a84ff; }
            code, pre { background: #1c1c1e; }
          }
          a { color: #007aff; text-decoration: none; }
          a:hover { text-decoration: underline; }
          code { background: #f2f2f7; padding: 2px 5px; border-radius: 4px; font-size: 0.9em; }
          pre { background: #f2f2f7; padding: 12px; border-radius: 8px; overflow-x: auto; }
          pre code { background: none; padding: 0; }
          blockquote { border-left: 3px solid #007aff; margin: 0; padding-left: 12px; color: #555; }
          h1, h2, h3 { margin-top: 1em; margin-bottom: 0.4em; }
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: left; }
          th { background: #f2f2f7; font-weight: 600; }
          /* Hebrew / RTL support */
          [dir="rtl"] { text-align: right; }
          .hebrew { font-size: 1.1em; direction: rtl; unicode-bidi: embed; }
        </style>
        <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
        </head>
        <body>
        <div id="content"></div>
        <script>
          document.getElementById('content').innerHTML =
            marked.parse(\(jsonStringLiteral(md)));
        </script>
        </body>
        </html>
        """
    }

    private func jsonStringLiteral(_ s: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: s),
              let str = String(data: data, encoding: .utf8)
        else { return "\"\"" }
        return str
    }
}

// MARK: - Height-aware wrapper

/// A MarkdownView that automatically sizes itself to its content height.
struct AutosizingMarkdownView: View {
    let markdown: String
    var isStreaming: Bool = false
    @State private var height: CGFloat = 100

    var body: some View {
        MarkdownView(markdown: markdown, isStreaming: isStreaming)
            .frame(height: height)
            .onAppear { estimateHeight() }
            .onChange(of: markdown) { estimateHeight() }
    }

    private func estimateHeight() {
        // Rough heuristic: ~20px per line, min 60
        let lines = markdown.components(separatedBy: "\n").count
        height = max(60, CGFloat(lines) * 20 + 40)
    }
}
