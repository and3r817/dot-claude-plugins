# apkanalyzer Reference

**Official Documentation:** https://developer.android.com/tools/apkanalyzer

apkanalyzer is included in the Android SDK Command-Line Tools package and provides insights into APK composition and
comparison.

**Location:** `android_sdk/cmdline-tools/version/bin/apkanalyzer`

## Syntax

```bash
apkanalyzer [global-options] subject verb [options] apk-file [apk-file2]
```

- **subject**: What to query (apk, dex, manifest, files, resources)
- **verb**: What to know about the subject
- **apk-file**: Path to APK or AAR file

## Global Options

```bash
-h, --human-readable             # Output in human-readable format
```

**Note:** Options can be shortened as long as unambiguous (e.g., `-h` for `--human-readable`)

## APK Subject

Analyze overall APK file attributes.

```bash
# Application metadata
apkanalyzer apk summary app.apk                    # App ID, version code, version name

# Size analysis
apkanalyzer apk file-size app.apk                  # Total APK file size
apkanalyzer apk download-size app.apk              # Estimated download size

# Features
apkanalyzer apk features app.apk                   # Features triggering Play Store filtering
apkanalyzer apk features --not-required app.apk    # Optional features only

# Compare two APKs
apkanalyzer apk compare old.apk new.apk            # Size comparison
apkanalyzer apk compare --different-only old.apk new.apk  # Differences only
apkanalyzer apk compare --files-only old.apk new.apk      # Exclude directories
apkanalyzer apk compare --patch-size old.apk new.apk      # File-by-file patch estimates
```

## Files Subject

Inspect APK file system structure.

```bash
# List all files
apkanalyzer files list app.apk

# View file contents
apkanalyzer files cat --file path/to/file app.apk
```

## Manifest Subject

Examine AndroidManifest.xml data.

```bash
# Full manifest
apkanalyzer manifest print app.apk                 # XML format output

# App metadata
apkanalyzer manifest application-id app.apk        # Application ID (package name)
apkanalyzer manifest version-name app.apk          # Version name (e.g., "1.2.3")
apkanalyzer manifest version-code app.apk          # Version code (integer)

# SDK versions
apkanalyzer manifest min-sdk app.apk               # Minimum SDK version
apkanalyzer manifest target-sdk app.apk            # Target SDK version

# Security & permissions
apkanalyzer manifest permissions app.apk           # List of permissions
apkanalyzer manifest debuggable app.apk            # Debuggability status (true/false)
```

## DEX Subject

Analyze Dalvik Executable files.

```bash
# DEX file list
apkanalyzer dex list app.apk                       # List all DEX files

# Method counts
apkanalyzer dex references app.apk                 # Total method reference count
apkanalyzer dex references --files classes.dex app.apk  # Specific DEX file

# Package tree with class/method/field counts
apkanalyzer dex packages app.apk

# Bytecode inspection
apkanalyzer dex code --class com.example.ClassName app.apk              # Class bytecode (smali)
apkanalyzer dex code --class com.example.ClassName --method methodName app.apk  # Method bytecode
```

### DEX Packages Output Format

```
P/C/M/F d/r  package/class/method/field-name
```

**Status indicators:**

- `P` - Package
- `C` - Class
- `M` - Method
- `F` - Field

**Definition status:**

- `x` - Removed
- `k` - Kept
- `r` - Referenced
- `d` - Defined

## Resources Subject

Inspect app resources.

```bash
# Resource packages
apkanalyzer resources packages app.apk             # Defined packages

# Resource configurations
apkanalyzer resources configs app.apk              # Configuration lists

# Resource values
apkanalyzer resources value app.apk                # Specific resource values

# Resource names
apkanalyzer resources names app.apk                # Resource name listings

# Decode binary XML
apkanalyzer resources xml app.apk                  # Human-readable binary XML
```

## Common Usage Patterns

### Quick APK Summary

```bash
# Get basic info
apkanalyzer apk summary app.apk

# Example output:
# com.example.app
# 1.2.3
# 123
```

### Size Analysis

```bash
# File size
apkanalyzer apk file-size app.apk
# Output: 15728640 (bytes)

# Human-readable
apkanalyzer -h apk file-size app.apk
# Output: 15.0 MB

# Download size estimate
apkanalyzer apk download-size app.apk
# Output: 12582912 (compressed size)
```

### Package & Method Count Analysis

```bash
# See all packages with method counts
apkanalyzer dex packages app.apk

# Example output:
# P d 100 <TOTAL>
# P d 50  com.example.app
# C d 10  com.example.app.MainActivity
# M d 5   onCreate
# ...

# Total method count
apkanalyzer dex references app.apk
# Output: 45678
```

### Manifest Inspection

```bash
# App package name
apkanalyzer manifest application-id app.apk
# Output: com.example.app

# Version info
apkanalyzer manifest version-name app.apk
# Output: 1.2.3

apkanalyzer manifest version-code app.apk
# Output: 123

# SDK versions
apkanalyzer manifest min-sdk app.apk
# Output: 21

apkanalyzer manifest target-sdk app.apk
# Output: 33

# Permissions
apkanalyzer manifest permissions app.apk
# Output:
# android.permission.INTERNET
# android.permission.ACCESS_NETWORK_STATE
# ...

# Check if debuggable
apkanalyzer manifest debuggable app.apk
# Output: false
```

### Compare Two APKs

```bash
# Full comparison
apkanalyzer apk compare old.apk new.apk

# Show only differences
apkanalyzer apk compare --different-only old.apk new.apk

# Example output:
# old  new   file
# 100  150   classes.dex
# 500  500   res/layout/activity_main.xml
# -    50    lib/arm64-v8a/libnew.so

# Patch size estimate
apkanalyzer apk compare --patch-size old.apk new.apk
```

### Bytecode Inspection

```bash
# View class bytecode (smali format)
apkanalyzer dex code --class com.example.app.MainActivity app.apk

# View specific method
apkanalyzer dex code \
  --class com.example.app.MainActivity \
  --method onCreate \
  app.apk
```

### File Extraction

```bash
# List all files
apkanalyzer files list app.apk

# View specific file content
apkanalyzer files cat --file AndroidManifest.xml app.apk
apkanalyzer files cat --file resources.arsc app.apk
apkanalyzer files cat --file classes.dex app.apk
```

## Working with AAR Libraries

apkanalyzer works with AAR files too:

```bash
# AAR size
apkanalyzer apk file-size library.aar

# Method count in AAR
apkanalyzer dex references library.aar

# Package breakdown
apkanalyzer dex packages library.aar

# List AAR contents
apkanalyzer files list library.aar
```

## Integration with Scripts

### Bash Script Examples

**Check if APK is debuggable:**

```bash
#!/bin/bash
if [ "$(apkanalyzer manifest debuggable app.apk)" = "true" ]; then
    echo "WARNING: APK is debuggable!"
    exit 1
fi
```

**Monitor method count:**

```bash
#!/bin/bash
METHOD_COUNT=$(apkanalyzer dex references app.apk)
MAX_METHODS=65536

if [ "$METHOD_COUNT" -gt "$MAX_METHODS" ]; then
    echo "ERROR: Method count $METHOD_COUNT exceeds limit!"
    exit 1
fi
```

**Extract version info:**

```bash
#!/bin/bash
APP_ID=$(apkanalyzer manifest application-id app.apk)
VERSION_NAME=$(apkanalyzer manifest version-name app.apk)
VERSION_CODE=$(apkanalyzer manifest version-code app.apk)

echo "$APP_ID v$VERSION_NAME ($VERSION_CODE)"
```

**Size regression check:**

```bash
#!/bin/bash
OLD_SIZE=$(apkanalyzer apk file-size old.apk)
NEW_SIZE=$(apkanalyzer apk file-size new.apk)
INCREASE=$((NEW_SIZE - OLD_SIZE))

if [ "$INCREASE" -gt 1048576 ]; then  # 1MB
    echo "WARNING: APK size increased by $(($INCREASE / 1048576)) MB"
fi
```

## Output Parsing

### JSON Output (Not Supported)

apkanalyzer outputs plain text, not JSON. Parse with standard tools:

```bash
# Extract version code
VERSION=$(apkanalyzer manifest version-code app.apk)

# Extract min SDK
MIN_SDK=$(apkanalyzer manifest min-sdk app.apk)

# Count DEX files
DEX_COUNT=$(apkanalyzer dex list app.apk | wc -l)

# Get app package
PACKAGE=$(apkanalyzer manifest application-id app.apk)
```

### Processing Package Tree

```bash
# Find packages with most methods
apkanalyzer dex packages app.apk | grep "^P" | sort -k3 -rn | head -10

# Count classes
apkanalyzer dex packages app.apk | grep "^C" | wc -l

# Find defined methods
apkanalyzer dex packages app.apk | grep "^M d"
```

## Performance Characteristics

- **Very fast**: No decompilation needed
- **Low memory**: Metadata analysis only
- **Accurate**: Direct APK file inspection
- **Lightweight**: Part of Android SDK

**Timing examples:**

```bash
# APK summary: <1 second
time apkanalyzer apk summary app.apk

# Method count: 1-5 seconds
time apkanalyzer dex references large-app.apk

# Package tree: 2-10 seconds (depends on APK size)
time apkanalyzer dex packages app.apk
```

## Limitations

- **No code decompilation**: Shows metadata only, not Java source
- **No resource decoding**: Binary resources not decoded (use apktool)
- **Limited bytecode view**: Smali format only
- **Plain text output**: No JSON/XML structured output

**For these needs, use:**

- JADX - Java decompilation
- apktool - Resource decoding and smali disassembly

## Troubleshooting

### Command Not Found

```bash
# Check if installed
which apkanalyzer

# If not found, add to PATH
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

# Or use full path
$ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer --version
```

### Invalid APK Error

```bash
# Verify APK is valid
file app.apk
# Should output: app.apk: Zip archive data

# Check if corrupted
unzip -t app.apk
```

### Slow Performance

```bash
# apkanalyzer is generally fast
# If slow, check:
# - APK size (>100MB can take longer)
# - Disk I/O (slow drive)
# - Multi-dex apps (more DEX files = longer analysis)
```

## Installation

apkanalyzer is included with Android SDK Command-Line Tools.

```bash
# Check installation
which apkanalyzer

# Add to PATH (if needed)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# Verify
apkanalyzer --version
```

**Install Android SDK:**

- Download from: https://developer.android.com/studio
- Or use `sdkmanager` to install cmdline-tools

## See Also

- [Official Android Documentation](https://developer.android.com/tools/apkanalyzer)
- [APK Analyzer (GUI)](https://developer.android.com/studio/debug/apk-analyzer) - Android Studio version
- `jadx-reference.md` - For Java decompilation
- `apktool-reference.md` - For smali disassembly and resource decoding
