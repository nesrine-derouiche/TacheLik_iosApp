import SwiftUI

// MARK: - Classes View
struct ClassesView: View {
    @StateObject private var viewModel = DIContainer.shared.makeClassesViewModel()
    @State private var selectedFilterID: String = ClassesViewModel.FilterOption.allID
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                loadingState
            } else if let message = viewModel.errorMessage {
                errorState(message: message)
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Classes")
        .navigationBarTitleDisplayMode(.inline)
        .appForceNavigationTitle("Classes", displayMode: .never)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
        .appNavigationBarStyle(.standard)
        .background(Color.appGroupedBackground)
        .task {
            await viewModel.loadClasses()
            if let firstFilter = viewModel.filters.first?.id {
                selectedFilterID = firstFilter
            }
        }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    filterPills
                    sectionsContent
                }
                .padding(.vertical, 8)
                .padding(.bottom, DS.barHeight + 8)
            }
            .background(Color.appGroupedBackground)
        }
    }
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.filters) { filter in
                    FilterPill(
                        title: filter.title,
                        isSelected: selectedFilterID == filter.id,
                        accentColor: filter.accentColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilterID = filter.id
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var sectionsContent: some View {
        let sections = viewModel.sections(for: selectedFilterID)
        if sections.isEmpty {
            emptyState
        } else if selectedFilterID == ClassesViewModel.FilterOption.allID {
            AllSectionsView(viewModel: viewModel, sections: sections, onSectionTap: { filterID in
                withAnimation(.spring(response: 0.3)) {
                    selectedFilterID = filterID
                }
            })
        } else if let section = sections.first {
            SectionClassesView(viewModel: viewModel, section: section)
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading classes...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.brandWarning)
            Text("Something went wrong")
                .font(.system(size: 18, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: {
                Task { await viewModel.loadClasses(force: true) }
            }) {
                Text("Try Again")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient.brandPrimaryGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical.circle")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No classes available")
                .font(.system(size: 18, weight: .semibold))
            Text("Please check back later or choose another filter.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color?
    let action: () -> Void
    
    private var selectedGradient: LinearGradient {
        if let accentColor {
            return LinearGradient(
                colors: [accentColor, accentColor.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient.brandPrimaryGradient
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            selectedGradient
                        } else {
                            Color(.secondarySystemBackground)
                        }
                    }
                )
                .cornerRadius(20)
                .shadow(color: (accentColor ?? .brandPrimary).opacity(isSelected ? 0.3 : 0), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ClassCardView: View {
    let classCard: ClassesViewModel.ClassCard
    let sectionColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ClassCardThumbnail(imageURLString: classCard.imageURLString, fallbackColor: sectionColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(classCard.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(classCard.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .appCardStyle()
    }
}

// MARK: - All Sections View
struct AllSectionsView: View {
    @ObservedObject var viewModel: ClassesViewModel
    let sections: [ClassesViewModel.ClassSectionViewData]
    let onSectionTap: (String) -> Void
    
    var body: some View {
        LazyVStack(spacing: 28, pinnedViews: []) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(section.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(section.classes.count) Classes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 12, pinnedViews: []) {
                        let previewCards = viewModel.previewClasses(for: section.id, limit: 2)
                        ForEach(previewCards) { classCard in
                            NavigationLink(destination: OurCoursesView(
                                classItem: classCard.classItem,
                                courseService: DIContainer.shared.courseService
                            )) {
                                ClassCardView(classCard: classCard, sectionColor: section.color)
                                    .padding(.horizontal, 20)
                            }
                            .onAppear {
                                viewModel.loadMoreClassesIfNeeded(sectionID: section.id, currentClassID: classCard.id)
                            }
                        }
                    }
                    
                    Button(action: {
                        onSectionTap(section.id)
                    }) {
                        HStack(spacing: 8) {
                            Text("Go to \(section.title)")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [section.color, section.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: section.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    viewModel.loadMoreSectionsIfNeeded(currentSectionID: section.id)
                }
            }
        }
    }
}

// MARK: - Section Classes View
struct SectionClassesView: View {
    @ObservedObject var viewModel: ClassesViewModel
    let section: ClassesViewModel.ClassSectionViewData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.system(size: 28, weight: .bold))
                    Text("All classes in this section")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(section.classes.count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(section.color)
                    .opacity(0.3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            LazyVStack(spacing: 12, pinnedViews: []) {
                ForEach(viewModel.visibleClasses(for: section.id)) { classCard in
                    NavigationLink(destination: OurCoursesView(
                        classItem: classCard.classItem,
                        courseService: DIContainer.shared.courseService
                    )) {
                        ClassCardView(classCard: classCard, sectionColor: section.color)
                            .padding(.horizontal, 20)
                    }
                    .onAppear {
                        viewModel.loadMoreClassesIfNeeded(sectionID: section.id, currentClassID: classCard.id)
                    }
                }
                if viewModel.canLoadMoreClasses(for: section.id) {
                    LoadMoreIndicator(accentColor: section.color)
                        .onAppear {
                            if let lastID = viewModel.visibleClasses(for: section.id).last?.id {
                                viewModel.loadMoreClassesIfNeeded(sectionID: section.id, currentClassID: lastID)
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Load More Indicator
struct LoadMoreIndicator: View {
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
            Text("Loading more")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Class Card Thumbnail
private struct ClassCardThumbnail: View {
    let imageURLString: String?
    let fallbackColor: Color
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [fallbackColor, fallbackColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundGradient)
            thumbnailContent
        }
        .frame(width: 70, height: 70)
        .shadow(color: fallbackColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var thumbnailContent: some View {
        RemoteThumbnailImageView(
            url: imageURLString.flatMap { URL(string: $0) },
            width: 70,
            height: 70,
            cornerRadius: 16,
            baseColor: fallbackColor
        ) {
            fallbackIcon
        }
    }
    
    private var fallbackIcon: some View {
        Image(systemName: "book.fill")
            .font(.system(size: 26, weight: .semibold))
            .foregroundColor(.white)
    }
}
