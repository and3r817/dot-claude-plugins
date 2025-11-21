# Vineflower Decompiler Reference

**Official Website:** https://vineflower.org/
**GitHub Repository:** https://github.com/Vineflower/vineflower

Vineflower is a modern Java and JVM language decompiler focused on accuracy and output quality. It's a fork of
JetBrains' Fernflower incorporating improvements from MinecraftForge's ForgeFlower, FabricMC's version, and Quiltflower.

## Why Use Vineflower

**Best for modern Java projects** (Java 21+):

- **Cutting-edge Java support**: Records, sealed classes, switch expressions, pattern matching
- **Clean output**: Automatic code formatting with high readability
- **Multithreaded decompilation**: Faster processing for large projects
- **Active development**: Regular updates from community-driven project
- **IntelliJ integration**: Plugin available for IDE workflow

## When to Use Vineflower

**Ideal scenarios**:

- Projects using Java 17, 21, or newer features
- Need for records, sealed classes, pattern matching decompilation
- IntelliJ IDEA users wanting better built-in decompiler
- Modern Spring Boot or Jakarta EE applications
- Kotlin bytecode analysis (includes Kotlin decompiler plugin)

**Not recommended for**:

- Android DEX files (use JADX instead)
- Java 8 or older projects (CFR is faster)
- When speed is critical over modern feature support (CFR is faster)

## Installation

### Requirements

- **Java 17 or newer** (versions 1.11+ require Java 17)
- For older Vineflower versions (1.9+): Java 11+

### Download Latest Release

```bash
# Download from GitHub releases
wget https://github.com/Vineflower/vineflower/releases/latest/download/vineflower-1.10.1.jar

# Or from Maven Central
wget https://repo1.maven.org/maven2/org/vineflower/vineflower/1.10.1/vineflower-1.10.1.jar

# Make executable (optional)
chmod +x vineflower-1.10.1.jar
```

### Verify Installation

```bash
java -jar vineflower.jar --version
# Output: Vineflower 1.10.1
```

### IntelliJ IDEA Plugin

1. **Settings** → **Plugins**
2. Search for "Vineflower"
3. Install **Vineflower Intellij IDEA Plugin**
4. Restart IDE

The plugin replaces Fernflower with Vineflower and allows custom settings configuration.

## Basic Usage

### Decompile Single JAR

```bash
# Basic decompilation
java -jar vineflower.jar library.jar output-dir/

# Specify output format
java -jar vineflower.jar library.jar output-dir/ -cfg=format=java
```

### Decompile Single Class

```bash
# Decompile class file
java -jar vineflower.jar MyClass.class output-dir/
```

### Decompile with Options

```bash
# Custom decompilation settings
java -jar vineflower.jar library.jar output-dir/ \
  -ind="  " \          # 2-space indentation
  -log=WARN \          # Warning level logging
  -threads=8           # 8 parallel threads
```

## Command-Line Options

### Output Control

```bash
-o=<path>                       # Output directory (alternative syntax)
-log=<LEVEL>                    # Logging level: TRACE, INFO, WARN, ERROR
-threads=<NUM>                  # Number of decompilation threads (default: auto)
```

### Code Formatting

```bash
-ind="  "                       # Indentation (default: "   " - 3 spaces)
-ind="\t"                       # Use tabs for indentation
-format=java                    # Output format (java is default)
```

### Decompilation Behavior

```bash
-dgs=<0|1>                      # Decompile generic signatures (default: 1)
-rsy=<0|1>                      # Remove synthetic classes (default: 0)
-rbr=<0|1>                      # Remove bridge methods (default: 1)
-lit=<0|1>                      # Literals as-is (default: 0)
-asc=<0|1>                      # ASCII strings only (default: 0)
```

### Modern Java Features

```bash
-jvn=<VERSION>                  # Target Java version (8, 11, 17, 21)
-iec=<0|1>                      # Inline expression constructor (default: 1)
-pat=<0|1>                      # Pattern matching (default: 1)
-tcs=<0|1>                      # Text blocks (default: 1)
```

### Variable Renaming

```bash
-ren=<0|1>                      # Rename ambiguous variables (default: 0)
-vac=<0|1>                      # Use var type (default: 1)
```

### Advanced Options

```bash
-bsm=<0|1>                      # Decompile bootstrap methods (default: 0)
-dcl=<0|1>                      # Decompile complex loops (default: 1)
-nls=<0|1>                      # New line before brace (default: 0)
-mpm=<NUM>                      # Maximum processing methods (default: 0, unlimited)
```

## Common Usage Patterns

### Decompiling Modern Java (17-21)

```bash
# Enable all modern features
java -jar vineflower.jar modern-app.jar decompiled/ \
  -jvn=21 \
  -pat=1 \
  -tcs=1 \
  -threads=8
```

### Decompiling with Clean Formatting

```bash
# 2-space indentation with variable renaming
java -jar vineflower.jar library.jar src/ \
  -ind="  " \
  -ren=1 \
  -vac=1
```

### High-Performance Decompilation

```bash
# Maximum speed for large projects
java -Xmx4g -jar vineflower.jar huge-project.jar output/ \
  -threads=16 \
  -log=ERROR
```

### Decompiling AAR Library

```bash
# Extract classes.jar from AAR first
unzip library.aar classes.jar

# Decompile with Vineflower
java -jar vineflower.jar classes.jar library-src/
```

### Kotlin Bytecode Analysis

Vineflower includes a Kotlin decompiler plugin:

```bash
# Decompile Kotlin-compiled JAR
java -jar vineflower.jar kotlin-app.jar decompiled/
# Automatically detects and decompiles Kotlin bytecode
```

## Output Format

Vineflower produces cleanly formatted Java source:

```
decompiled/
├── com/
│   └── example/
│       ├── Application.java
│       ├── model/
│       │   ├── User.java (with records if Java 14+)
│       │   └── Status.java (with sealed classes if Java 17+)
│       └── service/
│           └── UserService.java (with pattern matching if Java 21+)
```

### Example Output for Modern Java Features

**Java 17 Sealed Class**:

```java
public sealed class Shape permits Circle, Rectangle, Triangle {
    // Properly decompiled sealed class hierarchy
}

public final class Circle extends Shape {
    private final double radius;
    // ...
}
```

**Java 16 Record**:

```java
public record User(String name, int age, String email) {
    // Properly decompiled record with compact constructor
}
```

**Java 21 Pattern Matching**:

```java
public String process(Object obj) {
    return switch (obj) {
        case String s -> "String: " + s;
        case Integer i when i > 0 -> "Positive: " + i;
        case null -> "null value";
        default -> "Unknown";
    };
}
```

## Performance Characteristics

**Speed**: Moderate (slower than CFR, faster than Procyon)

- Multithreaded processing improves performance on multi-core systems
- ~10-15 seconds for 1.5MB JAR with 8 threads

**Memory Usage**:

```bash
# Default (sufficient for most JARs)
java -jar vineflower.jar app.jar decompiled/

# Large JARs (100MB+)
java -Xmx2g -jar vineflower.jar large-app.jar decompiled/

# Very large projects
java -Xmx4g -jar vineflower.jar huge-app.jar decompiled/ -threads=16
```

**Accuracy**: Excellent for modern Java

- Handles Java 21+ features better than any other decompiler
- Clean output with automatic formatting
- Variable renaming option improves readability

## IntelliJ IDEA Integration

Once the Vineflower plugin is installed:

1. **View decompiled classes**: Click on any `.class` file in project
2. **Configure settings**: **Settings** → **Other Settings** → **Vineflower**
3. **Customize options**:
    - Enable pattern matching decompilation
    - Set indentation style
    - Configure thread count for batch decompilation

## Maven/Gradle Integration

### Maven

```xml
<dependency>
    <groupId>org.vineflower</groupId>
    <artifactId>vineflower</artifactId>
    <version>1.10.1</version>
</dependency>
```

### Gradle

```groovy
implementation 'org.vineflower:vineflower:1.10.1'
```

### Programmatic Usage

```java
import org.jetbrains.java.decompiler.main.decompiler.ConsoleDecompiler;

public class DecompilerExample {
    public static void main(String[] args) {
        ConsoleDecompiler.main(new String[]{
            "-o", "output-dir",
            "-threads", "8",
            "input.jar"
        });
    }
}
```

## Troubleshooting

### Common Errors

**"UnsupportedClassVersionError"**

```bash
# Vineflower 1.11+ requires Java 17
java --version  # Check Java version

# Upgrade to Java 17 or newer
# macOS (Homebrew)
brew install openjdk@17

# Or use older Vineflower version for Java 11
wget https://github.com/Vineflower/vineflower/releases/download/1.9.3/vineflower-1.9.3.jar
```

**"OutOfMemoryError" for large JARs**

```bash
# Increase heap size
java -Xmx4g -jar vineflower.jar large-app.jar decompiled/
```

**Poor performance on single-core systems**

```bash
# Reduce thread count for single-core systems
java -jar vineflower.jar app.jar decompiled/ -threads=1
```

**Decompilation fails for obfuscated code**

```bash
# Enable variable renaming
java -jar vineflower.jar obfuscated.jar decompiled/ -ren=1

# Or fall back to CFR/JADX for obfuscated code
java -jar cfr.jar obfuscated.jar --outputdir decompiled/
```

## Limitations

**Cannot decompile**:

- Android DEX files (use JADX instead)
- Native code (.so, .dll files)
- Heavily obfuscated control flow
- Pre-Java 8 projects (CFR is better)

**Performance considerations**:

- Slower than CFR for simple Java 8-11 projects
- Requires Java 17+ runtime (limits portability)
- Multithreading helps but still slower than CFR on single-threaded tasks

## Comparison with Other Decompilers

| Feature              | Vineflower | CFR      | JADX     | Procyon |
|----------------------|------------|----------|----------|---------|
| **Java 21+ Support** | ⭐⭐⭐⭐⭐      | ❌        | ❌        | ❌       |
| **Speed**            | ⭐⭐⭐⭐       | ⭐⭐⭐⭐⭐    | ⭐⭐⭐      | ⭐       |
| **Readability**      | ⭐⭐⭐⭐       | ⭐⭐⭐⭐⭐    | ⭐⭐       | ⭐⭐⭐⭐⭐   |
| **Records/Sealed**   | ✅          | ❌        | ❌        | ❌       |
| **Pattern Matching** | ✅          | ❌        | ❌        | ❌       |
| **Android/DEX**      | ❌          | ❌        | ✅        | ❌       |
| **IDE Integration**  | ✅ IntelliJ | ❌        | ✅ GUI    | ❌       |
| **Kotlin Support**   | ✅ Plugin   | ❌        | Limited  | ❌       |
| **Maintenance**      | ✅ Active   | ✅ Active | ✅ Active | ❌ Stale |

**Recommendation**:

- **Modern Java (17-21)**: Vineflower (best choice)
- **Java 8-14 projects**: CFR (faster, better readability)
- **Android/APK**: JADX (only option)
- **IntelliJ users**: Vineflower (plugin integration)

## History and Evolution

**Fernflower** (2008-2015) → Created by Stiver, acquired by JetBrains

- Integrated into IntelliJ IDEA as default decompiler
- Historically achieved ~95% decompilation success

**ForgeFlower** (2016-2018) → MinecraftForge fork

- Improvements for modding community
- Better handling of synthetic methods

**Quiltflower** (2021-2023) → Community fork by Quilt project

- Modernization for Java 17+
- Improved output quality

**Vineflower** (2023-present) → Renamed and expanded Quiltflower

- Shift to general-purpose Java decompiler (beyond Minecraft)
- Java 21+ support, active community development

## See Also

- [CFR Reference](cfr-reference.md) - For faster Java 8-14 decompilation
- [JADX Reference](jadx-reference.md) - For Android APK/DEX decompilation
- [Tool Comparison](tool-comparison.md) - Detailed comparison of all decompilers
- [Official Vineflower Website](https://vineflower.org/)
- [Vineflower GitHub](https://github.com/Vineflower/vineflower)
