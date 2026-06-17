# Android — android/app/src/main/AndroidManifest.xml additions
# Add inside <manifest>:

# Internet permission (required)
# <uses-permission android:name="android.permission.INTERNET"/>

# Portrait only (add to <activity>):
# android:screenOrientation="portrait"

# ─────────────────────────────────────────────────────────────
# android/app/build.gradle — minSdk must be 21+
# defaultConfig {
#   minSdkVersion 21
#   targetSdkVersion 34
# }

# ─────────────────────────────────────────────────────────────
# iOS — ios/Runner/Info.plist additions:

# Network permissions:
# <key>NSAppTransportSecurity</key>
# <dict>
#   <key>NSAllowsArbitraryLoads</key>
#   <true/>
# </dict>

# Portrait lock:
# <key>UISupportedInterfaceOrientations</key>
# <array>
#   <string>UIInterfaceOrientationPortrait</string>
# </array>
