# Builds three harmless launcher apps for emulator integration checks.
# All generated files are confined to build/multi-fixtures; no user data is removed.
$ErrorActionPreference = 'Stop'
$taskSdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$taskTools = Join-Path $taskSdk 'build-tools\36.0.0'
$taskPlatform = Join-Path $taskSdk 'platforms\android-36\android.jar'
$taskJdk = Join-Path (Get-Location) 'build\jdk21\jdk-21.0.12.1+1'
$env:JAVA_HOME = $taskJdk
$taskRoot = Join-Path (Get-Location) 'build\multi-fixtures'
New-Item -ItemType Directory -Force $taskRoot | Out-Null
foreach ($taskName in @('alpha','beta','gamma')) {
    $taskPackage = "com.daylock.fixture.$taskName"
    $taskDir = Join-Path $taskRoot $taskName
    $taskClasses = Join-Path $taskDir 'classes'
    $taskDex = Join-Path $taskDir 'dex'
    New-Item -ItemType Directory -Force $taskDir,$taskClasses,$taskDex | Out-Null
    $taskLabel = "Daylock Fixture $($taskName.Substring(0,1).ToUpper())$($taskName.Substring(1))"
    @"
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="$taskPackage">
 <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="28" />
 <application android:label="$taskLabel" android:icon="@android:drawable/ic_menu_view" android:theme="@android:style/Theme.Material.NoActionBar">
  <activity android:name=".MainActivity" android:exported="true"><intent-filter>
   <action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" />
  </intent-filter></activity>
 </application>
</manifest>
"@ | Set-Content -Encoding ascii (Join-Path $taskDir 'AndroidManifest.xml')
    @"
package $taskPackage;
public class MainActivity extends android.app.Activity {
 @Override public void onCreate(android.os.Bundle state) {
  super.onCreate(state);
  android.widget.TextView text = new android.widget.TextView(this);
  text.setText("$taskLabel"); text.setTextSize(24); setContentView(text);
 }
}
"@ | Set-Content -Encoding ascii (Join-Path $taskDir 'MainActivity.java')
    & (Join-Path $taskJdk 'bin\javac.exe') -encoding UTF-8 -classpath $taskPlatform -d $taskClasses (Join-Path $taskDir 'MainActivity.java')
    if ($LASTEXITCODE -ne 0) { throw 'Fixture compilation failed' }
    & (Join-Path $taskTools 'd8.bat') --lib $taskPlatform --output $taskDex (Join-Path $taskClasses ($taskPackage.Replace('.','\') + '\MainActivity.class'))
    if ($LASTEXITCODE -ne 0) { throw 'Fixture dex failed' }
    $taskUnsigned = Join-Path $taskDir 'unsigned.apk'
    $taskAligned = Join-Path $taskDir 'aligned.apk'
    $taskSigned = Join-Path $taskDir 'fixture.apk'
    & (Join-Path $taskTools 'aapt.exe') package -f -M (Join-Path $taskDir 'AndroidManifest.xml') -I $taskPlatform -F $taskUnsigned
    if ($LASTEXITCODE -ne 0) { throw 'Fixture packaging failed' }
    & (Join-Path $taskJdk 'bin\jar.exe') uf $taskUnsigned -C $taskDex 'classes.dex'
    & (Join-Path $taskTools 'zipalign.exe') -f 4 $taskUnsigned $taskAligned
    & (Join-Path $taskTools 'apksigner.bat') sign --ks (Join-Path $env:USERPROFILE '.android\debug.keystore') --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out $taskSigned $taskAligned
    if ($LASTEXITCODE -ne 0) { throw 'Fixture signing failed' }
    & (Join-Path $taskSdk 'platform-tools\adb.exe') -s emulator-5554 install -r $taskSigned
    if ($LASTEXITCODE -ne 0) { throw 'Fixture install failed' }
}
