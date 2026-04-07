import SwiftUI
import WebKit

// MARK: - Find in Page View
struct FindInPageView: View {
    @ObservedObject var browserViewModel: BrowserViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var matchCount = 0
    @State private var currentMatch = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Find in page", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) { newValue in
                    // Trigger find in page
                    if let webView = browserViewModel.webView {
                        let script = """
                        window.find('\(newValue)', false, false, true, false, true, true);
                        """
                        webView.evaluateJavaScript(script) { result, error in
                            // Handle result
                        }
                    }
                }
            
            if !searchText.isEmpty {
                Text("\(currentMatch)/\(matchCount)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Button {
                    // Previous match
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Button {
                    // Next match
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding()
    }
}

// MARK: - Download Manager View
struct DownloadManagerView: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Downloads")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Download list
            if shellViewModel.downloadRecords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text("No downloads")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(shellViewModel.downloadRecords.sorted(by: { $0.createdAt > $1.createdAt })) { download in
                        DownloadRow(download: download)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Download Row
struct DownloadRow: View {
    let download: BrowserDownloadRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            Image(systemName: iconForFile(download.title))
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(download.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(formatFileSize(nil))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    if download.status == .finished, let dest = download.destinationPath {
                        Button {
                            NSWorkspace.shared.selectFile(dest, inFileViewerRootedAtPath: "")
                        } label: {
                            Text("Show in Finder")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            if download.status == .finished {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16))
            } else if download.status == .inProgress {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForFile(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.text"
        case "jpg", "jpeg", "png", "gif", "webp": return "photo"
        case "mp4", "mov", "avi": return "film"
        case "mp3", "wav", "aac": return "music.note"
        case "zip", "rar", "7z": return "archivebox"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        default: return "doc"
        }
    }
    
    private func formatFileSize(_ size: Int64?) -> String {
        guard let size = size else { return "Unknown size" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - History Browser View
struct HistoryBrowserView: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @Binding var isPresented: Bool
    let onSelectURL: (String) -> Void
    
    @State private var searchText = ""
    @State private var selectedTimeRange = TimeRange.today
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case allTime = "All Time"
    }
    
    var filteredHistory: [BrowserHistoryEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return shellViewModel.recentHistoryEntries.filter { entry in
            // Time range filter
            let matchesTimeRange: Bool = {
                switch selectedTimeRange {
                case .today:
                    return calendar.isDateInToday(entry.visitedAt)
                case .yesterday:
                    return calendar.isDateInYesterday(entry.visitedAt)
                case .last7Days:
                    return calendar.dateComponents([.day], from: entry.visitedAt, to: now).day ?? 0 <= 7
                case .last30Days:
                    return calendar.dateComponents([.day], from: entry.visitedAt, to: now).day ?? 0 <= 30
                case .allTime:
                    return true
                }
            }()
            
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                entry.title.lowercased().contains(searchText.lowercased()) ||
                entry.url.lowercased().contains(searchText.lowercased())
            
            return matchesTimeRange && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Search and filter
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search history", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.textBackgroundColor))
                )
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // History list
            if filteredHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text("No history found")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedHistory.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatDate(date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        ) {
                            ForEach(groupedHistory[date] ?? []) { entry in
                                HistoryRow(entry: entry)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onSelectURL(entry.url)
                                        isPresented = false
                                    }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 600, height: 500)
    }
    
    var groupedHistory: [Date: [BrowserHistoryEntry]] {
        Dictionary(grouping: filteredHistory) { entry in
            Calendar.current.startOfDay(for: entry.visitedAt)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - History Row
struct HistoryRow: View {
    let entry: BrowserHistoryEntry
    
    var body: some View {
        HStack(spacing: 12) {
            FaviconAsyncImage(url: entry.url, size: 16, fallback: "globe")
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Text(entry.url)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(formatTime(entry.visitedAt))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
