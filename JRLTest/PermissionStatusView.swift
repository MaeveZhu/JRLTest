import SwiftUI

/**
 * PermissionStatusView - Reusable view for displaying permission status
 * 
 * BEHAVIOR:
 * - Shows current permission status for all app permissions
 * - Provides buttons to request permissions or open settings
 * - Displays user-friendly messages for missing permissions
 * - Updates automatically when permission status changes
 * 
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 */
struct PermissionStatusView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            permissionListSection
            actionButtonsSection
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("权限状态")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            Text(permissionManager.allPermissionsGranted ? "所有权限已授权" : "部分权限需要授权")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(permissionManager.allPermissionsGranted ? .green : .orange)
        }
    }
    
    private var permissionListSection: some View {
        VStack(spacing: 12) {
            PermissionRow(
                title: "麦克风",
                status: permissionManager.microphonePermission.description,
                isGranted: permissionManager.microphonePermission == .granted
            )
            
            PermissionRow(
                title: "位置",
                status: permissionManager.locationPermission.description,
                isGranted: permissionManager.locationPermission == .authorizedWhenInUse
            )
            
            PermissionRow(
                title: "语音识别",
                status: permissionManager.speechRecognitionPermission.description,
                isGranted: permissionManager.speechRecognitionPermission == .authorized
            )
            
            PermissionRow(
                title: "Siri",
                status: permissionManager.siriPermission.description,
                isGranted: permissionManager.siriPermission == .authorized
            )
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !permissionManager.allPermissionsGranted {
                Button("请求所有权限") {
                    requestAllPermissions()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("打开设置") {
                    showingSettings = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .alert("打开设置", isPresented: $showingSettings) {
            Button("取消", role: .cancel) { }
            Button("打开设置") {
                permissionManager.openSettings()
            }
        } message: {
            Text("需要在设置中手动授权权限")
        }
    }
    
    private func requestAllPermissions() {
        permissionManager.requestAllPermissions { granted in
            if granted {
                print("✅ All permissions granted")
            } else {
                print("❌ Some permissions denied")
            }
        }
    }
}

/**
 * PermissionRow - Individual permission status row
 * 
 * BEHAVIOR:
 * - Displays individual permission status with icon and color
 * - Shows permission title and current status
 * - Uses appropriate colors for granted/denied states
 * 
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 */
struct PermissionRow: View {
    let title: String
    let status: String
    let isGranted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .red)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                Text(status)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isGranted ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

/**
 * PrimaryButtonStyle - Primary action button style
 * 
 * BEHAVIOR:
 * - Provides consistent primary button styling
 * - Uses blue background with white text
 * - Includes hover and press states
 * 
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 */
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/**
 * SecondaryButtonStyle - Secondary action button style
 * 
 * BEHAVIOR:
 * - Provides consistent secondary button styling
 * - Uses transparent background with blue border
 * - Includes hover and press states
 * 
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 */
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PermissionStatusView()
        .padding()
} 