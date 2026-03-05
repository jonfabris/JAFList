# Build Instructions for JAFList

## Prerequisites

- macOS with Xcode 14.0 or later installed
- iOS Simulator or physical iOS device (iOS 16.0+)

## Quick Start

### Option 1: Using Xcode (Recommended)

1. **Open the project**:
   ```bash
   cd /Users/jonfabris/workspace/JAFList
   open JAFList.xcodeproj
   ```

2. **Select a target**:
   - In Xcode, select a simulator from the device menu (top toolbar)
   - Recommended: iPhone 14 or iPhone 15 simulator

3. **Build and Run**:
   - Press `Cmd + R` or click the Play button
   - Xcode will build the project and launch the simulator

### Option 2: Using Command Line

1. **List available simulators**:
   ```bash
   xcrun simctl list devices available | grep "iPhone"
   ```

2. **Build the project**:
   ```bash
   cd /Users/jonfabris/workspace/JAFList
   xcodebuild -project JAFList.xcodeproj \
              -scheme JAFList \
              -sdk iphonesimulator \
              -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
              clean build
   ```

3. **Run on simulator** (requires Xcode to be installed):
   - Use Xcode's interface for best experience
   - Or use `xcodebuild` with `-destination` flag

## First Build Steps

When you first open the project:

1. **Select Development Team** (if deploying to device):
   - Click on the JAFList project in the navigator
   - Select the JAFList target
   - Go to "Signing & Capabilities"
   - Select your Apple Developer Team
   - For simulator testing, this step is optional

2. **Verify Build Settings**:
   - Bundle Identifier: `com.yourname.JAFList` (change "yourname" if needed)
   - Deployment Target: iOS 16.0
   - Swift Language Version: Swift 5

3. **Build the project**:
   - Press `Cmd + B` to build without running
   - Check for any compilation errors

## Troubleshooting

### Code Signing Issues
- **Simulator**: No code signing required
- **Device**: Select your Apple Developer Team in Signing & Capabilities

### Build Errors
If you see build errors:

1. **Clean Build Folder**:
   - In Xcode: `Product` > `Clean Build Folder` (Cmd + Shift + K)
   - Or from terminal: `xcodebuild clean`

2. **Check Swift Version**:
   - Ensure Xcode is using Swift 5.0+
   - Check in Build Settings > Swift Language Version

3. **Verify File Structure**:
   - All Swift files should be in `JAFList/` directory
   - Project file should be at `JAFList.xcodeproj/project.pbxproj`

### Runtime Issues

If the app crashes or behaves unexpectedly:

1. **Check Console Logs**:
   - In Xcode, open the Debug area (Cmd + Shift + Y)
   - Look for error messages

2. **Reset Simulator**:
   - Device menu > Erase All Content and Settings
   - Or: `xcrun simctl erase all`

3. **Clean Data**:
   - The app stores data in Documents directory
   - Delete the app from simulator to reset

## Testing the App

Once the app is running:

### Basic Functionality Test

1. **Create a folder**:
   - Tap the `+` button (top-right)
   - Enter "Work" and tap Add

2. **Add a todo item**:
   - Tap on the "Work" folder
   - Tap the `+` button
   - Enter "Complete project" and tap Add

3. **Add a nested item**:
   - Swipe left on "Complete project"
   - Tap "Add Subitem" (blue button)
   - Enter "Write documentation" and tap Add

4. **Toggle completion**:
   - Tap the checkbox next to "Write documentation"
   - Text should show strikethrough

5. **Expand/Collapse**:
   - Tap on "Complete project" row
   - Nested item should collapse/expand

6. **Test persistence**:
   - Force quit the app (swipe up in simulator)
   - Relaunch the app
   - All data should be preserved

### Cloud Export Test

1. **Export data**:
   - Tap the Share button (top-left)
   - In simulator, you can save to Files
   - On device, you can use AirDrop or iCloud Drive

2. **Verify JSON**:
   - Navigate to Files app
   - Find `jaflist_data.json`
   - Verify it contains your data in JSON format

## File Locations

When running in simulator, files are stored at:
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/jaflist_data.json
```

You can find the exact path by:
1. Running the app
2. Using Xcode > Window > Devices and Simulators
3. Select your simulator
4. Find JAFList app
5. Click the gear icon > Show Container

## Development Tips

### Enabling SwiftUI Previews

Some views have `#Preview` blocks. To use them:

1. Open a View file (e.g., `ContentView.swift`)
2. Press `Opt + Cmd + Return` to show Canvas
3. Click "Resume" if preview is paused
4. Preview shows live UI without running full app

### Debugging

1. **Add Breakpoints**:
   - Click on line numbers in Xcode to add breakpoints
   - Useful in AppViewModel methods

2. **Print Debugging**:
   - Use `print()` statements
   - Output appears in Xcode console

3. **View Hierarchy**:
   - Run the app
   - In Xcode: Debug > View Debugging > Capture View Hierarchy

### Modifying the Code

1. **Change Bundle Identifier**:
   - Open `JAFList.xcodeproj`
   - Select JAFList target
   - Change Bundle Identifier in General tab

2. **Adjust Auto-Save Timing**:
   - Open `DataStore.swift`
   - Change `saveDebounceInterval` value (line 13)

3. **Customize UI Colors**:
   - Icons, colors are in View files
   - Modify in `TodoItemRow.swift`, `ContentView.swift`, etc.

## Known Issues

1. **Xcode 16 Beta**: May have compatibility issues
   - Use Xcode 15 or earlier for stable builds

2. **iOS 17+ Only Features**:
   - Code is compatible with iOS 16.0+
   - No iOS 17-specific features used

3. **Large Nesting Depth**:
   - Very deep nesting (20+ levels) may affect performance
   - Recommended: Keep nesting under 10 levels

## Next Steps

After successful build:

1. Explore the codebase:
   - Start with `JAFListApp.swift` (entry point)
   - Review `AppViewModel.swift` (business logic)
   - Examine `TodoItemRow.swift` (recursive UI)

2. Customize for your needs:
   - Add new features
   - Modify UI styling
   - Implement import functionality

3. Deploy to device:
   - Connect iPhone/iPad
   - Select device in Xcode
   - Press Cmd + R to build and install

## Additional Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [Swift Language Guide](https://docs.swift.org/swift-book/)

## Support

If you encounter issues:

1. Check the README.md for app usage instructions
2. Review IMPLEMENTATION_SUMMARY.md for architecture details
3. Verify all files are present and in correct locations
4. Clean and rebuild the project
5. Try a different simulator or Xcode version

## Success Criteria

You'll know the build is successful when:

- ✓ Xcode shows "Build Succeeded"
- ✓ Simulator launches without crashes
- ✓ You can see the folder list view
- ✓ You can create folders and items
- ✓ Checkboxes work and toggle completion
- ✓ Data persists after app restart
- ✓ Share button exports JSON file

Happy coding!
