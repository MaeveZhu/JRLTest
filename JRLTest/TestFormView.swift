import SwiftUI
import AVFoundation
import CoreLocation

struct TestFormView: View {
    @State private var vin = ""
    @State private var testExecutionId = ""
    @State private var selectedTag = "Engine Test"
    @State private var milesBefore = 138
    @State private var milesAfter = 160
    @State private var showingRecordingView = false
    @State private var showingResultsView = false
    @State private var showingLocationPermissionAlert = false
    @State private var showingMicrophonePermissionAlert = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    @StateObject private var locationManager = LocationManager()
    
    let availableTags = [
        "Engine Test",
        "Brake Test", 
        "Steering Test",
        "Suspension Test",
        "Electrical Test",
        "Climate Control Test"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("Fill in Form 1")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // 表单容器
                VStack(spacing: 20) {
                    // VIN输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VIN:")
                            .font(.headline)
                        TextField("Enter VIN", text: $vin)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Test Execution ID输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Execution ID:")
                            .font(.headline)
                        TextField("Enter Test Execution ID", text: $testExecutionId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Tag选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag (what are you testing today):")
                            .font(.headline)
                        Picker("Select Tag", selection: $selectedTag) {
                            ForEach(availableTags, id: \.self) { tag in
                                Text(tag).tag(tag)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Miles Before
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Miles Before:")
                            .font(.headline)
                        HStack {
                            TextField("Miles", value: $milesBefore, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            
                            Stepper("", value: $milesBefore, in: 0...999999)
                                .labelsHidden()
                        }
                    }
                    
                    // Start按钮
                    Button(action: {
                        checkPermissionsAndStart()
                    }) {
                        Text("Start")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    .disabled(vin.isEmpty || testExecutionId.isEmpty)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Vehicle Test Form")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingRecordingView) {
            TestRecordingView(
                vin: vin,
                testExecutionId: testExecutionId,
                tag: selectedTag,
                milesBefore: milesBefore,
                milesAfter: $milesAfter,
                showingResultsView: $showingResultsView
            )
        }
        .sheet(isPresented: $showingResultsView) {
            TestResultsView(
                vin: vin,
                testExecutionId: testExecutionId,
                tag: selectedTag,
                milesBefore: milesBefore,
                milesAfter: milesAfter
            )
        }
        .alert("位置权限", isPresented: $showingLocationPermissionAlert) {
            Button("允许") {
                locationManager.requestLocationPermission()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要位置权限来记录测试时的GPS坐标")
        }
        .alert("麦克风权限", isPresented: $showingMicrophonePermissionAlert) {
            Button("允许") {
                requestMicrophonePermission()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要麦克风权限来进行语音录音和语音识别")
        }
        .alert("权限提示", isPresented: $showingPermissionAlert) {
            Button("确定") { }
        } message: {
            Text(permissionAlertMessage)
        }
    }
    
    private func checkPermissionsAndStart() {
        // 检查位置权限
        if locationManager.locationStatus != .available {
            showingLocationPermissionAlert = true
            return
        }
        
        // 检查麦克风权限
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        if microphoneStatus != .granted {
            showingMicrophonePermissionAlert = true
            return
        }
        
        // 所有权限都已获取，可以开始
        showingRecordingView = true
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    // 权限获取成功，可以开始
                    self.showingRecordingView = true
                } else {
                    self.permissionAlertMessage = "麦克风权限被拒绝，无法进行录音"
                    self.showingPermissionAlert = true
                }
            }
        }
    }
}

struct TestFormView_Previews: PreviewProvider {
    static var previews: some View {
        TestFormView()
    }
} 