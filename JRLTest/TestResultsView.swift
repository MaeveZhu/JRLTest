import SwiftUI

struct TestResultsView: View {
    let vin: String
    let testExecutionId: String
    let tag: String
    let milesBefore: Int
    let milesAfter: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 成功图标
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("测试完成")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // 测试信息
                VStack(spacing: 20) {
                    Text("Test Preview")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 15) {
                        // 测试用例信息
                        HStack {
                            Text("Test Case:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(tag)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("VIN:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(vin)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Execution ID:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(testExecutionId)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Miles Before:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(milesBefore)")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Miles After:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(milesAfter)")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Distance:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(milesAfter - milesBefore) miles")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // 录音信息
                VStack(spacing: 15) {
                    Text("录音信息")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.blue)
                        Text("语音录音已保存")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("GPS坐标已记录")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // 底部按钮
                VStack(spacing: 15) {
                    Button("开始新测试") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("查看所有测试") {
                        // TODO: 导航到测试列表
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .padding()
            .navigationTitle("测试结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TestResultsView_Previews: PreviewProvider {
    static var previews: some View {
        TestResultsView(
            vin: "TEST123",
            testExecutionId: "EXEC001",
            tag: "Engine Test",
            milesBefore: 138,
            milesAfter: 160
        )
    }
} 