# Google Play build preparation

The Play application ID is `com.sofien.daylock`. Android treats the earlier GitHub APK (`com.example.daylock`) as a different app, so installing this build will not update it or automatically transfer its local data. The existing Microsoft OAuth redirect scheme is intentionally unchanged; validate all calendar sign-in configuration against the Play package and Play signing certificate before release.

## Upload key

Use Google Play App Signing: the upload key signs bundles you submit, while Google manages the app-signing key used for distributed APKs. Check Play Console's App integrity page first: if an upload key has already been registered, use its existing keystore rather than creating a different one. Back up the keystore and passwords securely outside the repository. Never commit or send them in chat.

If there is no registered upload key, run this in PowerShell from the project root. It refuses to overwrite the chosen path and prompts for credentials interactively; choose your own passwords and save them securely.

```powershell
$uploadKeyPath = Join-Path $env:USERPROFILE 'daylock-upload.jks'
if (Test-Path -LiteralPath $uploadKeyPath) { throw "A keystore already exists at $uploadKeyPath. Stop and use the existing key." }
& 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' -genkeypair -v -keystore $uploadKeyPath -alias daylock-upload -keyalg RSA -keysize 4096 -validity 10000
```

The key will be at `C:\Users\Sofien\daylock-upload.jks`. Then create `android/key.properties` locally with Notepad and fill in your chosen passwords. In a Java properties file, escape backslashes or use forward slashes:

```properties
storeFile=C:/Users/Sofien/daylock-upload.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=daylock-upload
keyPassword=YOUR_KEY_PASSWORD
```

Both the properties file and `.jks` files are ignored by Git. Protect access to this file and do not commit it. Then run:

```powershell
flutter build appbundle --release
```

The bundle should be `build/app/outputs/bundle/release/app-release.aab`. This command has not been run with a real upload key until credentials are supplied. Confirm Play App Signing enrollment in Play Console; a Gradle upload-key configuration does not enroll the app on its own.

## Before submission

Test the Play-identity build on a physical device, including accessibility, restriction and notification flows. Review the AccessibilityService declaration and Play's prominent disclosure and affirmative consent requirements, and prepare the requested declaration and demonstration video; Google must review the app. Complete the privacy policy, Data safety and other Play Console declarations using the actual release behavior. Review the merged manifest and calendar OAuth clients, and verify Play's current account testing and release requirements. No upload or publication is performed by these instructions.
