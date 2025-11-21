# Android Reverse Engineering Tools Installation

Installation guide for tools used by the android-analysis skill (agent reference).

## Required Tools

### JADX (DEX to Java Decompiler)

**Primary decompiler - always needed**

**Install via Homebrew (recommended)**:

```bash
brew install jadx
```

**Manual installation**:

```bash
wget https://github.com/skylot/jadx/releases/latest/download/jadx-1.4.7.zip
unzip jadx-1.4.7.zip -d ~/bin/jadx
export PATH="$PATH:$HOME/bin/jadx/bin"
```

**Verify**:

```bash
jadx --version
```

### Apktool (APK Disassembler)

**For smali and resource extraction**

**Install via Homebrew (recommended)**:

```bash
brew install apktool
```

**Manual installation**:

```bash
# macOS/Linux
wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/osx/apktool
wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.2.jar
mv apktool_2.9.2.jar apktool.jar
chmod +x apktool
sudo mv apktool apktool.jar /usr/local/bin/
```

**Verify**:

```bash
apktool --version
```

## Recommended Tools

### CFR (Java JAR Decompiler)

**Best decompiler for JAR files and AAR libraries**

**Download latest release**:

```bash
# Download CFR
wget https://www.benf.org/other/cfr/cfr-0.152.jar -O ~/bin/cfr.jar

# Or from GitHub
wget https://github.com/leibnitz27/cfr/releases/latest/download/cfr-0.152.jar -O ~/bin/cfr.jar
```

**Verify**:

```bash
java -jar ~/bin/cfr.jar --version
```

**Usage**:

```bash
# Decompile JAR
java -jar ~/bin/cfr.jar library.jar --outputdir src/

# Decompile classes.jar from AAR
unzip library.aar classes.jar
java -jar ~/bin/cfr.jar classes.jar --outputdir src/
```

**Requirements**: Java 8 or newer

---

### Vineflower (Modern Java Decompiler)

**Best for Java 17-21 projects with modern features**

**Download latest release**:

```bash
# Download Vineflower
wget https://github.com/Vineflower/vineflower/releases/latest/download/vineflower-1.10.1.jar -O ~/bin/vineflower.jar
```

**Verify**:

```bash
java -jar ~/bin/vineflower.jar --version
```

**Usage**:

```bash
# Decompile modern Java JAR
java -jar ~/bin/vineflower.jar library.jar src/
```

**Requirements**: Java 17 or newer (for Vineflower 1.11+)

**IntelliJ IDEA Plugin**:

1. Settings → Plugins
2. Search "Vineflower"
3. Install and restart IDE

---

### apkanalyzer (Android SDK)

**For APK structure inspection**

Usually already installed with Android SDK.

**Add to PATH**:

```bash
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
```

**Verify**:

```bash
which apkanalyzer
apkanalyzer --version
```

**If not installed**:

- Install Android SDK Command-line Tools
- Or use Android Studio to install SDK tools

---

### tree (Directory Visualization)

**Optional - for viewing decompiled structure**

**Install**:

```bash
# macOS
brew install tree

# Ubuntu/Debian
sudo apt install tree

# CentOS/RHEL
sudo yum install tree
```

**Verify**:

```bash
tree --version
```

## Built-in Tools (No Installation Needed)

### unzip

Extract AAR/JAR archives

**Verify**:

```bash
which unzip
```

### jar

List/extract JAR contents

**Verify**:

```bash
which jar
```

## Quick Installation Script

**macOS (Homebrew + Manual)**:

```bash
#!/bin/bash

# Install core tools via Homebrew
brew install jadx apktool tree

# Download Java decompilers
mkdir -p ~/bin
wget https://www.benf.org/other/cfr/cfr-0.152.jar -O ~/bin/cfr.jar
wget https://github.com/Vineflower/vineflower/releases/latest/download/vineflower-1.10.1.jar -O ~/bin/vineflower.jar

# Verify
echo "Verifying installations..."
jadx --version
apktool --version
tree --version
java -jar ~/bin/cfr.jar --version
java -jar ~/bin/vineflower.jar --version

# Check Android SDK tool
if command -v apkanalyzer &> /dev/null; then
    echo "✓ apkanalyzer found"
else
    echo "⚠ apkanalyzer not found - install Android SDK"
fi

echo "✓ Installation complete"
```

## Platform-Specific Notes

### macOS

- Use Homebrew for easiest installation
- Android SDK usually at `~/Library/Android/sdk`

### Linux

- Use apt/yum for system tools
- Install JADX from GitHub releases
- Android SDK location varies

### Windows

- Use WSL for best compatibility
- Or use Scoop/Chocolatey package managers
- Android SDK usually at `C:\Users\<user>\AppData\Local\Android\Sdk`

## Verification Checklist

After installation, verify all tools work:

```bash
# Core tools (Android-specific)
jadx --version          # Should show version 1.4.7+
apktool --version       # Should show version 2.9.0+

# Java decompilers (JAR analysis)
java -jar ~/bin/cfr.jar --version        # CFR 0.152+
java -jar ~/bin/vineflower.jar --version # Vineflower 1.10.1+

# Optional tools
apkanalyzer --version   # Android SDK version
tree --version          # Directory tree visualizer

# Built-in
which unzip             # Should return path
which jar               # Should return path
java --version          # Java 8+ required for CFR, Java 17+ for Vineflower
```

## Troubleshooting

### JADX not found

```bash
# macOS: Reinstall with Homebrew
brew reinstall jadx

# Check PATH
echo $PATH | grep jadx
```

### apktool not found

```bash
# macOS: Reinstall with Homebrew
brew reinstall apktool

# Manual: Check /usr/local/bin
ls -la /usr/local/bin/apktool
```

### apkanalyzer not found

```bash
# Check Android SDK installed
echo $ANDROID_HOME

# Add to PATH in ~/.zshrc or ~/.bashrc
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### Permission denied (macOS)

```bash
# Grant execute permission
chmod +x /usr/local/bin/jadx
chmod +x /usr/local/bin/apktool
```

### CFR not working

```bash
# Check Java version (need Java 8+)
java --version

# Verify CFR file exists
ls -la ~/bin/cfr.jar

# Test CFR
java -jar ~/bin/cfr.jar --version

# Re-download if corrupted
rm ~/bin/cfr.jar
wget https://www.benf.org/other/cfr/cfr-0.152.jar -O ~/bin/cfr.jar
```

### Vineflower not working

```bash
# Check Java version (need Java 17+ for v1.11+)
java --version

# If Java version too old, install Java 17
brew install openjdk@17

# Verify Vineflower file exists
ls -la ~/bin/vineflower.jar

# Test Vineflower
java -jar ~/bin/vineflower.jar --version

# Use older version for Java 11
wget https://github.com/Vineflower/vineflower/releases/download/1.9.3/vineflower-1.9.3.jar -O ~/bin/vineflower.jar
```

## Minimum Versions

- **JADX**: 1.4.0+
- **apktool**: 2.9.0+
- **apkanalyzer**: Any (part of Android SDK build-tools)
- **CFR**: 0.150+
- **Vineflower**: 1.9.0+ (Java 11), 1.11.0+ (Java 17)

Older versions may work but are untested.

## Tool Locations

After installation, tools should be in PATH:

```bash
# Show tool locations
which jadx       # /usr/local/bin/jadx or /opt/homebrew/bin/jadx
which apktool    # /usr/local/bin/apktool
which apkanalyzer # $ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer

# Java decompilers (manually placed)
ls ~/bin/cfr.jar       # ~/bin/cfr.jar
ls ~/bin/vineflower.jar # ~/bin/vineflower.jar
```

## Updates

### Update JADX

```bash
brew upgrade jadx
```

### Update apktool

```bash
brew upgrade apktool
```

### Update CFR

```bash
# Download latest version
wget https://www.benf.org/other/cfr/cfr-latest.jar -O ~/bin/cfr.jar

# Verify
java -jar ~/bin/cfr.jar --version
```

### Update Vineflower

```bash
# Download latest version
wget https://github.com/Vineflower/vineflower/releases/latest/download/vineflower-latest.jar -O ~/bin/vineflower.jar

# Verify
java -jar ~/bin/vineflower.jar --version
```

### Update apkanalyzer

Update Android SDK via Android Studio or sdkmanager.
