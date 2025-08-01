import SwiftUI

struct TestDashboardView: View {
    @State private var selectedTag: TestTag = .engineTest
    @State private var selectedVIN: String?
    @State private var testRecords: [String: [TestRecord]] = [:]
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    let testTags: [TestTag] = [
        .engineTest,
        .brakeTest,
        .steeringTest,
        .suspensionTest,
        .electricalTest,
        .climateTest
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.01)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Abstract background elements
                abstractBackgroundElements
                
                HStack(spacing: 0) {
                    // Left Panel - Test Categories
                    testCategoriesPanel
                    
                    // Vertical separator
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 1)
                    
                    // Right Panel - Test Details
                    if let selectedVIN = selectedVIN {
                        testDetailPanel(vin: selectedVIN)
                    } else {
                        emptyStatePanel
                    }
                }
            }
        }
        .onAppear {
            loadTestData()
            startAnimations()
        }
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            // Floating geometric shapes
            Circle()
                .stroke(Color.gray.opacity(0.03), lineWidth: 1)
                .frame(width: 400, height: 400)
                .offset(x: -200, y: -100)
                .rotationEffect(.degrees(animationPhase * 0.2))
                .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: animationPhase)
            
            Rectangle()
                .fill(Color.black.opacity(0.005))
                .frame(width: 300, height: 2)
                .rotationEffect(.degrees(-20))
                .offset(x: 200, y: 150)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulseScale)
        }
    }
    
    private var testCategoriesPanel: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                VStack(spacing: 15) {
                    Text("Test Categories")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(.black)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 1)
                }
                .padding(.top, 20)
                
                ForEach(testTags, id: \.self) { tag in
                    testCategoryCard(tag: tag)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    private func testCategoryCard(tag: TestTag) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Category Header
            categoryHeader(tag: tag)
            
            // VIN List for this category
            if let records = testRecords[tag.rawValue] {
                VStack(spacing: 12) {
                    ForEach(records, id: \.id) { record in
                        vinRow(record: record)
                    }
                }
            }
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 25)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(
                    tag == selectedTag ? Color.black.opacity(0.2) : Color.gray.opacity(0.1), 
                    lineWidth: 1
                )
        )
        .onTapGesture {
            selectedTag = tag
        }
    }
    
    private func categoryHeader(tag: TestTag) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(tag.displayName)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.black)
                    
                    Text(tag.duration)
                        .font(.system(size: 12, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(tag == selectedTag ? pulseScale : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
                    
                    Text("Active")
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
            }
            
            // Abstract divider
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
                .scaleEffect(x: tag == selectedTag ? 1.0 : 0.5, anchor: .leading)
                .animation(.easeInOut(duration: 0.3), value: selectedTag)
        }
    }
    
    private func vinRow(record: TestRecord) -> some View {
        Button(action: {
            selectedVIN = record.vin
        }) {
            HStack(spacing: 15) {
                Rectangle()
                    .fill(Color.black.opacity(selectedVIN == record.vin ? 0.8 : 0.1))
                    .frame(width: 2, height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.vin)
                        .font(.system(size: 14, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                    
                    Text(formatDate(record.startTime))
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                statusIndicator(status: record.status)
            }
            .padding(.vertical, 8)
            .background(
                selectedVIN == record.vin ? Color.gray.opacity(0.02) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusIndicator(status: TestStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 4, height: 4)
            
            Text(status.displayName)
                .font(.system(size: 10, weight: .ultraLight))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func statusColor(_ status: TestStatus) -> Color {
        switch status {
        case .completed: return Color.black.opacity(0.6)
        case .inProgress: return Color.gray.opacity(0.8)
        case .failed: return Color.gray.opacity(0.4)
        }
    }
    
    private func testDetailPanel(vin: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 35) {
                // Header
                VStack(alignment: .leading, spacing: 15) {
                    Text("Session Details")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(.black)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 1)
                }
                
                if let record = findRecord(by: vin) {
                    testInfoSection(record: record)
                    locationSection(record: record)
                    recordingSection(record: record)
                }
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    private var emptyStatePanel: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "doc.text")
                            .font(.system(size: 24, weight: .ultraLight))
                            .foregroundColor(.gray)
                    )
                
                VStack(spacing: 8) {
                    Text("Select Test Record")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.black)
                    
                    Text("Choose a VIN from the left panel to view details")
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    private func testInfoSection(record: TestRecord) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Test Information")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            VStack(spacing: 15) {
                InfoRow(label: "Test Type", value: record.testType.displayName)
                InfoRow(label: "VIN", value: record.vin)
                InfoRow(label: "Test Time", value: DateFormatter.shortTime.string(from: record.startTime))
                InfoRow(label: "Duration", value: formatDuration(record.recordingDuration))
            }
            .padding(25)
            .background(Color.gray.opacity(0.01))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func locationSection(record: TestRecord) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("GPS Coordinates")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 15) {
                coordinateRow(
                    label: "Start Position",
                    coordinate: record.startCoordinate,
                    isStart: true
                )
                
                coordinateRow(
                    label: "End Position", 
                    coordinate: record.endCoordinate,
                    isStart: false
                )
            }
            .padding(25)
            .background(Color.gray.opacity(0.01))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func coordinateRow(label: String, coordinate: String, isStart: Bool) -> some View {
        HStack(spacing: 15) {
            Circle()
                .fill(isStart ? Color.black.opacity(0.6) : Color.gray.opacity(0.4))
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.gray)
                
                Text(coordinate)
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
    }
    
    private func recordingSection(record: TestRecord) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recording Files")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            VStack(spacing: 15) {
                InfoRow(label: "Duration", value: formatDuration(record.recordingDuration))
                InfoRow(label: "Files", value: "3 segments")
                InfoRow(label: "Size", value: record.fileSize)
            }
            .padding(25)
            .background(Color.gray.opacity(0.01))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func startAnimations() {
        withAnimation {
            pulseScale = 1.3
        }
        
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func findRecord(by vin: String) -> TestRecord? {
        for records in testRecords.values {
            if let record = records.first(where: { $0.vin == vin }) {
                return record
            }
        }
        return nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d分%02d秒", minutes, seconds)
    }
    
    private func loadTestData() {
        // Sample data - replace with actual data loading
        let sampleRecords = [
            TestRecord(
                vin: "1HGBH41JXMN109186",
                status: .completed,
                startTime: Date(),
                endTime: Date(),
                testType: .engineTest,
                recordingDuration: 1890, // 31分30秒
                fileSize: "2.3MB",
                startCoordinate: "31.161240, 121.472366",
                endCoordinate: "31.165421, 121.478912"
            ),
            TestRecord(
                vin: "2FMDK3GC8NBA12345",
                status: .completed,
                startTime: Date(),
                endTime: Date(),
                testType: .engineTest,
                recordingDuration: 1200, // 20分钟
                fileSize: "1.8MB",
                startCoordinate: "31.163456, 121.475123",
                endCoordinate: "31.167234, 121.480567"
            ),
            TestRecord(
                vin: "3WDX7AJ9DM123456",
                status: .inProgress,
                startTime: Date(),
                endTime: nil,
                testType: .engineTest,
                recordingDuration: 1200, // 20分钟
                fileSize: "1.5MB",
                startCoordinate: "31.165123, 121.477890",
                endCoordinate: "未完成"
            )
        ]
        
        testRecords = Dictionary(grouping: sampleRecords, by: { $0.testType.rawValue })
    }
}

// MARK: - Supporting Structures

enum TestTag: String, CaseIterable {
    case engineTest = "Engine Test"
    case brakeTest = "Brake Test"
    case steeringTest = "Steering Test"
    case suspensionTest = "Suspension Test"
    case electricalTest = "Electrical Test"
    case climateTest = "Climate Control Test"
    
    var displayName: String {
        switch self {
        case .engineTest: return "Engine Performance"
        case .brakeTest: return "Brake System"
        case .steeringTest: return "Steering Response"
        case .suspensionTest: return "Suspension Analysis"
        case .electricalTest: return "Electrical System"
        case .climateTest: return "Climate Control"
        }
    }
    
    var duration: String {
        switch self {
        case .engineTest: return "1h 15m"
        case .brakeTest: return "45min"
        case .steeringTest: return "30min"
        case .suspensionTest: return "1h"
        case .electricalTest: return "20min"
        case .climateTest: return "35min"
        }
    }
}

enum TestStatus: String {
    case completed = "Completed"
    case inProgress = "In Progress"
    case failed = "Failed"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .completed: return .black
        case .inProgress: return .gray
        case .failed: return .gray
        }
    }
}

struct TestRecord: Identifiable {
    let id = UUID()
    let vin: String
    let status: TestStatus
    let startTime: Date
    let endTime: Date?
    let testType: TestTag
    let recordingDuration: TimeInterval
    let fileSize: String
    let startCoordinate: String
    let endCoordinate: String
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .light, design: .monospaced))
                .foregroundColor(.black)
        }
    }
}

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    TestDashboardView()
} 
