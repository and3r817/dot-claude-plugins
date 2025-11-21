---
description: Reverse engineer Android APK (decompile, inspect resources, verify signature)
allowed-tools:
  - Bash(jadx:*)
  - Bash(apktool:*)
  - Bash(aapt:*)
  - Bash(apksigner:*)
  - Bash(unzip:*)
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

# Android Reverse Engineering

## Usage

```
/android-reverse [apk-file] [--decompile|--disassemble|--inspect|--all]
```

**Arguments:**

- `apk-file` - Path to APK file. If not provided, searches current directory.
- `--decompile` - Decompile to Java code only (JADX)
- `--disassemble` - Disassemble to smali + resources (apktool)
- `--inspect` - Quick inspection (manifest, signature, resources)
- `--all` - Comprehensive reverse engineering (default)

## Implementation

### 1. Locate APK File

If not provided:

- Search current directory for `.apk` files
- Check common build directories: `app/build/outputs/apk/`
- Ask user to provide path

### 2. Verify Tools Available

Check required tools:

```bash
which jadx
which apktool
which aapt
which apksigner
```

If missing, provide installation instructions based on OS.

### 3. Quick Inspection (Always Run First)

#### Signature Verification

```bash
apksigner verify --verbose --print-certs <apk-file>
```

**Extract:**

- Signer certificate info
- Signature algorithm
- Valid/invalid status

#### Manifest Analysis

```bash
aapt dump badging <apk-file>
aapt dump permissions <apk-file>
aapt dump xmltree <apk-file> AndroidManifest.xml
```

**Extract:**

- Package name
- Version code/name
- Min/Target SDK
- Permissions
- Exported components
- Activities, services, receivers

#### Basic APK Info

```bash
aapt dump resources <apk-file>
unzip -l <apk-file> | head -20
```

**Identify:**

- APK structure
- Resource files
- Native libraries (.so files)
- Asset files

### 4. Decompilation (if requested or --all)

#### JADX Decompilation

```bash
# Decompile with deobfuscation
jadx --deobf -d output-jadx/ <apk-file>
```

**Options:**

- `--no-res` - Skip resources (faster)
- `--deobf` - Attempt deobfuscation
- `-j 8` - Use 8 threads

**Analyze:**

- Package structure
- Class hierarchy
- Method implementations
- String resources
- Obfuscation level

### 5. Disassembly (if requested or --all)

#### Apktool Disassembly

```bash
apktool d <apk-file> -o output-apktool/
```

**Outputs:**

- Smali bytecode
- XML resources (decoded)
- AndroidManifest.xml (readable)
- Assets

**Use Cases:**

- Modify and rebuild APK
- Inspect resources in detail
- Analyze obfuscated code

### 6. Code Analysis

**Search for Interesting Patterns:**

```bash
# API endpoints
grep -r "http://" output-jadx/
grep -r "https://" output-jadx/

# Hardcoded secrets
grep -r "api_key\|apiKey\|API_KEY" output-jadx/
grep -r "password\|secret\|token" output-jadx/

# Crypto usage
grep -r "Cipher\|MessageDigest\|SecretKey" output-jadx/

# Network libraries
grep -r "Retrofit\|OkHttp\|HttpClient" output-jadx/

# Database
grep -r "SQLiteDatabase\|Room\|Realm" output-jadx/
```

### 7. Resource Extraction

**Extract specific resources:**

```bash
# Extract all
unzip <apk-file> -d extracted/

# Images
unzip <apk-file> "res/drawable*/*" -d extracted/

# Layouts
unzip <apk-file> "res/layout*/*" -d extracted/

# Native libraries
unzip <apk-file> "lib/*" -d extracted/
```

### 8. Analysis Report

Format output as:

```
🔍 Reverse Engineering Report: app-release.apk
──────────────────────────────────────────────

📋 APK Information:
  • Package: com.example.app
  • Version: 2.1.0 (210)
  • Min SDK: 21 (Android 5.0)
  • Target SDK: 33 (Android 13)
  • Size: 45.2 MB

🔐 Signature Information:
  • Signer: CN=Example Inc, O=Example, C=US
  • Valid from: 2020-01-15
  • Valid until: 2045-01-09
  • Algorithm: RSA with SHA-256
  • Status: ✓ Valid

📱 Permissions (12 declared):
  Critical:
  • android.permission.INTERNET
  • android.permission.ACCESS_FINE_LOCATION
  • android.permission.CAMERA

  Standard:
  • android.permission.ACCESS_NETWORK_STATE
  • android.permission.WRITE_EXTERNAL_STORAGE
  [...]

🎯 Components:
  Activities: 23 (5 exported)
  Services: 8 (2 exported)
  Receivers: 6 (3 exported)
  Providers: 1 (0 exported)

⚠️  Exported Components (Potential Attack Surface):
  1. MainActivity (LAUNCHER)
  2. DeepLinkActivity (VIEW intent-filter)
  3. NotificationService
  4. BootReceiver
  5. ShareReceiver

💻 Decompilation Results:
  • Output: output-jadx/
  • Total classes: 3,421
  • Packages: 142
  • Obfuscation: Heavy (ProGuard/R8)

  Top-level packages:
  • com.example.app (application code)
  • androidx.* (Android libraries)
  • com.google.android.gms (Google Play Services)
  • okhttp3.* (Networking)
  • retrofit2.* (API client)

📦 Disassembly Results:
  • Output: output-apktool/
  • Smali files: 8,234
  • Resources decoded: ✓
  • Can be rebuilt: ✓

🔍 Code Analysis Findings:

API Endpoints Discovered:
  • https://api.example.com/v1/
  • https://analytics.example.com/events
  • https://cdn.example.com/assets/

Potential Issues Found:
  ⚠️  Hardcoded API key in BuildConfig.java
  ⚠️  Root detection implemented
  ✓ SSL pinning implemented
  ⚠️  Debug logs present (Log.d calls)

Libraries Used:
  • Networking: Retrofit 2.9.0 + OkHttp 4.9.3
  • Database: Room 2.5.0
  • DI: Dagger 2.44
  • Image Loading: Glide 4.14.2
  • Analytics: Firebase Analytics

Native Libraries:
  • lib/arm64-v8a/libnative-lib.so (2.3 MB)
  • lib/armeabi-v7a/libnative-lib.so (1.8 MB)

📚 Next Steps:

For Modification:
  1. Modify smali code in output-apktool/
  2. Rebuild: apktool b output-apktool/ -o modified.apk
  3. Sign with debug key
  4. Install and test

For Deep Analysis:
  1. Review decompiled code in output-jadx/
  2. Trace critical flows (auth, payment, data sync)
  3. Document business logic
  4. Check for backdoors or malicious code

For Dynamic Analysis:
  1. Use Frida to hook methods: /android-dynamic
  2. Monitor network traffic with mitmproxy
  3. Test with different inputs
```

### 9. Provide Warnings and Legal Notes

**Display warning:**

```
⚠️  IMPORTANT LEGAL NOTICE:

Reverse engineering may be subject to legal restrictions:
• Only reverse engineer apps you own or have permission to analyze
• Respect software licenses and terms of service
• Educational and research use only
• Do not redistribute modified APKs
• Comply with local laws (DMCA, CFAA, etc.)

This tool is for:
✓ Research on your own apps
✓ Educational purposes
✓ Malware analysis
✓ Compatibility research

NOT for:
✗ Piracy or license circumvention
✗ Stealing intellectual property
✗ Creating modified/cracked versions
```

### 10. Offer Next Steps

**Based on analysis goals:**

**Modification:**

- Provide instructions for rebuilding
- Sign with debug certificate
- Install on test device

**Documentation:**

- Generate class diagram
- Document API endpoints
- Map user flows

## Examples

**Quick inspection:**

```
/android-reverse app.apk --inspect
```

**Full reverse engineering:**

```
/android-reverse app-release.apk --all
```

**Decompile only:**

```
/android-reverse app.apk --decompile
```

## Error Handling

**APK signature invalid:**

- Report to user
- May indicate tampering
- Proceed with caution

**Decompilation fails:**

- Try alternative: `dex2jar + jd-cli`
- Check APK not corrupted
- Try older JADX version

**Heavy obfuscation:**

- Deobfuscation may be incomplete
- Smali inspection required
- Use ProGuard mapping file if available

**APK too large:**

- May take significant time
- Use `--no-res` to skip resources
- Decompile specific packages only

## Advanced Usage

**Decompile specific package:**

```bash
jadx --deobf -d output/ --package-only com.example.app <apk-file>
```

**Export as Gradle project:**

```bash
jadx --export-gradle -d project/ <apk-file>
```

**Compare two APKs:**
Decompile both and diff:

```bash
diff -r output-v1/ output-v2/ > changes.diff
```

**Extract ProGuard mapping:**
If available in APK metadata

**Analyze native libraries:**

```bash
# Disassemble .so files
objdump -d lib/arm64-v8a/libnative.so
# Or use IDA Pro, Ghidra for deeper analysis
```
