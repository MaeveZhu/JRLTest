import SwiftUI

struct TestFormView: View {
    @State private var vin = ""
    @State private var testExecutionId = ""
    @State private var selectedTag = "Engine Test"
    @State private var milesBefore = 138
    @State private var milesAfter = 160
    @State private var showingRecordingView = false
    @State private var showingResultsView = false
    
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
                        showingRecordingView = true
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
    }
}

struct TestFormView_Previews: PreviewProvider {
    static var previews: some View {
        TestFormView()
    }
} 