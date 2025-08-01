import SwiftUI

struct TestResultsView: View {
    let vin: String
    let testExecutionId: String
    let tag: String
    let milesBefore: Int
    let milesAfter: Int
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showSuccessAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.01)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Abstract background elements
                abstractBackgroundElements
                
                ScrollView {
                    VStack(spacing: 50) {
                        successIndicator
                        testSummarySection
                        recordingStatusSection
                        actionButtonsSection
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Test Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            // Floating geometric shapes
            Circle()
                .stroke(Color.gray.opacity(0.02), lineWidth: 1)
                .frame(width: 350, height: 350)
                .offset(x: -100, y: -200)
                .rotationEffect(.degrees(animationPhase * 0.1))
                .animation(.linear(duration: 80).repeatForever(autoreverses: false), value: animationPhase)
            
            Rectangle()
                .fill(Color.black.opacity(0.005))
                .frame(width: 150, height: 2)
                .rotationEffect(.degrees(30))
                .offset(x: 120, y: 250)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulseScale)
        }
    }
    
    private var successIndicator: some View {
        VStack(spacing: 25) {
            // Success icon container
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    .frame(width: 120, height: 120)
                    .scaleEffect(showSuccessAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8), value: showSuccessAnimation)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(.black)
                    .opacity(showSuccessAnimation ? 1.0 : 0.0)
                    .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: showSuccessAnimation)
            }
            
            VStack(spacing: 12) {
                Text("Session Complete")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(.black)
                    
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 1)
                
                Text("Test data has been successfully recorded")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var testSummarySection: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Session Summary")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.black)
                
            
            VStack(spacing: 18) {
                summaryRow(label: "Test Category", value: tag)
                summaryRow(label: "Vehicle ID", value: vin)
                summaryRow(label: "Execution ID", value: testExecutionId)
                summaryRow(label: "Initial Miles", value: "\(milesBefore)")
                summaryRow(label: "Final Miles", value: "\(milesAfter)")
                
                // Distance calculation with emphasis
                HStack {
                    Text("Distance Covered")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.gray)
                        
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 2, height: 16)
                        
                        Text("\(milesAfter - milesBefore) miles")
                            .font(.system(size: 16, weight: .light, design: .monospaced))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(30)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func summaryRow(label: String, value: String) -> some View {
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
    
    private var recordingStatusSection: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Recording Status")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.black)
                
            
            VStack(spacing: 15) {
                statusRow(
                    icon: "mic",
                    title: "Voice Recording",
                    subtitle: "Audio data captured successfully",
                    isCompleted: true
                )
                
                statusRow(
                    icon: "location",
                    title: "GPS Coordinates",
                    subtitle: "Position data logged",
                    isCompleted: true
                )
                
                statusRow(
                    icon: "clock",
                    title: "Session Timing",
                    subtitle: "Duration and timestamps recorded",
                    isCompleted: true
                )
            }
        }
    }
    
    private func statusRow(icon: String, title: String, subtitle: String, isCompleted: Bool) -> some View {
        HStack(spacing: 20) {
            // Icon container
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .ultraLight))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(isCompleted ? Color.black.opacity(0.6) : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isCompleted ? pulseScale : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
                
                Text(isCompleted ? "Complete" : "Pending")
                    .font(.system(size: 10, weight: .ultraLight))
                    .foregroundColor(.gray)
                    
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 25)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Primary action
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 15) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 18)
                    
                    Text("Start New Session")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                        
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Secondary action
            Button(action: {
                // TODO: Navigate to test list
                dismiss()
            }) {
                HStack(spacing: 15) {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: 18)
                    
                    Text("View All Sessions")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.black)
                        
                    
                    Spacer()
                    
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 18)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("All session data has been automatically saved")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
        }
    }
    
    private func startAnimations() {
        withAnimation {
            showSuccessAnimation = true
            pulseScale = 1.2
        }
        
        withAnimation(.linear(duration: 80).repeatForever(autoreverses: false)) {
            animationPhase = 360
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
