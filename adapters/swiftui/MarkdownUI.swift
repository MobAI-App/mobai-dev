// Preview adapter for MarkdownUI. It renders paragraphs, bold-only headings,
// and simple `*` bullet rows while keeping the surrounding layout real.

import Foundation
import SwiftUI

public struct Markdown: View {
    private let source: String

    public init(_ source: String) {
        self.source = source
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(parsedBlocks, id: \.id) { block in
                MarkdownBlockRow(block: block)
                    .padding(.top, block.topSpacing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var parsedBlocks: [MarkdownBlock] {
        var result: [MarkdownBlock] = []
        var paragraph: [String] = []

        func append(_ kind: MarkdownBlock.Kind, _ text: String) {
            let spacing: Double
            if result.isEmpty || (kind == .bullet && result.last?.kind == .bullet) {
                spacing = 0
            } else {
                spacing = 17
            }
            result.append(MarkdownBlock(
                id: result.count, kind: kind, text: text, topSpacing: spacing))
        }

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            append(.paragraph, paragraph.joined(separator: " "))
            paragraph.removeAll(keepingCapacity: true)
        }

        for rawLine in source.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
            } else if line.hasPrefix("**"), line.hasSuffix("**"), line.count >= 4 {
                flushParagraph()
                append(.heading, String(line.dropFirst(2).dropLast(2)))
            } else if line.hasPrefix("* ") {
                flushParagraph()
                append(.bullet, String(line.dropFirst(2)))
            } else {
                paragraph.append(line)
            }
        }
        flushParagraph()
        return result
    }
}

private struct MarkdownBlock {
    enum Kind: Equatable { case heading, paragraph, bullet }
    let id: Int
    let kind: Kind
    let text: String
    let topSpacing: Double
}

private struct MarkdownBlockRow: View {
    let block: MarkdownBlock

    var body: some View {
        Group {
            if block.kind == .heading {
                Text(block.text)
                    .fontWeight(.bold)
                    .lineSpacing(2.55)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if block.kind == .bullet {
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(block.text)
                        .lineSpacing(2.55)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 16)
            } else {
                Text(block.text)
                    .lineSpacing(2.55)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
