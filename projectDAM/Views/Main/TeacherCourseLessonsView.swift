//
//  TeacherCourseLessonsView.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

import SwiftUI
import UIKit

struct TeacherCourseLessonsView: View {
    @StateObject private var viewModel: TeacherCourseLessonsViewModel
    
    init(course: TeacherCourse, classItem: TeacherClass, viewModel: TeacherCourseLessonsViewModel? = nil) {
        if let provided = viewModel {
            _viewModel = StateObject(wrappedValue: provided)
        } else {
            let authService = DIContainer.shared.authService
            let service = TeacherCourseContentService(
                networkService: DIContainer.shared.networkService,
                authService: authService
            )
            _viewModel = StateObject(
                wrappedValue: TeacherCourseLessonsViewModel(
                    course: course,
                    classItem: classItem,
                    contentService: service,
                    authService: authService
                )
            )
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                metaSection
                contentBlocks
                Spacer(minLength: 40)
            }
            .padding(.horizontal, DS.paddingMD)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Course Lessons")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") { Task { await viewModel.refresh() } }
                    .disabled(viewModel.isLoading)
            }
        }
        .safeAreaInset(edge: .bottom) {
            addLessonButton
                .background(.ultraThinMaterial)
        }
        .task { await viewModel.loadContent() }
        .refreshable { await viewModel.refresh() }
        .sheet(isPresented: $viewModel.showAddLessonSheet) {
            AddLessonSheetView(form: $viewModel.addLessonForm) {
                viewModel.submitDraftBlock()
            }
            .presentationDetents([.large])
        }
        .alert("Unable to load content", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue { viewModel.clearError() }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Course Lessons")
                .font(.system(size: 28, weight: .bold))
            Text(viewModel.courseTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Text(viewModel.courseSubtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var metaSection: some View {
        HStack(spacing: 12) {
            pillView(icon: "person.3", title: viewModel.studentCountLabel)
            if let lastUpdated = viewModel.lastUpdatedLabel {
                pillView(icon: "clock", title: lastUpdated)
            }
            Spacer()
        }
    }
    
    private var contentBlocks: some View {
        Group {
            if viewModel.isLoading && viewModel.displayedBlocks.isEmpty {
                skeletonCards
            } else if viewModel.displayedBlocks.isEmpty {
                TeacherLessonEmptyStateCard(message: "No lesson content yet. Tap Add Lesson to get started.")
            } else {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(viewModel.displayedRenderableItems) { item in
                        blockView(for: item)
                    }
                }
            }
        }
    }
    
    private func blockView(for item: TeacherLessonRenderableItem) -> some View {
        switch item {
        case let .title(_, text):
            return AnyView(Text(text)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary))
        case let .subtitle(_, text):
            return AnyView(Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase))
        case let .paragraph(_, text, style):
            return AnyView(paragraphCard(text: text, boxed: style == .boxed))
        case let .latex(_, content):
            return AnyView(formulaCard(text: content))
        case let .image(_, reference, caption):
            return AnyView(lessonImage(reference: reference, caption: caption))
        case let .pdf(_, reference, label):
            return AnyView(pdfCard(reference: reference, label: label))
        case let .link(_, label, detail, url):
            return AnyView(linkCard(label: label, detail: detail, url: url))
        case let .checklist(_, items):
            return AnyView(checklistCard(items: items))
        case let .code(_, reference, filename, language):
            return AnyView(codeCard(reference: reference, filename: filename, language: language))
        case .divider:
            return AnyView(Divider().padding(.vertical, 8))
        case let .unknown(_, raw, fallback):
            return AnyView(unknownBlock(type: raw, content: fallback))
        }
    }
    
    private func paragraphCard(text: String, boxed: Bool) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(boxed ? Color(.systemBackground) : Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(boxed ? 0.05 : 0), radius: boxed ? 12 : 0)
    }
    
    private func formulaCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Formula")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Show raw")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.brandPrimary)
            }
            Text(text.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .padding(.top, 8)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
    }
    
    private func lessonImage(reference: LessonMediaReference, caption: String?) -> some View {
        LessonRemoteImageView(reference: reference, caption: caption) { ref in
            try await viewModel.imageData(for: ref)
        }
    }
    
    private func pdfCard(reference: LessonMediaReference, label: String) -> some View {
        Button {
            Task {
                if let url = await viewModel.documentURL(for: reference, fileExtension: "pdf") {
                    _ = await UIApplication.shared.open(url)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(reference.filename)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
    
    private func linkCard(label: String, detail: String?, url: URL?) -> some View {
        Button {
            guard let target = url else { return }
            Task { _ = await UIApplication.shared.open(target) }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "link")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.brandPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.brandPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
    }
    
    private func checklistCard(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.brandPrimary)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    private func unknownBlock(type: String, content: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Unsupported block (\(type))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            if let content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
    }
    
    private func codeCard(reference: LessonMediaReference, filename: String?, language: String?) -> some View {
        LessonCodeBlock(reference: reference, filename: filename, language: language) { ref in
            await viewModel.documentURL(for: ref, fileExtension: "code")
        }
    }
    
    private var skeletonCards: some View {
        VStack(spacing: 16) {
            TeacherLessonSkeletonCard(height: 200)
            TeacherLessonSkeletonCard(height: 120)
            TeacherLessonSkeletonCard(height: 220)
        }
    }
    
    private func pillView(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(.secondarySystemBackground)))
    }
    
    private var addLessonButton: some View {
        Button {
            viewModel.showAddLessonSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Lesson")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color.brandPrimary, Color.brandPrimaryHover], startPoint: .leading, endPoint: .trailing))
            )
            .foregroundColor(.white)
            .padding(.horizontal, DS.paddingMD)
            .padding(.vertical, 12)
        }
    }
    
}

private struct TeacherLessonEmptyStateCard: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.secondary)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
}

private struct TeacherLessonSkeletonCard: View {
    let height: CGFloat
    @State private var phase: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5), Color(.systemGray6)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.5), Color.white.opacity(0.0)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: height)
                .offset(x: phase)
                .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
            )
            .onAppear { phase = 220 }
    }
}

private struct LessonRemoteImageView: View {
    let reference: LessonMediaReference
    let caption: String?
    let loader: (LessonMediaReference) async throws -> Data
    
    @State private var image: Image?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .cornerRadius(24)
                } else if isLoading {
                    ProgressView()
                } else if let error {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(24)
            
            if let caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .task(id: reference.blockId) { await loadImage() }
    }
    
    private func loadImage() async {
        guard !isLoading, image == nil else { return }
        isLoading = true
        do {
            let data = try await loader(reference)
            if let uiImage = UIImage(data: data) {
                image = Image(uiImage: uiImage)
            } else {
                error = "Image unavailable"
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

private struct LessonCodeBlock: View {
    let reference: LessonMediaReference
    let filename: String?
    let language: String?
    let loader: (LessonMediaReference) async -> URL?
    
    @State private var code: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ScrollView(.horizontal, showsIndicators: false) {
                if let code {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("Code snippet will appear once downloaded.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
        .task(id: reference.blockId) { await loadCode() }
    }
    
    private var header: some View {
        HStack {
            if let filename, !filename.isEmpty {
                Text(filename)
                    .font(.system(size: 13, weight: .semibold))
            }
            Spacer()
            if let language, !language.isEmpty {
                Text(language.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color.brandPrimary.opacity(0.1))
                    )
            }
            Button {
                if let code {
                    UIPasteboard.general.string = code
                }
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .disabled(code == nil)
        }
    }
    
    private func loadCode() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        guard let url = await loader(reference) else {
            errorMessage = "Unable to download code file."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            code = String(decoding: data, as: UTF8.self)
        } catch {
            errorMessage = "Unable to decode code file."
        }
    }
}

// MARK: - Add Lesson Sheet
private struct AddLessonSheetView: View {
    @Binding var form: AddLessonForm
    var onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Content Type")) {
                    Picker("Type", selection: $form.type) {
                        Text("Title").tag(TeacherLessonContentType.title)
                        Text("Subtitle").tag(TeacherLessonContentType.subtitle)
                        Text("Paragraph").tag(TeacherLessonContentType.paragraph)
                        Text("Boxed Paragraph").tag(TeacherLessonContentType.boxedParagraph)
                        Text("Latex").tag(TeacherLessonContentType.latex)
                        Text("Checklist").tag(TeacherLessonContentType.checklist)
                        Text("Code").tag(TeacherLessonContentType.code)
                        Text("Link").tag(TeacherLessonContentType.link)
                        Text("PDF").tag(TeacherLessonContentType.pdf)
                        Text("Image").tag(TeacherLessonContentType.fullImage)
                    }
                    .pickerStyle(.menu)
                }
                dynamicFields
            }
            .navigationTitle("Add Lesson Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        onSubmit()
                        dismiss()
                    }
                    .disabled(!form.canSubmit)
                }
            }
        }
    }
    
    @ViewBuilder
    private var dynamicFields: some View {
        switch form.type {
        case .title, .subtitle, .paragraph, .boxedParagraph, .latex, .code:
            Section(header: Text("Primary Content")) {
                TextEditor(text: $form.body)
                    .frame(height: 120)
            }
        default:
            EmptyView()
        }
        
        if form.type == .link {
            Section(header: Text("Link Details")) {
                TextField("Label", text: $form.body)
                TextField("Helper text", text: $form.secondaryText)
                TextField("URL", text: $form.url)
                    .keyboardType(.URL)
                    .textContentType(.URL)
            }
        }
        
        if form.type == .pdf {
            Section(header: Text("PDF")) {
                TextField("File name", text: $form.filename)
                TextField("Description", text: $form.body)
            }
        }
        
        if form.type == .fullImage {
            Section(header: Text("Image")) {
                TextField("Image file", text: $form.filename)
                TextField("Caption", text: $form.body)
            }
        }
        
        if form.type == .checklist {
            Section(header: Text("Checklist items")) {
                TextEditor(text: $form.checklistRaw)
                    .frame(height: 140)
                Text("Enter each task on a new line")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        
        if form.type == .code {
            Section(header: Text("Metadata")) {
                TextField("Filename", text: $form.filename)
                TextField("Language", text: $form.language)
            }
        }
    }
}
