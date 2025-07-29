import SwiftUI

struct TestDashboardView: View {
    @State private var selectedTag: TestTag = .engineTest
    @State private var selectedVIN: String?
    @State private var testRecords: [String: [TestRecord]] = [:]
    
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
            HStack(spacing: 0) {
                // Left Panel - Test Categories
                testCategoriesPanel
                
                // Right Panel - Test Details
                if let selectedVIN = selectedVIN {
                    testDetailPanel(vin: selectedVIN)
                } else {
                    emptyStatePanel
                }
            }
            .navigationTitle("测试记录")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadTestData()
        }
    }
    
    private var testCategoriesPanel: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(testTags, id: \.self) { tag in
                    testCategoryCard(tag: tag)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.05))
    }
    
    private func testCategoryCard(tag: TestTag) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            categoryHeader(tag: tag)
            
            // VIN List for this category
            if let records = testRecords[tag.rawValue] {
                ForEach(records, id: \.id) { record in
                    vinRow(record: record)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tag == .brakeTest ? Color.blue.opacity(0.1) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tag == .brakeTest ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private func categoryHeader(tag: TestTag) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tag.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(tag.duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("You")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func vinRow(record: TestRecord) -> some View {
        Button(action: {
            selectedVIN = record.vin
        }) {
            HStack {
                Text(record.vin)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                
                Spacer()
                
                statusBadge(status: record.status)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusBadge(status: TestStatus) -> some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(status.color)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
    
    private func testDetailPanel(vin: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("测试会话详情")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let record = findRecord(by: vin) {
                    testInfoSection(record: record)
                    locationSection(record: record)
                    recordingSection(record: record)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    private var emptyStatePanel: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("选择一个测试记录")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("点击左侧的VIN码查看详细信息")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    private func testInfoSection(record: TestRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("测试信息")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "测试类型", value: record.testType.displayName)
                InfoRow(label: "VIN", value: record.vin)
                InfoRow(label: "测试时间", value: DateFormatter.shortTime.string(from: record.startTime))
                InfoRow(label: "录音时长", value: formatDuration(record.recordingDuration))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func locationSection(record: TestRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GPS坐标")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("起始位置:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(record.startCoordinate)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("结束位置:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(record.endCoordinate)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func recordingSection(record: TestRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("录音文件")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "录音时长", value: formatDuration(record.recordingDuration))
                InfoRow(label: "文件数量", value: "3个")
                InfoRow(label: "文件大小", value: record.fileSize)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
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
        case .engineTest: return "Engine Performance Test"
        case .brakeTest: return "Brake System Validation"
        case .steeringTest: return "Steering Response Test"
        case .suspensionTest: return "Suspension Analysis"
        case .electricalTest: return "Electrical System Check"
        case .climateTest: return "Climate Control Test"
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
    case completed = "完成"
    case inProgress = "进行中"
    case failed = "失败"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .inProgress: return .orange
        case .failed: return .red
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