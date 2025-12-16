# JADX Decompiler Reference

**Official Documentation:** https://github.com/skylot/jadx

JADX is a command-line and GUI tool for converting Android DEX/APK files into readable Java source code.

## Supported File Formats

JADX processes: `.apk`, `.dex`, `.jar`, `.class`, `.smali`, `.zip`, `.aar`, `.arsc`, `.aab`, `.xapk`, `.apkm`,
`.jadx.kts`

## Basic Usage

```bash
# Simple decompilation
jadx app.apk

# Decompile to specific directory
jadx -d output/ app.apk

# With deobfuscation (recommended)
jadx --deobf -d output/ app.apk
```

## Essential Options

### Output Control

```bash
-d, --output-dir <DIR>           # Destination directory
-ds, --output-dir-src <DIR>      # Sources output location
-dr, --output-dir-res <DIR>      # Resources output location
-r, --no-res                     # Skip resource decoding (faster)
-s, --no-src                     # Skip source decompilation
```

### Processing Parameters

```bash
-j, --threads-count <NUM>        # Parallel processing threads (default: 16)
-m, --decompilation-mode <MODE>  # auto/restructure/simple/fallback
--output-format <FORMAT>         # Java or JSON output
```

### Deobfuscation

ProGuard/R8 obfuscation renames classes to single letters (a, b, c). JADX's deobfuscator makes code readable.

```bash
--deobf                          # Activate deobfuscation (recommended)
--deobf-min <NUM>                # Minimum name length for renaming (default: 3)
--deobf-max <NUM>                # Maximum name length (default: 64)
--deobf-cfg-file <FILE>          # Custom mappings in JOBF format
--deobf-whitelist <LIST>         # Exclude packages from renaming
--mappings-path <FILE>           # External mapping files (Tiny, Enigma, ProGuard formats)
```

**Always use --deobf:**

```bash
# Without deobfuscation (hard to read)
class a {
    int a(int a) { return a * 2; }
}

# With --deobf (readable)
class UserManager {
    int calculateAge(int birthYear) { return birthYear * 2; }
}
```

### Code Generation Options

```bash
--no-imports                     # Write full package names instead of imports
--no-debug-info                  # Disable debug info parsing
--add-debug-lines                # Include line number comments
--show-bad-code                  # Display incorrectly decompiled sections
--escape-unicode                 # Convert non-ASCII to escape sequences
```

### Advanced Transformations

```bash
--no-inline-anonymous            # Preserve anonymous classes
--no-inline-methods              # Keep method definitions separate
--no-move-inner-classes          # Retain nested class structure
--no-finally                     # Keep finally blocks intact
--rename-flags <FLAGS>           # case, valid, printable, none, all
```

### Gradle Export

```bash
-e, --export-gradle              # Generate Gradle project structure
--export-gradle-type <TYPE>      # auto/android-app/android-library/simple-java
```

### Logging & Performance

```bash
--log-level <LEVEL>              # quiet/progress/error/warn/info/debug
-v, --verbose                    # Debug output
-q, --quiet                      # Suppress output
--type-update-limit <NUM>        # Type inference iterations (default: 10)
--fs-case-sensitive              # Filesystem case handling
```

## Common Usage Patterns

### APK Decompilation

```bash
# Full decompilation with deobfuscation
jadx --deobf -d output/ app.apk

# Code only (skip resources, faster)
jadx --no-res --deobf -d output/ app.apk

# Preserve obfuscated names (no deobfuscation)
jadx --rename-flags "none" -d output/ app.apk

# Multiple renaming filters
jadx --rename-flags "valid, printable" -d output/ app.apk
```

### AAR/JAR Decompilation

```bash
# Direct decompilation
jadx --deobf -d output/ library.aar
jadx --deobf -d output/ library.jar

# Or extract AAR first
unzip library.aar classes.jar
jadx --deobf -d output/ classes.jar
```

### Performance Optimization

```bash
# Large APKs: Skip resources
jadx --no-res --deobf -d output/ large-app.apk

# Multiple threads
jadx -j 8 --deobf -d output/ app.apk

# Increase heap size
JAVA_OPTS="-Xmx4g" jadx --deobf -d output/ huge-app.apk
```

## Output Structure

```
output/
├── sources/                    # Decompiled Java source
│   └── com/example/app/
│       ├── MainActivity.java
│       ├── models/
│       └── utils/
├── resources/                  # Decoded resources
│   ├── AndroidManifest.xml
│   ├── res/
│   │   ├── layout/
│   │   ├── values/
│   │   └── drawable/
│   └── assets/
└── lib/                       # Native libraries
    ├── arm64-v8a/
    ├── armeabi-v7a/
    ├── x86/
    └── x86_64/
```

## Plugin System

JADX supports plugins with configuration:

```bash
# Configure plugin
jadx -Pdex-input.verify-checksum=no app.apk
```

**Available plugins:**

- `dex-input` - DEX/APK loading with checksum verification
- `java-convert` - Converts .class/.jar to DEX (via dx or d8)
- `kotlin-metadata` - Kotlin annotation processing
- `rename-mappings` - Multiple mapping format support (TINY, Enigma, SRG, ProGuard)
- `smali-input` - SMALI file loading (configurable API level)

## Environment Variables

```bash
JADX_DISABLE_XML_SECURITY        # Disable XML validation
JADX_DISABLE_ZIP_SECURITY        # Disable ZIP checks
JADX_ZIP_MAX_ENTRIES_COUNT       # Entry limit (default: 100,000)
JADX_CONFIG_DIR                  # Custom configuration directory
JADX_CACHE_DIR                   # Cache location
JADX_TMP_DIR                     # Temporary file storage
```

## Error Handling

### Common Errors

**"Error: Unable to load DEX"**

```bash
# APK may be corrupted - try apktool
apktool d app.apk
```

**"OutOfMemoryError"**

```bash
# Increase heap size
JAVA_OPTS="-Xmx8g" jadx --deobf -d output/ app.apk

# Or skip resources
jadx --no-res --deobf -d output/ app.apk
```

**"Decompilation failed for class X"**

```bash
# Check for errors
grep -r "JADX WARNING\|JADX ERROR" output/

# Fall back to smali for problematic classes
apktool d app.apk
```

### Verification

```bash
# Check decompilation issues
grep -r "JADX WARNING" output/
grep -r "JADX ERROR" output/

# Count decompiled classes
find output/sources/ -name "*.java" | wc -l
```

## Code Comments

JADX adds helpful annotations:

```java
// Deobfuscated: Original name was 'a'
public class UserManager {

    // JADX WARNING: Removed duplicated region for block: B:12:0x0024
    public void login(String username) {
        // ...
    }

    // JADX INFO: Access modifiers changed from private to public
    public static final int VERSION = 123;
}
```

## Limitations

**Cannot decompile:**

- Native code (.so files) - use IDA/Ghidra
- Heavily obfuscated control flow - may produce unreadable code
- String encryption - encrypted strings remain encrypted
- Reflection-heavy code - may miss runtime behavior

**Note:** "Please note that in most cases jadx can't decompile all 100% of the code, so errors will occur." Consult
the [Troubleshooting Q&A](https://github.com/skylot/jadx/wiki/Troubleshooting-Q&A) for workarounds.

## Installation

```bash
# macOS
brew install jadx

# Arch Linux
sudo pacman -S jadx

# Flathub
flatpak install flathub com.github.skylot.jadx

# From source
git clone https://github.com/skylot/jadx.git
./gradlew dist
```

**Requirements:**

- Java 11 or later (64-bit)

## Version Check

```bash
jadx --version

# Update (Homebrew)
brew upgrade jadx
```

## See Also

- [GitHub Repository](https://github.com/skylot/jadx)
- [Jadx Scripts Guide](https://github.com/skylot/jadx/wiki/Jadx-scripts-guide)
- `apktool-reference.md` - For smali disassembly
- `apkanalyzer-reference.md` - For APK structure inspection
