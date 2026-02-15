# dvsa-util (in.yadhu.dvsa_util:dvsa)

Internal library for DVSA — built and published only to the **private Nexus** (not to Maven Central).

## Build and publish

From **this directory** (dvsa-util has its own Gradle wrapper):

```bash
./gradlew build publish
```

## Main app

The main DVSA application depends on `in.yadhu.dvsa_util:dvsa:0.0.1-SNAPSHOT` from the private registry. Publish this project to Nexus before building the main app (or ensure the artifact is already in your private repo).
