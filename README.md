# CS710S-Android — JitPack Library Distribution

This repository publishes three Android libraries for the CS710S/CS108 RFID readers via [JitPack](https://jitpack.io), plus a quick-start demo app you can build locally.

[Product information](https://www.convergence.com.hk/cs710s/)

## Published libraries

| Library | JitPack coordinate | Purpose |
|---|---|---|
| `csl-rfid-android-sdk` | `com.github.cslrfid.cs710s-android:csl-rfid-android-sdk:{TAG}` | Callback-based wrapper SDK — recommended entry point |
| `cslibrary4a` | `com.github.cslrfid.cs710s-android:cslibrary4a:{TAG}` | Core BLE/USB protocol and reader-chip drivers |
| `epctagcoder` | `com.github.cslrfid.cs710s-android:epctagcoder:{TAG}` | EPC tag encode/decode utility |

Dependency chain: `csl-rfid-android-sdk` → `cslibrary4a` → `epctagcoder`. Depending on any one library pulls in its transitive deps automatically.

## Consuming the libraries

**`settings.gradle`** (Gradle 7+):

```groovy
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

**`app/build.gradle`**:

```groovy
dependencies {
    // Recommended: wrapper SDK — transitively brings in cslibrary4a and epctagcoder
    implementation 'com.github.cslrfid.cs710s-android:csl-rfid-android-sdk:1.0.0'

    // Or, core SDK only (no wrapper) — still brings in epctagcoder
    // implementation 'com.github.cslrfid.cs710s-android:cslibrary4a:1.0.0'
}
```

## Demo app — `cs710aquickstart`

A minimal Android demo (MVVM, ViewModel-based) that exercises BLE scan, connect, inventory, Geiger search, battery monitoring, and hardware-trigger support against the wrapper SDK.

```bash
./gradlew :cs710aquickstart:assembleDebug          # Debug APK
./gradlew :cs710aquickstart:installDebug           # Install to a connected device
```

See `cs710aquickstart/README.md` for the full walkthrough.

## Prerequisites for local development

- Android Studio
- Android SDK API Level 36 (compileSdk/targetSdk), minSdk 26
- JDK 17
- macOS / Linux / Windows
