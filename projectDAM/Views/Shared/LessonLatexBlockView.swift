//
//  LessonLatexBlockView.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

#if canImport(UIKit)

import SwiftUI
import WebKit
import UIKit

// MARK: - Public View
struct LessonLatexBlockView: View {
    let latex: String
    var accessibilityLabel: String?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var renderedImage: UIImage?
    @State private var isLoading = false
    @State private var showRaw = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
            actionRow
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .task(id: renderTaskIdentifier) {
            guard !showRaw else { return }
            await renderLatexIfNeeded()
        }
        .onChange(of: showRaw) { newValue in
            if newValue == false && renderedImage == nil {
                Task { await renderLatexIfNeeded() }
            }
        }
        .onChange(of: colorScheme) { _ in
            renderedImage = nil
            if showRaw == false {
                Task { await renderLatexIfNeeded() }
            }
        }
    }
    
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Formula")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            Spacer()
            Button(action: { showRaw.toggle() }) {
                Text(showRaw ? "Show rendered" : "Show raw")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .foregroundColor(.brandPrimary)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if showRaw {
            formulaContainer { rawLatexView }
        } else if let renderedImage {
            formulaContainer {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
            }
        } else if isLoading {
            formulaContainer {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Rendering…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
            }
        } else {
            formulaContainer { rawLatexView }
        }
    }
    
    private var rawLatexView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(latex)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var actionRow: some View {
        HStack(spacing: 16) {
            Button(action: copyLatex) {
                Label("Copy LaTeX", systemImage: "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .foregroundColor(.brandPrimary)
            .accessibilityLabel("Copy raw LaTeX")
            Spacer()
        }
    }
    
    private var accessibilityText: Text {
        if let accessibilityLabel {
            return Text("Formula: \(accessibilityLabel)")
        }
        return Text("Formula block")
    }
    
    private var renderTaskIdentifier: String {
        "latex-\(latex)-scheme-\(colorScheme == .dark ? "dark" : "light")"
    }
    
    private func renderLatexIfNeeded() async {
        guard renderedImage == nil else { return }
        do {
            isLoading = true
            errorMessage = nil
            let appearance = colorScheme == .dark ? UIUserInterfaceStyle.dark : UIUserInterfaceStyle.light
            let image = try await LatexRenderer.shared.renderImage(for: latex, appearance: appearance)
            renderedImage = image
            errorMessage = nil
        } catch {
            errorMessage = "Unable to render. Showing raw LaTeX."
            print("⚠️ [LatexRenderer] render failed: \(error)")
        }
        isLoading = false
    }
    
    private func copyLatex() {
        UIPasteboard.general.string = latex
    }

    private func formulaContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let gradient = LinearGradient(
            colors: [Color.brandPrimary.opacity(0.08), Color.brandPrimaryHover.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return content()
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Renderer
@MainActor
final class LatexRenderer {
    static let shared = LatexRenderer()
    
    private let cache = NSCache<NSString, UIImage>()
    
    func renderImage(for latex: String, appearance: UIUserInterfaceStyle) async throws -> UIImage {
        let key = cacheKey(for: latex, appearance: appearance)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let image = try await LatexRenderOperation.render(latex: latex, appearance: appearance)
        cache.setObject(image, forKey: key)
        return image
    }
    
    private func cacheKey(for latex: String, appearance: UIUserInterfaceStyle) -> NSString {
        NSString(string: "\(appearance.rawValue)-\(latex)")
    }
}

private enum LatexRenderError: Error {
    case timeout
    case snapshotFailed
    case renderingFailed(String)
}

@MainActor
private final class LatexRenderOperation: NSObject, WKScriptMessageHandler {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<UIImage, Error>?
    private var timeoutItem: DispatchWorkItem?
    private let latex: String
    private let appearance: UIUserInterfaceStyle
    private var contentSize: CGSize = CGSize(width: 320, height: 120)
    
    private init(latex: String, appearance: UIUserInterfaceStyle) {
        self.latex = latex
        self.appearance = appearance
    }
    
    static func render(latex: String, appearance: UIUserInterfaceStyle) async throws -> UIImage {
        let operation = LatexRenderOperation(latex: latex, appearance: appearance)
        return try await operation.start()
    }
    
    private func start() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let config = WKWebViewConfiguration()
            config.preferences.javaScriptEnabled = true
            config.userContentController.add(self, name: "mathjaxReady")
            config.userContentController.add(self, name: "mathjaxError")
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.isOpaque = false
            webView.backgroundColor = .clear
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.backgroundColor = .clear
            self.webView = webView
            let html = buildHTMLDocument()
            webView.loadHTMLString(html, baseURL: nil)
            webView.frame = CGRect(origin: .zero, size: contentSize)
            let timeoutItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.finish(.failure(LatexRenderError.timeout))
            }
            self.timeoutItem = timeoutItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutItem)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "mathjaxReady":
            if let payload = message.body as? [String: Double],
               let width = payload["width"],
               let height = payload["height"],
               width > 0, height > 0 {
                let paddedWidth = min(max(width + 24, 120), 2000)
                let paddedHeight = min(max(height + 24, 40), 2000)
                contentSize = CGSize(width: paddedWidth, height: paddedHeight)
                webView?.frame = CGRect(origin: .zero, size: contentSize)
            }
            captureSnapshot()
        case "mathjaxError":
            let description = message.body as? String ?? "Unknown"
            finish(.failure(LatexRenderError.renderingFailed(description)))
        default:
            break
        }
    }
    
    private func captureSnapshot() {
        guard let webView else { return }
        let configuration = WKSnapshotConfiguration()
        configuration.afterScreenUpdates = true
        configuration.rect = CGRect(origin: .zero, size: contentSize)
        webView.takeSnapshot(with: configuration) { [weak self] image, error in
            guard let self else { return }
            if let image {
                self.finish(.success(image))
            } else {
                self.finish(.failure(error ?? LatexRenderError.snapshotFailed))
            }
        }
    }
    
    private func finish(_ result: Result<UIImage, Error>) {
        guard let continuation else { return }
        switch result {
        case .success(let image):
            continuation.resume(returning: image)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
        cleanup()
    }
    
    private func cleanup() {
        if let userContentController = webView?.configuration.userContentController {
            userContentController.removeScriptMessageHandler(forName: "mathjaxReady")
            userContentController.removeScriptMessageHandler(forName: "mathjaxError")
        }
        timeoutItem?.cancel()
        timeoutItem = nil
        webView = nil
        continuation = nil
    }
    
    private func buildHTMLDocument() -> String {
        let textColor = appearance == .dark ? "#FFFFFF" : "#111111"
        let background = "#00000000"
        let escapedLatex = sanitizedLatexExpression()
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset=\"utf-8\">
            <meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1\">
            <style>
                body { margin: 0; padding: 12px; background: \(background); color: \(textColor); }
                .formula { font-size: 22px; display: flex; justify-content: center; align-items: center; min-height: 32px; }
                svg { width: auto !important; height: auto !important; }
            </style>
            <script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js\"></script>
            <script>
                window.addEventListener('load', function() { scheduleTypeset(); });
                function scheduleTypeset() {
                    if (!window.MathJax || !MathJax.typesetPromise) {
                        setTimeout(scheduleTypeset, 50);
                        return;
                    }
                    MathJax.typesetPromise().then(function () {
                        const rect = document.querySelector('.formula').getBoundingClientRect();
                        window.webkit.messageHandlers.mathjaxReady.postMessage({width: rect.width, height: rect.height});
                    }).catch(function (err) {
                        window.webkit.messageHandlers.mathjaxError.postMessage(err.toString());
                    });
                }
            </script>
        </head>
        <body>
            <div class=\"formula\">\(escapedLatex)</div>
        </body>
        </html>
        """
    }

    private func sanitizedLatexExpression() -> String {
        let trimmed = latex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        guard !trimmed.isEmpty else { return "" }
        let lower = trimmed.lowercased()
        if (trimmed.hasPrefix("\\[") && trimmed.hasSuffix("\\]")) ||
            (trimmed.hasPrefix("\\(") && trimmed.hasSuffix("\\)")) {
            return trimmed
        }
        if trimmed.hasPrefix("$$") && trimmed.hasSuffix("$$") && trimmed.count > 4 {
            let inner = trimmed.dropFirst(2).dropLast(2)
            return "\\[\(inner)\\]"
        }
        if trimmed.hasPrefix("$") && trimmed.hasSuffix("$") && trimmed.count > 2 {
            let inner = trimmed.dropFirst().dropLast()
            return "\\(\(inner)\\)"
        }
        if lower.hasPrefix("\\begin{") || lower.contains("\\frac") {
            return "\\[\(trimmed)\\]"
        }
        return "\\(\(trimmed)\\)"
    }
}

#else

import SwiftUI

struct LessonLatexBlockView: View {
    let latex: String
    var accessibilityLabel: String?
    
    var body: some View {
        Text(latex)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

#endif
