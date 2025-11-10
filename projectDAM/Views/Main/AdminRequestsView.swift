//
//  AdminRequestsView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct AdminRequestsView: View {
    @State private var selectedTab = 0
    @State private var pendingCount = 3
    @State private var approvedCount = 2
    @State private var rejectedCount = 0
    
    enum FilterTab: Int, CaseIterable {
        case pending, approved, rejected
        
        var label: String {
            switch self {
            case .pending: return "Pending"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            }
        }
        
        var count: Int {
            switch self {
            case .pending: return 3
            case .approved: return 2
            case .rejected: return 0
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
                    // Filter Tabs
                    filterTabsView()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case 0:
                                pendingRequestsContent()
                            case 1:
                                approvedRequestsContent()
                            case 2:
                                rejectedRequestsContent()
                            default:
                                EmptyView()
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, DS.paddingMD)
                        .padding(.vertical, DS.paddingMD)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Requests Management")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Filter Tabs
    private func filterTabsView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(FilterTab.allCases, id: \.self) { tab in
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text(tab.label)
                                .font(.system(size: 14, weight: .semibold))
                            
                            if tab.count > 0 {
                                ZStack {
                                    Circle()
                                        .fill(
                                            tab == .pending ? Color.brandError :
                                            tab == .approved ? Color.brandSuccess :
                                            Color.secondary
                                        )
                                    
                                    Text("\(tab.count)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 22, height: 22)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
    
    // MARK: - Pending Requests
    private func pendingRequestsContent() -> some View {
        VStack(spacing: 16) {
            // Header Stats
            HStack(spacing: 12) {
                StatBadge(
                    icon: "clock.fill",
                    label: "Pending",
                    count: "\(pendingCount)",
                    color: .brandWarning
                )
                
                StatBadge(
                    icon: "checkmark.circle.fill",
                    label: "Approved",
                    count: "\(approvedCount)",
                    color: .brandSuccess
                )
                
                StatBadge(
                    icon: "dollar.circle.fill",
                    label: "This Month",
                    count: "$3.62K",
                    color: .brandError
                )
            }
            
            // Payment Request Cards
            PaymentRequestCard(
                amount: "$850.00",
                instructor: "Dr. Sami Rezgui",
                course: "Advanced Web Development",
                studentCount: 45,
                date: "Nov 3, 2025",
                status: .pending
            )
            
            PaymentRequestCard(
                amount: "$1200.00",
                instructor: "Prof. Leila Ben Amor",
                course: "Data Structures & Algorithms",
                studentCount: 67,
                date: "Nov 4, 2025",
                status: .pending
            )
            
            PaymentRequestCard(
                amount: "$650.00",
                instructor: "Eng. Karim Hassine",
                course: "Mobile App Development",
                studentCount: 38,
                date: "Nov 5, 2025",
                status: .pending
            )
        }
    }
    
    // MARK: - Approved Requests
    private func approvedRequestsContent() -> some View {
        VStack(spacing: 16) {
            PaymentRequestCard(
                amount: "$1500.00",
                instructor: "Dr. Mohamed Trabelsi",
                course: "Cybersecurity Basics",
                studentCount: 52,
                date: "Nov 1, 2025",
                status: .approved
            )
            
            PaymentRequestCard(
                amount: "$2000.00",
                instructor: "Dr. Sarah Smith",
                course: "Machine Learning Fundamentals",
                studentCount: 78,
                date: "Oct 28, 2025",
                status: .approved
            )
        }
    }
    
    // MARK: - Rejected Requests
    private func rejectedRequestsContent() -> some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandError.opacity(0.05),
                                Color.brandWarning.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.brandSuccess.opacity(0.3))
                    
                    Text("No Rejected Requests")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("All requests have been successfully processed")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Stat Badge Component
private struct StatBadge: View {
    let icon: String
    let label: String
    let count: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Text(count)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.systemBackground))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Payment Request Card
private struct PaymentRequestCard: View {
    enum RequestStatus {
        case pending, approved, rejected
        
        var backgroundColor: LinearGradient {
            switch self {
            case .pending:
                return LinearGradient(
                    colors: [Color.brandWarning.opacity(0.05), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .approved:
                return LinearGradient(
                    colors: [Color.brandSuccess.opacity(0.05), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .rejected:
                return LinearGradient(
                    colors: [Color.brandError.opacity(0.05), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        var borderColor: Color {
            switch self {
            case .pending: return Color.brandWarning.opacity(0.3)
            case .approved: return Color.brandSuccess.opacity(0.3)
            case .rejected: return Color.brandError.opacity(0.3)
            }
        }
        
        var statusLabel: String {
            switch self {
            case .pending: return "Pending"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            }
        }
        
        var statusColor: Color {
            switch self {
            case .pending: return .brandWarning
            case .approved: return .brandSuccess
            case .rejected: return .brandError
            }
        }
    }
    
    let amount: String
    let instructor: String
    let course: String
    let studentCount: Int
    let date: String
    let status: RequestStatus
    
    @State private var isApproved = false
    @State private var isRejected = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.2),
                                    Color.brandAccent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                }
                .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Request")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(amount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(status.statusColor.opacity(0.15))
                        
                        Text(status.statusLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(status.statusColor)
                    }
                    .frame(width: 70, height: 24)
                }
            }
            
            // Details
            VStack(spacing: 12) {
                DetailRow(
                    icon: "person.fill",
                    label: "Instructor",
                    value: instructor
                )
                
                DetailRow(
                    icon: "book.fill",
                    label: "Course",
                    value: course
                )
                
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("\(studentCount) students enrolled")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(date)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action Buttons (only for pending)
            if status == .pending {
                HStack(spacing: 12) {
                    Button(action: { isApproved.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Approve")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.brandSuccess.opacity(isApproved ? 1 : 0.85))
                        )
                    }
                    
                    Button(action: { isRejected.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Reject")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.brandError)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.brandError.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                }
            }
        }
        .padding(DS.paddingMD)
        .background(status.backgroundColor)
        .border(status.borderColor, width: 1, cornerRadius: DS.cornerRadiusMD)
    }
}

// MARK: - Detail Row Component
private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Border Extension
extension View {
    func border(_ color: Color, width: CGFloat, cornerRadius: CGFloat) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
}

#Preview {
    AdminRequestsView()
}
