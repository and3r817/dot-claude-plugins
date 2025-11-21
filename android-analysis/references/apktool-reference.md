# Apktool Reference

**Official Documentation:** https://apktool.org/docs/cli-parameters/
**GitHub Repository:** https://github.com/iBotPeaches/Apktool

Apktool is a tool for reverse engineering Android APK files. It decodes resources to nearly original form and rebuilds
them after modifications.

## Core Capabilities

- Decode resources to nearly original form and rebuild after modifications
- Debug smali code step-by-step
- Project-like file structure with automation for repetitive build tasks
- Perfect for localizing apps, adding features, or supporting custom platforms

## Basic Usage

### Decoding APKs

```bash
# Basic decoding (full extraction)
apktool d app.apk

# Decode to specific directory
apktool d app.apk -o output/

# Decode with force (delete existing output)
apktool d -f app.apk -o output/
```

### Building APKs

```bash
# Build from decoded directory
apktool b output/

# Build to specific output file
apktool b output/ -o rebuilt.apk

# Build with debug flag
apktool b -d output/ -o debug.apk
```

## Decode Options

```bash
-api, --api-level <API>          # Sets API level for generated smali files (defaults to targetSdkVersion)
-b, --no-debug-info              # Prevents debug info (.local, .param, .line entries)
-f, --force                      # Forces deletion of destination directory
--force-manifest                 # Forces AndroidManifest.xml decoding regardless of settings
--keep-broken-res                # Allows decoding when resources fail (prevents data loss)
-l, --lib <pkg:location>         # Specifies dynamic library locations (repeatable)
-m, --match-original             # Matches generated files close to originals
--no-assets                      # Skips decoding unknown asset files
--only-main-classes              # Disassembles only root-level dex classes
-p, --frame-path <DIR>           # Sets framework file storage directory
-r, --no-res                     # Prevents resource decompilation; maintains resources.arsc
-resm, --resource-mode <mode>    # Unresolved resource handling (remove/dummy/keep)
-s, --no-src                     # Prevents dex file disassembly
-t, --frame-tag <TAG>            # Uses framework files with specified tag
-o, --output <path>              # Output directory for decoding
```

## Build Options

```bash
-a, --aapt <FILE>                # Loads custom aapt/aapt2 binaries
-api, --api-level <API>          # Sets API level of smali files to build against
-c, --copy-original              # Duplicates original AndroidManifest.xml and META-INF
-d, --debug                      # Adds debuggable="true" to AndroidManifest.xml
-f, --force-all                  # Overwrites existing files during build
-n, --net-sec-conf               # Includes generic Network Security Configuration
-na, --no-apk                    # Disables APK repacking
-nc, --no-crunch                 # Prevents bitmap optimization by aapt/aapt2
-o, --output <FILE>              # Specifies output APK filename (default: dist/{apkname}.apk)
-p, --frame-path <DIR>           # Sets framework directory
--use-aapt1                      # Uses aapt instead of aapt2
--use-aapt2                      # Uses aapt2 (default in v2.9.0+)
```

## Common Options

```bash
-j <NUM>, --jobs <NUM>           # Configures thread count for parallel operations
-v, --verbose                    # Enables detailed logging output
-q, --quiet                      # Suppresses output messages
-advance, --advanced             # Outputs advanced usage information
-version, --version              # Displays current software version
```

## Common Usage Patterns

### Extract Code Only (Smali)

```bash
# Decode smali without resources (faster)
apktool d --no-res app.apk -o smali-only/

# Decode smali without debug info
apktool d -b --no-res app.apk -o smali-clean/
```

### Extract Resources Only

```bash
# Decode resources without source code
apktool d --no-src app.apk -o resources-only/

# Get AndroidManifest.xml only
apktool d --no-src --no-res app.apk -o manifest-only/
```

### Full Extraction

```bash
# Decode everything
apktool d app.apk -o full-decode/

# With match-original flag (closer to original structure)
apktool d -m app.apk -o full-decode/

# Force overwrite existing directory
apktool d -f app.apk -o full-decode/
```

### Building Modified APKs

```bash
# Build from decoded directory
apktool b decoded/ -o modified.apk

# Build with debug flag (adds android:debuggable="true")
apktool b -d decoded/ -o debug.apk

# Build without resource optimization
apktool b --no-crunch decoded/ -o modified.apk

# Build using aapt1 instead of aapt2
apktool b --use-aapt1 decoded/ -o modified.apk
```

### Handling Resources

```bash
# Keep broken resources (don't fail on resource errors)
apktool d --keep-broken-res app.apk -o output/

# Resource mode: remove unresolved resources
apktool d --resource-mode remove app.apk -o output/

# Resource mode: use dummy for unresolved
apktool d --resource-mode dummy app.apk -o output/
```

## Output Structure

```
output/
├── AndroidManifest.xml         # Decoded manifest (human-readable XML)
├── apktool.yml                 # Apktool configuration
├── original/                   # Original files (if -c used during build)
│   ├── AndroidManifest.xml
│   └── META-INF/
├── smali/                      # Disassembled DEX code (smali format)
│   └── com/example/app/
│       ├── MainActivity.smali
│       └── models/
├── smali_classes2/             # Additional DEX files (if multi-dex)
├── res/                        # Decoded resources
│   ├── layout/
│   ├── values/
│   ├── drawable/
│   └── xml/
├── assets/                     # App assets
├── lib/                        # Native libraries
│   ├── arm64-v8a/
│   ├── armeabi-v7a/
│   ├── x86/
│   └── x86_64/
└── unknown/                    # Unknown files
```

## Advanced Usage

### Framework Files

Some APKs require framework files for proper decoding:

```bash
# Install framework
apktool if framework-res.apk

# Install with custom tag
apktool if framework-res.apk -t samsung

# Use custom framework directory
apktool d -p /path/to/frameworks app.apk

# Decode using tagged framework
apktool d -t samsung app.apk
```

### Multi-Threading

```bash
# Use 8 threads for parallel processing
apktool d -j 8 large-app.apk -o output/

# Build with multiple threads
apktool b -j 8 decoded/ -o rebuilt.apk
```

### Verbose Output

```bash
# Detailed logging
apktool d -v app.apk -o output/

# Quiet mode (suppress output)
apktool d -q app.apk -o output/
```

## Working with Smali

Smali is the human-readable representation of Dalvik bytecode. After decoding:

```smali
# Example smali file: MainActivity.smali
.class public Lcom/example/app/MainActivity;
.super Landroid/app/Activity;

.method public onCreate(Landroid/os/Bundle;)V
    .locals 1
    .param p1, "savedInstanceState"    # Landroid/os/Bundle;

    .line 15
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    .line 16
    const v0, 0x7f0b0020
    invoke-virtual {p0, v0}, Lcom/example/app/MainActivity;->setContentView(I)V

    .line 17
    return-void
.end method
```

## AndroidManifest.xml

Apktool decodes the binary XML to human-readable format:

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    android:compileSdkVersion="33"
    android:compileSdkVersionCodename="13"
    package="com.example.app"
    platformBuildVersionCode="33"
    platformBuildVersionName="13">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:allowBackup="true"
        android:debuggable="false"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme">

        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

## Error Handling

### Common Errors

**"brut.androlib.AndrolibException: Could not decode arsc file"**

```bash
# Try without resources
apktool d --no-res app.apk

# Or keep broken resources
apktool d --keep-broken-res app.apk
```

**"Exception in thread "main" brut.androlib.err.UndefinedResObject"**

```bash
# Use resource mode to handle unresolved resources
apktool d --resource-mode dummy app.apk

# Or remove unresolved resources
apktool d --resource-mode remove app.apk
```

**"Invalid resource directory name"**

```bash
# Install required framework files
apktool if framework-res.apk
apktool d app.apk
```

**"aapt: error: failed processing manifest"**

```bash
# Use aapt1 instead of aapt2
apktool b --use-aapt1 decoded/ -o rebuilt.apk
```

## apktool.yml

The `apktool.yml` file stores metadata about the decoded APK:

```yaml
version: "2.9.2"
apkFileName: app.apk
isFrameworkApk: false
usesFramework:
  ids:
  - 1
sdkInfo:
  minSdkVersion: '21'
  targetSdkVersion: '33'
packageInfo:
  forcedPackageId: '127'
versionInfo:
  versionCode: '123'
  versionName: '1.2.3'
compressionType: false
sharedLibrary: false
```

## Rebuilding & Signing

After modifying, rebuild and sign:

```bash
# 1. Build modified APK
apktool b decoded/ -o modified-unsigned.apk

# 2. Sign with debug key
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/.android/debug.keystore \
  -storepass android \
  modified-unsigned.apk androiddebugkey

# 3. Align
zipalign -v 4 modified-unsigned.apk modified.apk

# Or use apksigner (Android SDK build-tools)
apksigner sign --ks ~/.android/debug.keystore \
  --ks-pass pass:android modified-unsigned.apk
```

## Installation

```bash
# macOS
brew install apktool

# Arch Linux
sudo pacman -S apktool

# Manual installation
# 1. Download wrapper script
wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/osx/apktool

# 2. Download apktool jar
wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.2.jar

# 3. Rename and set permissions
mv apktool_2.9.2.jar apktool.jar
chmod +x apktool
chmod +x apktool.jar

# 4. Move to /usr/local/bin
sudo mv apktool apktool.jar /usr/local/bin/
```

**Requirements:**

- Java 8 or later

## Version Check

```bash
apktool --version

# Update (Homebrew)
brew upgrade apktool
```

## Use Cases

- **App Localization**: Decode, translate strings in res/values/, rebuild
- **Resource Modification**: Change layouts, drawables, colors
- **Smali Debugging**: Inspect and modify bytecode behavior
- **Permission Changes**: Modify AndroidManifest.xml permissions
- **Theme Customization**: Change app themes and styling

## Limitations

- Cannot decompile to Java (use JADX for that)
- Smali is harder to read than decompiled Java
- Some obfuscated apps may fail to decode cleanly
- Rebuilding may fail if resources are heavily customized

## See Also

- [Official Website](https://apktool.org)
- [GitHub Repository](https://github.com/iBotPeaches/Apktool)
- [Documentation](https://apktool.org/docs/the-basics/intro)
- `jadx-reference.md` - For Java decompilation
- `apkanalyzer-reference.md` - For APK structure inspection
