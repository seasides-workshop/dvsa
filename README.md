# DVSA - Damn Vulnerable Supply Chain Application1

A Spring Boot application for supply chain security exercises.

## Prerequisites

- [sdkman](https://sdkman.io/) (SDK Manager) for installing Java

## Setup

### 1. Install Java 17 with sdkman

If you don’t have sdkman:

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

Install and use Java 17 (project uses `.sdkmanrc`; exact version may be auto-selected in the project directory):

```bash
sdk install java 17.0.9-tem
sdk use java 17.0.9-tem
```

Or, from the project root, use the version from `.sdkmanrc`:

```bash
sdk use java
```

### 2. Util dependency

The main app depends on `in.yadhu.util:util`. The project is configured to use the local `dvsa-util` module via Gradle composite build (`includeBuild 'dvsa-util'` in `settings.gradle`), so you can run without a private Maven registry. If you use a registry instead, build and publish the util library first from the `dvsa-util` directory (see `dvsa-util/README.md`).

## Run the application

From the project root:

```bash
./gradlew bootRun
```

The app starts on **http://localhost:8080**.

## Build (no run)

```bash
./gradlew build
```

## Run tests

```bash
./gradlew test
```

