# JRL Test App

A comprehensive iOS application for driving test management with CarPlay support.

## Features

- **Driving Test Management**: Create and manage driving test sessions
- **Voice Recording**: Record audio with location tracking
- **CarPlay Integration**: Full CarPlay support for hands-free operation
- **Siri Integration**: Voice commands for test operations
- **Location Services**: GPS tracking and coordinate management

## CarPlay Testing in Simulator

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ Simulator
- No CarPlay entitlement required

### Testing Steps

1. **Build and Run**: Build the app in Xcode and run it in the iOS Simulator

2. **Enable CarPlay Display**: 
   - In the Simulator, go to `Hardware` → `External Displays` → `CarPlay`
   - This will open a CarPlay display window

3. **Test CarPlay Interface**:
   - The app will automatically detect CarPlay connection
   - Use the "测试 CarPlay 功能" button in the main app to test CarPlay features
   - CarPlay templates will appear in the CarPlay display window

4. **CarPlay Features Available**:
   - Start/Stop driving test sessions
   - Start/Stop voice recording
   - View test status and information
   - Quick access to main app features

### CarPlay Architecture

The app uses a scene-based architecture for CarPlay support:

- **CarPlaySceneDelegate**: Manages CarPlay interface lifecycle
- **CarPlayIntegrationManager**: Coordinates between iOS app and CarPlay
- **CarPlayManager**: Manages CarPlay state and communication
- **CarPlayContentView**: SwiftUI interface for CarPlay testing

### Simulator Compatibility

All CarPlay templates used are simulator-safe:
- `CPListTemplate` for navigation
- `CPAlertTemplate` for confirmations
- `CPActionSheetTemplate` for options

No real CarPlay hardware or entitlements are required for testing.

## Development

### Project Structure

```
JRLTest/
├── JRLTest/                    # Main app target
│   ├── CarPlaySceneDelegate.swift      # CarPlay scene management
│   ├── CarPlayIntegrationManager.swift # CarPlay integration logic
│   ├── CarPlayManager.swift           # CarPlay state management
│   ├── CarPlayContentView.swift       # CarPlay SwiftUI interface
│   ├── CarPlayTestView.swift          # CarPlay testing interface
│   └── ...                           # Other app files
├── JRLTest Siri Extension/            # Siri integration
└── JRLTest.xcodeproj/                 # Xcode project
```

### Key Components

- **Info.plist**: Configured with CarPlay scene support
- **Scene Configuration**: Uses `CPTemplateApplicationSceneSessionRoleApplication`
- **Template System**: Simulator-safe CarPlay templates
- **State Synchronization**: Real-time updates between iOS and CarPlay

## Troubleshooting

### CarPlay Not Appearing in Simulator

1. Ensure you're using iOS 17.0+ Simulator
2. Check that `Hardware` → `External Displays` → `CarPlay` is selected
3. Verify the app has built successfully
4. Check console logs for CarPlay connection messages

### Build Issues

1. Ensure Xcode 15.0+ is installed
2. Check that all CarPlay framework imports are present
3. Verify scene configuration in Info.plist

## License

This project is proprietary software for JRL driving test management. 