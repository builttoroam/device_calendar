val kotlinVersion = "2.3.20"

group = "com.builttoroam.devicecalendar"
version = "1.0-SNAPSHOT"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Whether the AGP version the *consuming* build resolves (root project's
// own pluginManagement, not anything declared here) is 9+, where Kotlin
// support is embedded in AGP itself and applying the standalone
// kotlin-android plugin breaks the build. Below 9, it must be applied
// explicitly. See PR #612's original Groovy version of this same check.
val isAgp9OrAbove = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION
    .substringBefore(".").toInt() >= 9

plugins {
    id("com.android.library")
}

if (!isAgp9OrAbove) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

android {
    namespace = "com.builttoroam.devicecalendar"

    compileSdk = 36

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("proguard-rules.pro")
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }

    lint {
        disable += "InvalidPackage"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

if (!isAgp9OrAbove) {
    extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension>("kotlin") {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion")
    implementation("com.google.code.gson:gson:2.14.0")
    api("androidx.appcompat:appcompat:1.7.1")
    implementation("org.dmfs:lib-recur:0.17.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.4.0")
    testImplementation("androidx.test:core:1.6.1")
}
