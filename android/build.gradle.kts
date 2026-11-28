group = "com.dsolutions.image_converter"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.4.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.3.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Built-in Kotlin (AGP 9): the Kotlin Gradle plugin is not applied here.
// See https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
plugins {
    id("com.android.library")
}

android {
    namespace = "com.dsolutions.image_converter"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 21
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.exifinterface:exifinterface:1.3.7")
    // Without the Kotlin Gradle plugin nothing picks kotlin-test's JUnit 5
    // variant automatically, so name it (and its version) explicitly.
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5:2.4.20")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
