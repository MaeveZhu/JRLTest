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
    @State private var startCoordinate: CLLocationCoordinate2D?
    
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
            mainContent
        }
        .sheet(isPresented: $showingRecordingView) {
            recordingView
        }
        .sheet(isPresented: $showingResultsView) {
            resultsView
        }
        .alert("位置权限", isPresented: $showingLocationPermissionAlert) {
            locationPermissionButtons
        } message: {
            locationPermissionMessage
        }
        .alert("麦克风权限", isPresented: $showingMicrophonePermissionAlert) {
            microphonePermissionButtons
        } message: {
            microphonePermissionMessage
        }
        .alert("权限提示", isPresented: $showingPermissionAlert) {
            permissionButtons
        } message: {
            permissionMessage
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
    
    // MARK: - View Components
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            titleSection
            formContainer
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
        .navigationTitle("Vehicle Test Form")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var titleSection: some View {
        Text("Fill in Form 1")
            .font(.title)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
    
    private var formContainer: some View {
        VStack(spacing: 20) {
            vinInputSection
            testExecutionIdSection
            tagSelectionSection
            milesBeforeSection
            startButtonSection
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    private var vinInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VIN:")
                .font(.headline)
            TextField("Enter VIN", text: $vin)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var testExecutionIdSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Execution ID:")
                .font(.headline)
            TextField("Enter Test Execution ID", text: $testExecutionId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var tagSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tag (what are you testing today):")
                .font(.headline)
            tagPicker
        }
    }
    
    private var tagPicker: some View {
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
    
    private var milesBeforeSection: some View {
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
    }
    
    private var startButtonSection: some View {
        Button(action: {
            checkPermissionsAndStart()
        }) {
            startButtonContent
        }
        .disabled(vin.isEmpty || testExecutionId.isEmpty)
    }
    
    private var startButtonContent: some View {
        Text("Start")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .cornerRadius(10)
    }
    
    private var recordingView: some View {
        TestRecordingView(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: selectedTag,
            milesBefore: milesBefore,
            milesAfter: $milesAfter,
            startCoordinate: startCoordinate,
            showingResultsView: $showingResultsView
        )
    }
    
    private var resultsView: some View {
        TestResultsView(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: selectedTag,
            milesBefore: milesBefore,
            milesAfter: milesAfter
        )
    }
    
    private var locationPermissionButtons: some View {
        Group {
            Button("允许") {
                locationManager.requestLocationPermission()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var locationPermissionMessage: some View {
        Text("需要位置权限来记录测试时的GPS坐标")
    }
    
    private var microphonePermissionButtons: some View {
        Group {
            Button("允许") {
                requestMicrophonePermission()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var microphonePermissionMessage: some View {
        Text("需要麦克风权限来进行语音录音和语音识别")
    }
    
    private var permissionButtons: some View {
        Button("确定") { }
    }
    
    private var permissionMessage: some View {
        Text(permissionAlertMessage)
    }
    
    // MARK: - Methods
    
    private func checkPermissionsAndStart() {
        // 记录起始GPS坐标
        startCoordinate = locationManager.currentLocation
        
        // 检查位置权限
        if locationManager.locationStatus != .available {
            showingLocationPermissionAlert = true
            return
        }
        
        // 检查麦克风权限
        let microphoneStatus = AVAudioApplication.shared.recordPermission
        if microphoneStatus != .granted {
            showingMicrophonePermissionAlert = true
            return
        }
        
        // 所有权限都已获取，可以开始
        showingRecordingView = true
    }
    
    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
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