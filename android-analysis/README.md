# Android Analysis

Android APK/AAR/JAR decompilation and inspection toolkit for analyzing compiled binaries and unpacking libraries.

## Features

**🔍 Expert Decompilation Skill**: Autonomous Android binary analysis assistant

- Decompiles APKs, AARs, and JARs to readable Java source code
- Analyzes obfuscated code with deobfuscation support
- Inspects library contents and dependencies
- Extracts and analyzes Android resources and manifests
- Provides code-level insights and architectural analysis

**⚡ Quick Command**: Reverse engineering workflow

- `/android-reverse` - Complete decompilation, disassembly, and code inspection

**📚 Documentation**: Tool setup and comparison guides

- Installation instructions for decompilation tools (JADX, apktool)
- Tool comparison and selection matrix

## Installation

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install android-analysis@dot-claude-plugins
```

## Usage

### Skill-Based Analysis

Ask Claude Code to analyze Android binaries, and the skill will automatically activate:

**Examples:**

```
"Decompile this APK and show me the main activity"
"What's inside this AAR library?"
"Unpack this JAR and inspect the API classes"
"Is this APK obfuscated? What techniques are used?"
"Find all API endpoints in this decompiled APK"
"Analyze the authentication flow in this app"
"What libraries does this APK use?"
```

The skill will:

1. Decompile the binary with JADX (or apktool for smali)
2. Inspect the decompiled code structure
3. Search for specific functionality
4. Analyze and explain code behavior
5. Identify obfuscation techniques
6. Provide architectural insights

### Quick Command

For comprehensive analysis:

```bash
/android-reverse app-release.apk
```

Performs:

- APK decompilation with JADX
- Smali disassembly with apktool
- Manifest and permissions analysis
- Resource extraction
- Code pattern analysis
- Obfuscation detection

## Tool Requirements

### Essential

- **JADX** - Best Android decompiler (`brew install jadx`)
- **apktool** - APK disassembler (`brew install apktool`)

### Recommended

- **apkanalyzer** - APK structure inspector (part of Android SDK)
- **unzip/jar** - Archive extraction (built-in)
- **tree** - Directory visualization (`brew install tree`)

See `references/installation-guide.md` for detailed setup instructions.

## Common Workflows

### 1. Decompile and Inspect APK

```bash
# Claude Code automatically:
# 1. Decompiles with JADX
jadx --deobf -d output/ app.apk

# 2. Inspects structure
tree -L 3 output/sources/

# 3. Finds key classes
find output/ -name "*MainActivity*.java"

# 4. Searches for specifics
grep -r "API_KEY" output/
```

Just ask: "Decompile app.apk and show me the authentication code"

### 2. Analyze AAR Library

```bash
# Ask: "What's inside this library.aar?"
# Claude Code will:
jadx -d output/ library.aar
# Then analyze public APIs and dependencies
```

### 3. Understand Obfuscation

```bash
# Ask: "Is this APK obfuscated?"
# Claude identifies:
# - ProGuard/R8 class name patterns
# - String encryption
# - Control flow obfuscation
```

### 4. Extract Resources

```bash
# Ask: "Show me the AndroidManifest from this APK"
apktool d app.apk -o output/
# Reads manifest, permissions, components
```

## Examples

**Decompilation requests:**

```
"Decompile this APK and explain what it does"
→ Skill decompiles, reads main classes, explains functionality

"Find all network calls in this app"
→ Skill searches decompiled code for HTTP endpoints

"Is this code obfuscated?"
→ Skill analyzes class names, identifies ProGuard/R8 patterns
```

**Library inspection:**

```
"Unpack this AAR and show me the public API"
→ Skill extracts AAR, decompiles classes.jar, lists public methods

"What version of OkHttp does this JAR use?"
→ Skill searches for version strings in decompiled code
```

**Code analysis:**

```
"Analyze the payment flow in app.apk"
→ Skill finds payment-related classes, explains implementation

"Does this APK store data insecurely?"
→ Skill searches for storage patterns, identifies risks

"Explain the obfuscation used in this app"
→ Skill analyzes obfuscation techniques and patterns
```

## Reference Documentation

Detailed guides in `references/`:

- **installation-guide.md** - Tool setup for JADX, apktool, apkanalyzer
- **tool-comparison.md** - Tool selection matrix and decision trees

## Supported Analysis Domains

| Domain                   | Tools Used       | Output                                       |
|--------------------------|------------------|----------------------------------------------|
| **Decompilation**        | JADX, apktool    | Java source code, smali bytecode             |
| **Code Inspection**      | grep, find, Read | Code patterns, functionality analysis        |
| **Obfuscation Analysis** | JADX --deobf     | Deobfuscation, technique identification      |
| **Library Unpacking**    | unzip, jar, JADX | AAR/JAR contents, dependency analysis        |
| **Resource Extraction**  | apktool, aapt    | Manifest, layouts, strings, assets           |
| **Structure Analysis**   | apkanalyzer      | Package breakdown, method counts, components |

## Troubleshooting

**Skill not activating?**

- Use keywords: APK, AAR, JAR, decompile, inspect, unpack, reverse
- Try: "Decompile this APK" or "What's in this library?"

**Command not found?**

- Check plugin installed: `/plugin list`
- Verify command: `/slash` should show `/android-reverse`

**Tool not found errors?**

- Install JADX: `brew install jadx`
- Install apktool: `brew install apktool`
- Check Android SDK for apkanalyzer
- Review `references/installation-guide.md`

**Decompilation fails?**

- Large APKs may take time (50MB+ can take minutes)
- Heavily obfuscated APKs may partially fail
- Try apktool for smali if JADX fails

## Advanced Usage

**Custom JADX options:**

```bash
# Skip resources (faster)
jadx --no-res -d output/ app.apk

# Export as Gradle project
jadx --export-gradle -d output/ app.apk

# Deobfuscate
jadx --deobf -d output/ app.apk
```

**AAR inspection:**

```bash
# Manual extraction
unzip library.aar -d unpacked/
tree unpacked/

# Decompile classes.jar
jadx -d output/ unpacked/classes.jar
```

**Obfuscation analysis:**

```bash
# Find obfuscated classes (single letter names)
find output/ -name "[a-z].java"

# Search for string obfuscation
grep -r "decrypt\|deobfuscate" output/
```

**Structure inspection:**

```bash
# Package breakdown
apkanalyzer dex packages app.apk

# Method count
apkanalyzer dex references app.apk

# Compare versions
apkanalyzer apk compare old.apk new.apk
```

## Contributing

See main repository [CLAUDE.md](../CLAUDE.md) for plugin development guidelines.

## License

MIT

## Uninstall

```bash
/plugin uninstall android-analysis
```
