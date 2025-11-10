//
//  TeacherMessagesView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct TeacherMessagesView: View {
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var selectedMessage: String? = nil
    
    enum MessageTab: Int, CaseIterable {
        case qna, direct
        
        var label: String {
            switch self {
            case .qna: return "Q&A"
            case .direct: return "Direct Messages"
            }
        }
        
        var icon: String {
            switch self {
            case .qna: return "questionmark.circle.fill"
            case .direct: return "message.fill"
            }
        }
        
        var count: Int {
            switch self {
            case .qna: return 5
            case .direct: return 3
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBarView()
                    
                    // Message Tabs
                    messageTabsView()
                    
                    // Messages List
                    messagesList()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Messages & Q&A")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Search Bar
    private func searchBarView() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("Search messages...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.systemBackground).opacity(0.5))
                .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
        )
        .padding(DS.paddingMD)
    }
    
    // MARK: - Message Tabs
    private func messageTabsView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(MessageTab.allCases, id: \.self) { tab in
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .semibold))
                            
                            Text(tab.label)
                                .font(.system(size: 13, weight: .semibold))
                            
                            if tab.count > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandError)
                                    
                                    Text("\(tab.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 20, height: 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(selectedTab == tab.rawValue ? .brandPrimary : .secondary)
                        
                        if selectedTab == tab.rawValue {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.brandPrimary)
                                .frame(height: 3)
                        } else {
                            Color.clear.frame(height: 3)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab.rawValue
                        }
                    }
                }
            }
            .padding(.horizontal, DS.paddingMD)
            
            Divider()
                .padding(.top, 0)
        }
    }
    
    // MARK: - Messages List
    @ViewBuilder
    private func messagesList() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                switch selectedTab {
                case 0:
                    qnaContent()
                case 1:
                    directMessagesContent()
                default:
                    EmptyView()
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, DS.paddingMD)
            .padding(.vertical, DS.paddingMD)
        }
    }
    
    // MARK: - Q&A Content
    private func qnaContent() -> some View {
        VStack(spacing: 12) {
            MessageItemView(
                initials: "ABA",
                name: "Ahmed Ben Ali",
                course: "Web Development",
                subject: "How to implement JWT authentication?",
                preview: "I'm trying to implement JWT authentication in my Node.js project...",
                timestamp: "2h ago",
                isUnanswered: true,
                unreadCount: 1,
                messageType: .qna
            )
            
            MessageItemView(
                initials: "SM",
                name: "Sarra Mansour",
                course: "React Course",
                subject: "Understanding Redux concepts",
                preview: "Could you explain the difference between actions and reducers?",
                timestamp: "4h ago",
                isUnanswered: true,
                unreadCount: 1,
                messageType: .qna
            )
            
            MessageItemView(
                initials: "YT",
                name: "Youssef Trabelsi",
                course: "Full Stack Dev",
                subject: "Database optimization tips",
                preview: "What are the best practices for optimizing database queries?",
                timestamp: "1d ago",
                isUnanswered: false,
                unreadCount: 0,
                messageType: .qna
            )
            
            MessageItemView(
                initials: "LR",
                name: "Leila Rezgui",
                course: "Web Development",
                subject: "Debugging production errors",
                preview: "How do I properly handle errors in production?",
                timestamp: "2d ago",
                isUnanswered: false,
                unreadCount: 0,
                messageType: .qna
            )
            
            MessageItemView(
                initials: "KH",
                name: "Karim Hassine",
                course: "React Course",
                subject: "Component lifecycle questions",
                preview: "When should I use useEffect vs useLayoutEffect?",
                timestamp: "3d ago",
                isUnanswered: false,
                unreadCount: 0,
                messageType: .qna
            )
        }
    }
    
    // MARK: - Direct Messages Content
    private func directMessagesContent() -> some View {
        VStack(spacing: 12) {
            MessageItemView(
                initials: "ABA",
                name: "Ahmed Ben Ali",
                course: "Web Development",
                subject: "Assignment submission",
                preview: "I've submitted my assignment, can you review it?",
                timestamp: "30m ago",
                isUnanswered: false,
                unreadCount: 1,
                messageType: .direct
            )
            
            MessageItemView(
                initials: "SM",
                name: "Sarra Mansour",
                course: "React Course",
                subject: "Extension request",
                preview: "Can I get an extension for the project deadline?",
                timestamp: "1h ago",
                isUnanswered: false,
                unreadCount: 1,
                messageType: .direct
            )
            
            MessageItemView(
                initials: "YT",
                name: "Youssef Trabelsi",
                course: "Full Stack Dev",
                subject: "Thank you for the feedback",
                preview: "Thanks for reviewing my code and giving detailed feedback!",
                timestamp: "5h ago",
                isUnanswered: false,
                unreadCount: 0,
                messageType: .direct
            )
        }
    }
}

// MARK: - Message Item Component
private struct MessageItemView: View {
    enum MessageType {
        case qna, direct
    }
    
    let initials: String
    let name: String
    let course: String
    let subject: String
    let preview: String
    let timestamp: String
    let isUnanswered: Bool
    let unreadCount: Int
    let messageType: MessageType
    
    @State private var isSelected = false
    
    var body: some View {
        NavigationLink(destination: MessageDetailView(
            senderName: name,
            subject: subject,
            messageType: messageType
        )) {
            HStack(spacing: 12) {
                // Avatar with unread indicator
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.3),
                                    Color.brandAccent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(initials)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.brandPrimary)
                    
                    if unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.brandError)
                            
                            Text("\(unreadCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 20, height: 20)
                        .offset(x: 6, y: -6)
                    }
                }
                .frame(width: 48, height: 48)
                
                // Message Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(course)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brandPrimary.opacity(0.1))
                            .cornerRadius(4)
                        
                        if isUnanswered {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.brandWarning)
                        }
                    }
                    
                    Text(subject)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(preview)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Timestamp
                VStack(alignment: .trailing, spacing: 8) {
                    Text(timestamp)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if messageType == .qna && isUnanswered {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .padding(DS.paddingMD)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                    .fill(Color(.systemBackground))
                    .stroke(
                        unreadCount > 0 ?
                            Color.brandPrimary.opacity(0.2) :
                            Color.brandPrimary.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Message Detail View
private struct MessageDetailView: View {
    let senderName: String
    let subject: String
    let messageType: MessageItemView.MessageType
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Message Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Subject
                            VStack(alignment: .leading, spacing: 8) {
                                Text(subject)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("From: \(senderName)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            // Message Body
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                            
                            Spacer(minLength: 20)
                        }
                        .padding(DS.paddingMD)
                    }
                    
                    Divider()
                    
                    // Reply Section
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("Type your reply...", text: .constant(""))
                                .font(.system(size: 14, weight: .regular))
                                .textInputAutocapitalization(.sentences)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                                        .fill(Color(.systemBackground).opacity(0.5))
                                        .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
                                )
                            
                            Button(action: {}) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.brandPrimary)
                                    )
                            }
                        }
                    }
                    .padding(DS.paddingMD)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(.brandPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(subject)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    TeacherMessagesView()
}
