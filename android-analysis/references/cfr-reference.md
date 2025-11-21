# CFR (Class File Reader) Decompiler Reference

**Official Website:** https://www.benf.org/other/cfr/
**GitHub Repository:** https://github.com/leibnitz27/cfr

CFR is a Java decompiler that converts compiled .class files and JAR archives back into readable Java source code. It
excels at modern Java features and produces highly readable output with minimal synthetic constructs.

## Why Use CFR

**Best for JAR files**: CFR provides superior readability compared to JADX for pure Java libraries

- **Fastest decompilation**: 6.5 seconds for 1.5MB JAR (vs 26.7s for Procyon)
- **Best readability**: Excels at variable naming, Lambda expressions, Stream operations, Switch syntax
- **Modern Java support**: Java 5-14 features including modules, records, switch expressions
- **Actively maintained**: Regular updates with fast development cycle

## Installation

### Download Latest Release

```bash
# Download CFR JAR
wget https://www.benf.org/other/cfr/cfr-0.152.jar

# Or from GitHub releases
wget https://github.com/leibnitz27/cfr/releases/latest/download/cfr-0.152.jar

# Make it executable (optional)
chmod +x cfr-0.152.jar
```

### Verify Installation

```bash
java -jar cfr-0.152.jar --version
# Output: CFR 0.152
```

## Basic Usage

### Decompile Single JAR

```bash
# Basic decompilation
java -jar cfr.jar library.jar --outputdir decompiled/

# Specify output path
java -jar cfr.jar library.jar --outputpath /path/to/output/
```

### Decompile Single Class File

```bash
# Decompile to stdout
java -jar cfr.jar MyClass.class

# Save to file
java -jar cfr.jar MyClass.class --outputdir src/
```

### Decompile with External Dependencies

```bash
# Reference external JARs for better type inference
java -jar cfr.jar myapp.jar \
  --extraclasspath "lib/dependency1.jar:lib/dependency2.jar" \
  --outputdir decompiled/
```

## Command-Line Options

### Output Control

```bash
--outputdir <path>              # Output directory for decompiled files
--outputpath <path>             # Alternative output path specification
--caseinsensitivefs <bool>      # Case-insensitive filesystem (default: auto-detect)
--silent <bool>                 # Suppress summary output
```

### Java Version Compatibility

```bash
--java14 <bool>                 # Enable Java 14 features (records, pattern matching)
--sugarenums <bool>             # Decompile enums as syntactic sugar (default: true)
--stringbuffer <bool>           # Convert StringBuffer to StringBuilder
--stringbuilder <bool>          # Decompile with StringBuilder
```

### Decompilation Behavior

```bash
--aexagg <bool>                 # Aggressive array expression aggregation
--arrayiter <bool>              # Re-sugar array iteration (default: true)
--collectioniter <bool>         # Re-sugar collection iteration (default: true)
--tryresources <bool>           # Re-construct try-with-resources (default: true)

--decodeenumswitch <bool>       # Re-construct switch on enum (default: true)
--decodestringswitch <bool>     # Re-construct switch on string (default: true)
--decodelambdas <bool>          # Re-construct lambda functions (default: true)
```

### Code Cleanup

```bash
--removeboilerplate <bool>      # Remove boilerplate functions (default: true)
--removeinnerclasssynthetics    # Remove inner class synthetic methods (default: true)
--hideutf <bool>                # Hide UTF8 characters (default: true)
--hidelongstrings <bool>        # Hide very long strings (default: false)
--commentmonitors <bool>        # Replace monitors with comments (default: false)
```

### Advanced Options

```bash
--extraclasspath <path>         # Additional classpaths for type resolution
--renamedupmembers <bool>       # Rename ambiguous/duplicate members (default: false)
--renameillegalidents <bool>    # Rename illegal identifiers (default: false)
--renamesmallmembers <int>      # Rename small members (default: 0, disabled)

--showinferrable <bool>         # Show inferrable types (default: false)
--forcetopsort <bool>           # Force topological sort (default: false)
--forloopaggcapture <bool>      # Allow for loop to aggressively capture (default: false)
```

### Obfuscation Handling

```bash
--renamedupmembers true         # Rename duplicate member names
--renameillegalidents true      # Rename illegal Java identifiers
--renamesmallmembers 3          # Rename members with names shorter than 3 chars
```

## Common Usage Patterns

### Decompiling Modern Java (8-14)

```bash
# Enable all modern features
java -jar cfr.jar modern-app.jar \
  --java14 true \
  --decodelambdas true \
  --tryresources true \
  --outputdir decompiled/
```

### Decompiling Obfuscated JARs

```bash
# Rename obfuscated members for readability
java -jar cfr.jar obfuscated.jar \
  --renamedupmembers true \
  --renameillegalidents true \
  --renamesmallmembers 3 \
  --outputdir decompiled/
```

### Large JAR with External Dependencies

```bash
# Allocate more memory and provide dependencies
java -Xmx4g -jar cfr.jar large-app.jar \
  --extraclasspath "lib/*" \
  --outputdir decompiled/ \
  --silent true
```

### Extracting Classes.jar from AAR

```bash
# Full workflow for AAR analysis
unzip library.aar classes.jar
java -jar cfr.jar classes.jar --outputdir library-src/

# Alternative: extract and decompile in one step
unzip -p library.aar classes.jar | java -jar cfr.jar - --outputdir library-src/
```

### Comparing Decompiler Output

```bash
# Decompile same JAR with multiple tools for validation
java -jar cfr.jar app.jar --outputdir cfr-output/
java -jar procyon.jar app.jar --outputdir procyon-output/

# Compare critical classes
diff cfr-output/com/app/Main.java procyon-output/com/app/Main.java
```

## Output Format

CFR produces clean Java source files organized by package structure:

```
decompiled/
├── com/
│   └── example/
│       ├── Main.java
│       ├── models/
│       │   ├── User.java
│       │   └── Product.java
│       └── utils/
│           └── StringUtils.java
└── META-INF/
    └── MANIFEST.MF
```

### Example Decompiled Output

**Original obfuscated bytecode**:

```java
class a {
    int a(int a) { return a * 2; }
}
```

**CFR decompiled output** (with `--renamedupmembers`):

```java
public class Calculator {
    public int multiply(int value) {
        return value * 2;
    }
}
```

## Performance Characteristics

**Speed Comparison** (from research):

- **CFR**: 6.5 seconds for 1.5MB JAR (fastest)
- **Procyon**: 26.7 seconds for 1.5MB JAR (slowest)
- **JADX**: ~10-15 seconds (Android-focused, poor Java quality)

**Accuracy** (from 2023 research):

- **Syntactic accuracy**: 84% (industry standard)
- **Behavioral accuracy**: 78% (best-in-class)

**Memory Usage**:

```bash
# Default (sufficient for most JARs)
java -jar cfr.jar app.jar --outputdir decompiled/

# Large JARs (100MB+)
java -Xmx2g -jar cfr.jar large-app.jar --outputdir decompiled/

# Very large JARs (500MB+)
java -Xmx4g -jar cfr.jar huge-app.jar --outputdir decompiled/
```

## Integration Examples

### Bash Script for Batch Decompilation

```bash
#!/bin/bash
# Decompile all JARs in directory

for jar in *.jar; do
    echo "Decompiling $jar..."
    java -jar cfr.jar "$jar" --outputdir "decompiled/${jar%.jar}/" --silent true
done
```

### IDE Integration (IntelliJ IDEA)

CFR can be configured as external tool:

1. **Settings** → **Tools** → **External Tools**
2. **Add new tool**:
    - Name: `CFR Decompiler`
    - Program: `java`
    - Arguments: `-jar /path/to/cfr.jar $FilePath$ --outputdir $FileParentDir$/decompiled/`
    - Working directory: `$ProjectFileDir$`

### CI/CD Pipeline Integration

```yaml
# GitHub Actions example
- name: Decompile JAR for analysis
  run: |
    wget https://www.benf.org/other/cfr/cfr-0.152.jar
    java -jar cfr-0.152.jar build/libs/app.jar --outputdir decompiled/
    # Run static analysis on decompiled code
```

## Troubleshooting

### Common Errors

**"java.lang.OutOfMemoryError"**

```bash
# Increase heap size
java -Xmx4g -jar cfr.jar large-app.jar --outputdir decompiled/
```

**"ClassNotFoundException" during decompilation**

```bash
# Provide external dependencies
java -jar cfr.jar app.jar \
  --extraclasspath "lib/dependency.jar:lib/another.jar" \
  --outputdir decompiled/
```

**Poor variable names in output**

```bash
# Enable member renaming
java -jar cfr.jar obfuscated.jar \
  --renamedupmembers true \
  --renamesmallmembers 3 \
  --outputdir decompiled/
```

**Synthetic methods cluttering output**

```bash
# Remove boilerplate and synthetic code
java -jar cfr.jar app.jar \
  --removeboilerplate true \
  --removeinnerclasssynthetics true \
  --outputdir decompiled/
```

## Limitations

**Cannot decompile**:

- Native code (.so, .dll files) - use IDA/Ghidra
- Android DEX files directly - use JADX instead
- Heavily obfuscated control flow - may produce unreadable code
- Encrypted strings - remain encrypted in output

**Accuracy notes**:

- Generic variable names (var1, var2) when debug info missing
- Some compiler optimizations may not reverse perfectly
- Final output may differ syntactically from original source

## Comparison with Other Decompilers

| Feature         | CFR          | JADX         | Procyon            | Vineflower |
|-----------------|--------------|--------------|--------------------|------------|
| **Speed**       | ⭐⭐⭐⭐⭐ (6.5s) | ⭐⭐⭐ (10-15s) | ⭐ (26.7s)          | ⭐⭐⭐⭐       |
| **Readability** | ⭐⭐⭐⭐⭐        | ⭐⭐           | ⭐⭐⭐⭐⭐              | ⭐⭐⭐⭐       |
| **Modern Java** | Java 5-14    | Limited      | Java 8             | Java 21+   |
| **Android/DEX** | ❌            | ✅            | ❌                  | ❌          |
| **Maintenance** | ✅ Active     | ✅ Active     | ❌ Stale (2+ years) | ✅ Active   |
| **GUI**         | ❌            | ✅            | ❌                  | ✅ (plugin) |

**Recommendation**:

- **JAR files**: CFR (best choice)
- **APK/DEX files**: JADX (only option)
- **Java 21+ features**: Vineflower
- **Highest fidelity**: Procyon (but very slow)

## See Also

- [JADX Reference](jadx-reference.md) - For Android APK/DEX decompilation
- [Vineflower Reference](vineflower-reference.md) - For modern Java 21+ features
- [Tool Comparison](tool-comparison.md) - Detailed comparison of all decompilers
- [Official CFR Documentation](https://www.benf.org/other/cfr/)
