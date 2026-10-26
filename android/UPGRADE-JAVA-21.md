# Upgrade to Java 21 (LTS) for Android Gradle modules

This project has been updated so Android compilation targets Java 21. Follow the steps below to prepare your development environment and validate the upgrade.

## What changed
- `android/app/build.gradle.kts`:
  - `sourceCompatibility` and `targetCompatibility` updated to Java 21
  - `kotlinOptions.jvmTarget` updated to Java 21

## Prerequisites
- Install JDK 21 on your system. On Windows, install to `C:\Program Files\Java\jdk-21` and set `JAVA_HOME` accordingly.

## Steps to test locally
1. Install JDK 21 and set `JAVA_HOME` environment variable.
   - PowerShell example:
     ```powershell
     setx -m JAVA_HOME "C:\Program Files\Java\jdk-21"; $env:JAVA_HOME="C:\Program Files\Java\jdk-21"
     setx -m PATH "%JAVA_HOME%\bin;${env:PATH}"
     ```
2. Optional: Set Gradle to use JDK 21 explicitly for the Android module by adding this to `android/gradle.properties`:
   ```properties
   # Uncomment and set to JDK 21 installation path if you want Gradle to use JDK 21 explicitly
   # org.gradle.java.home=C:\Program Files\Java\jdk-21
   ```
3. Clean and build:
   - From project root:
     ```powershell
     cd android
     .\gradlew clean assembleDebug
     ```
   - Or run the Flutter build:
     ```powershell
     cd ..\
     flutter build apk
     ```

## CI considerations
- Ensure CI services that compile Android have JDK 21 installed and/or have `org.gradle.java.home` set to the JDK 21 path.
- Ensure Gradle 8.12 (already set in `gradle-wrapper.properties`) is compatible with JDK 21.

## Rollback
- If there are compatibility issues with third-party plugins, revert the Java target values to the previous ones (Java 11) and report issues.

## Further steps
- If you want me to: install JDK 21 using automated tools (requires sign-in to Copilot's app modernization tools), or run a CI build and tests, let me know.
