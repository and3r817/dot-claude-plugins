# Tool Selection Guide (Agent Reference)

Quick reference for choosing the right decompiler/analyzer during reverse engineering tasks.

## Primary Decision Tree

```
What file type?
│
├─ APK (Android Package)
│  │
│  ├─ Need CODE? → JADX (DEX to Java)
│  │  Success? → Done
│  │  Failed? → apktool (DEX to Smali)
│  │
│  ├─ Need RESOURCES/MANIFEST? → apktool
│  │
│  └─ Need STRUCTURE/METADATA? → apkanalyzer
│
├─ AAR (Android Archive)
│  │
│  ├─ Extract classes.jar → unzip library.aar classes.jar
│  │  │
│  │  ├─ Best quality? → CFR (recommended)
│  │  └─ Acceptable? → JADX (faster, lower quality)
│  │
│  ├─ Need FULL CONTENTS? → unzip library.aar -d unpacked/
│  │
│  └─ Quick inspection? → JADX direct: jadx library.aar
│
├─ JAR (Java Archive)
│  │
│  ├─ Java 8-14? → CFR (primary choice - best readability)
│  │
│  ├─ Java 17-21? → Vineflower (modern features)
│  │
│  └─ CFR unavailable? → JADX (fallback, lower quality)
│
└─ DEX (Dalvik Executable)
   └─ JADX only (no alternatives)
```

## Tool Selection Matrix by File Type

| File Type | Primary Tool          | Alternative | Fallback        | Why                            |
|-----------|-----------------------|-------------|-----------------|--------------------------------|
| **APK**   | JADX                  | apktool     | -               | JADX best for DEX→Java         |
| **AAR**   | CFR (via classes.jar) | JADX direct | Vineflower      | CFR better Java quality        |
| **JAR**   | CFR                   | Vineflower  | JADX            | CFR fastest + best readability |
| **DEX**   | JADX                  | -           | apktool (smali) | JADX only DEX decompiler       |

## Tool Selection Matrix by User Request

| User Request                 | File Type | Tool                | Command                                                                       |
|------------------------------|-----------|---------------------|-------------------------------------------------------------------------------|
| **APK Analysis**             |
| "Decompile APK"              | APK       | JADX                | `jadx --deobf -d out/ app.apk`                                                |
| "Show me the code"           | APK       | JADX                | `jadx --deobf -d out/ app.apk`                                                |
| "What does this APK do?"     | APK       | JADX                | `jadx --deobf -d out/ app.apk`                                                |
| "Is this obfuscated?"        | APK       | JADX                | `jadx --deobf -d out/ app.apk`                                                |
| "Show smali"                 | APK       | apktool             | `apktool d app.apk -o out/`                                                   |
| "Extract manifest"           | APK       | apktool             | `apktool d --no-src app.apk`                                                  |
| "Show permissions"           | APK       | apktool/apkanalyzer | `apkanalyzer manifest permissions app.apk`                                    |
| "What packages are in this?" | APK       | apkanalyzer         | `apkanalyzer dex packages app.apk`                                            |
| "Compare two APKs"           | APK       | apkanalyzer         | `apkanalyzer apk compare old.apk new.apk`                                     |
| **AAR Analysis**             |
| "Analyze this AAR"           | AAR       | CFR                 | `unzip lib.aar classes.jar && java -jar cfr.jar classes.jar --outputdir src/` |
| "Decompile AAR"              | AAR       | CFR                 | `unzip lib.aar classes.jar && java -jar cfr.jar classes.jar --outputdir src/` |
| "Quick AAR check"            | AAR       | JADX                | `jadx --deobf -d out/ lib.aar`                                                |
| "Extract AAR contents"       | AAR       | unzip               | `unzip lib.aar -d unpacked/`                                                  |
| **JAR Analysis**             |
| "Decompile this JAR"         | JAR       | CFR                 | `java -jar cfr.jar lib.jar --outputdir src/`                                  |
| "Analyze Java library"       | JAR       | CFR                 | `java -jar cfr.jar lib.jar --outputdir src/`                                  |
| "Modern Java JAR (17-21)"    | JAR       | Vineflower          | `java -jar vineflower.jar lib.jar src/`                                       |
| "List JAR contents"          | JAR       | jar                 | `jar -tf lib.jar`                                                             |

## Detailed Tool Comparison

### JADX (Android DEX Decompiler)

**Best for:** APK and DEX files only

**Strengths:**

- Only decompiler that handles Android DEX files
- Multi-format support (APK, AAR, JAR, DEX, AAB)
- Built-in deobfuscation (`--deobf` flag)
- GUI available (jadx-gui)
- Fast for Android-specific formats

**Limitations:**

- **Poor Java decompilation quality** (fails Lambda/Stream operations)
- Not recommended for pure Java JARs (use CFR instead)
- May fail on heavily R8-optimized code
- Limited deobfuscation effectiveness without mapping.txt

**When to use:**

- Default choice for APK/DEX analysis
- Multi-format archives (APK, AAB)
- Need GUI for visual browsing
- Quick AAR inspection (but CFR is better quality)

**Command-line options:**

```bash
--deobf                         # Enable deobfuscation (always use)
--no-res                        # Skip resources (faster)
-d output/                      # Output directory
-j 8                            # Use 8 threads
```

**Performance:** 10-15 seconds for medium APK (20-50MB)

---

### CFR (Java JAR Decompiler)

**Best for:** JAR files and extracted classes.jar from AAR

**Strengths:**

- **Best readability** for Java code
- **Fastest speed**: 6.5 seconds for 1.5MB JAR
- Excellent Lambda/Stream handling
- Modern Java 5-14 support
- Actively maintained
- Command-line only (scriptable)

**Limitations:**

- No Android DEX support (use JADX for APK/DEX)
- No GUI
- Java 15-21 features limited (use Vineflower)

**When to use:**

- **Primary choice for all JAR files**
- Extracting classes.jar from AAR (better quality than JADX)
- Need fastest decompilation
- JADX produces unreadable output
- Scripting/automation workflows

**Command-line options:**

```bash
--outputdir decompiled/         # Output directory
--extraclasspath lib/*          # External dependencies
--renamedupmembers true         # Rename obfuscated members
--renamesmallmembers 3          # Rename short names
```

**Performance:** 6.5 seconds for 1.5MB JAR (fastest)

---

### Vineflower (Modern Java Decompiler)

**Best for:** Java 17-21 projects with modern features

**Strengths:**

- **Java 21+ support**: Records, sealed classes, pattern matching, switch expressions
- Clean output with automatic formatting
- Multithreaded decompilation
- IntelliJ IDEA plugin available
- Kotlin decompiler plugin included
- Active development

**Limitations:**

- **Requires Java 17+ runtime** (limits portability)
- Slower than CFR for simple Java 8-11 projects
- No Android DEX support
- Newer tool (less proven than CFR)

**When to use:**

- Java 17+ projects with modern features
- Need records/sealed classes decompilation
- IntelliJ IDEA users (plugin integration)
- Kotlin bytecode analysis

**Command-line options:**

```bash
-jvn=21                         # Target Java 21
-pat=1                          # Enable pattern matching
-threads=8                      # 8 parallel threads
-ind="  "                       # 2-space indentation
```

**Performance:** 10-15 seconds for 1.5MB JAR (with 8 threads)

---

### apktool (Smali Disassembler)

**Best for:** Exact bytecode, resource extraction, APK modifications

**Strengths:**

- Always works (smali is exact bytecode representation)
- Perfect resource extraction
- AndroidManifest.xml decoded to human-readable XML
- Can rebuild modified APKs
- Handles cases where JADX fails

**Limitations:**

- Smali is harder to read than Java source
- Slower than JADX for code analysis
- No Java output (only smali)

**When to use:**

- User asks for smali specifically
- JADX decompilation fails
- Need AndroidManifest.xml or resources
- Need to modify and rebuild APK
- Exact bytecode representation required

**Command-line options:**

```bash
d app.apk -o out/               # Disassemble
--no-src                        # Skip smali (resources only)
--no-res                        # Skip resources (smali only)
--force-manifest                # Force manifest decoding
```

**Performance:** 5-30 seconds for medium APK

---

### apkanalyzer (Structure Inspector)

**Best for:** Quick APK metadata, package counts, version comparisons

**Strengths:**

- Very fast (<5 seconds)
- No decompilation needed
- Precise metadata extraction
- APK comparison features
- Part of Android SDK (usually installed)

**Limitations:**

- Metadata only (no code)
- APK-specific (doesn't work with JAR)

**When to use:**

- "What's in this APK?" (structure overview)
- Package/method count analysis
- Comparing two APK versions
- Before decompiling (understand structure first)

**Command examples:**

```bash
apk summary app.apk             # Overview
dex packages app.apk            # Package breakdown
dex references app.apk          # Method count
apk compare old.apk new.apk     # Version diff
```

**Performance:** <5 seconds for any APK size

---

## Detailed Comparison Table

| Feature              | JADX                | CFR                 | Vineflower          | apktool       | apkanalyzer    |
|----------------------|---------------------|---------------------|---------------------|---------------|----------------|
| **File Support**     |
| APK                  | ✅                   | ❌                   | ❌                   | ✅             | ✅              |
| AAR                  | ✅                   | ✅ (via classes.jar) | ✅ (via classes.jar) | ❌             | ❌              |
| JAR                  | ⚠️ Poor             | ✅ Best              | ✅ Modern            | ❌             | ❌              |
| DEX                  | ✅ Only option       | ❌                   | ❌                   | ✅ (smali)     | ✅ (metadata)   |
| **Output Quality**   |
| Java Readability     | ⭐⭐                  | ⭐⭐⭐⭐⭐               | ⭐⭐⭐⭐                | N/A (smali)   | N/A (metadata) |
| Lambda/Stream        | ❌ Fails             | ✅ Excellent         | ✅ Excellent         | N/A           | N/A            |
| Modern Java (17-21)  | ❌                   | Limited             | ✅ Full              | N/A           | N/A            |
| Obfuscation Handling | ⚠️ Limited          | ⭐⭐⭐                 | ⭐⭐⭐                 | ⭐⭐⭐⭐⭐ (exact) | N/A            |
| **Performance**      |
| Speed                | ⭐⭐⭐                 | ⭐⭐⭐⭐⭐               | ⭐⭐⭐⭐                | ⭐⭐⭐           | ⭐⭐⭐⭐⭐          |
| Memory Usage         | Medium              | Low                 | Medium              | Medium        | Very Low       |
| **Features**         |
| Deobfuscation        | `--deobf` (limited) | Renaming options    | Renaming options    | N/A           | N/A            |
| GUI                  | ✅ jadx-gui          | ❌                   | ✅ (plugin)          | ❌             | ❌              |
| Multithreading       | ✅ `-j`              | ❌                   | ✅ `-threads`        | ❌             | N/A            |
| **Maintenance**      |
| Active Development   | ✅                   | ✅                   | ✅                   | ✅             | ✅              |

## Common Workflows

### Workflow 1: Analyze APK

```bash
# 1. Get structure overview
apkanalyzer apk summary app.apk
apkanalyzer dex packages app.apk

# 2. Decompile code
jadx --deobf -d app-src/ app.apk

# 3. If JADX fails, use apktool for smali
apktool d app.apk -o app-smali/
```

### Workflow 2: Analyze AAR Library

```bash
# 1. Extract classes.jar
unzip library.aar classes.jar

# 2. Decompile with CFR (best quality)
java -jar cfr.jar classes.jar --outputdir library-src/

# Alternative: JADX (faster but lower quality)
jadx --deobf -d library-src/ library.aar
```

### Workflow 3: Analyze JAR Library

```bash
# 1. Determine Java version
jar -xf library.jar META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF | grep "Build-Jdk"

# 2a. Java 8-14: Use CFR
java -jar cfr.jar library.jar --outputdir src/

# 2b. Java 17-21: Use Vineflower
java -jar vineflower.jar library.jar src/

# 3. If CFR/Vineflower unavailable, use JADX (fallback)
jadx -d src/ library.jar
```

### Workflow 4: Deobfuscate with mapping.txt

```bash
# 1. Deobfuscate JAR with mapping file
java -jar reconstruct-cli.jar \
  -jar obfuscated.jar \
  -mapping mapping.txt \
  -output deobfuscated.jar

# 2. Decompile restored JAR
java -jar cfr.jar deobfuscated.jar --outputdir src/
```

### Workflow 5: Compare APK Versions

```bash
# 1. Quick structural diff
apkanalyzer apk compare v1.apk v2.apk --different-only

# 2. If need code comparison
jadx --deobf -d v1-src/ v1.apk
jadx --deobf -d v2-src/ v2.apk

# 3. Compare specific files
Read v1-src/sources/com/app/auth/LoginActivity.java
Read v2-src/sources/com/app/auth/LoginActivity.java
```

## Error Handling Decision Trees

### JADX Produces Unreadable Output (JAR/AAR)

```
JADX output has errors or poor quality?
│
├─ Working with JAR?
│  └─ Use CFR instead: java -jar cfr.jar library.jar --outputdir src/
│
├─ Working with AAR?
│  └─ Extract classes.jar → CFR
│     unzip library.aar classes.jar
│     java -jar cfr.jar classes.jar --outputdir src/
│
└─ Working with APK?
   └─ Fall back to apktool (smali is always accurate)
      apktool d app.apk -o smali/
```

### JADX Decompilation Fails

```
JADX crashes or fails to decompile?
│
├─ APK/DEX file?
│  └─ Use apktool for smali
│     apktool d app.apk -o output/
│
├─ JAR file?
│  └─ Try CFR (more robust)
│     java -jar cfr.jar library.jar --outputdir src/
│
└─ Heavily obfuscated?
   └─ Check for mapping.txt file
      Found? → Use Reconstruct/ReTrace
      Not found? → Use apktool smali (exact bytecode)
```

### Performance Issues

```
Decompilation too slow?
│
├─ Large APK (100MB+)?
│  │
│  ├─ Skip resources: jadx --no-res app.apk
│  └─ Use apkanalyzer first to understand structure
│
├─ Large JAR?
│  │
│  ├─ Use CFR (fastest): java -jar cfr.jar lib.jar --outputdir src/
│  └─ Increase memory: java -Xmx4g -jar cfr.jar lib.jar --outputdir src/
│
└─ Need faster overall?
   └─ Use apkanalyzer for metadata-only analysis (no decompilation)
```

## Tool Availability Verification

```bash
# Check all tools
which jadx             # JADX decompiler
which apktool          # Smali disassembler
which apkanalyzer      # APK structure inspector
java -jar cfr.jar --version          # CFR (check path)
java -jar vineflower.jar --version   # Vineflower (check path)
which unzip            # Archive extraction
which jar              # JAR tool
```

If missing, consult `installation-guide.md`.

## Performance Benchmarks

**Decompilation Speed** (1.5MB JAR):

- CFR: 6.5 seconds (fastest)
- JADX: ~10-15 seconds
- Vineflower: ~10-15 seconds (8 threads)
- Procyon: 26.7 seconds (slowest, not recommended)

**Accuracy** (2023 research):

- Syntactic accuracy: 84% (best tools)
- Behavioral accuracy: 78% (best tools)

**Memory Usage**:

- apkanalyzer: <100MB
- CFR: ~500MB-1GB
- JADX: ~1-2GB
- Vineflower: ~1-2GB

## Decision Summary

**Use JADX when:**

- Analyzing APK or DEX files (only option)
- Need GUI for browsing
- Working with multi-format Android archives

**Use CFR when:**

- Analyzing JAR files (best quality)
- Extracting classes.jar from AAR
- Need fastest decompilation
- JADX produces unreadable output

**Use Vineflower when:**

- Java 17-21 projects with modern features
- Need records, sealed classes, pattern matching
- IntelliJ IDEA users (plugin integration)

**Use apktool when:**

- JADX fails to decompile
- Need exact bytecode (smali)
- Extracting AndroidManifest.xml or resources
- Modifying and rebuilding APKs

**Use apkanalyzer when:**

- Need quick metadata overview
- Comparing APK versions
- Understanding structure before decompilation
