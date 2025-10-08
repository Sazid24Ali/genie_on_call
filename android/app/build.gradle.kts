plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Ensure this is present
    id("com.google.gms.google-services") // Ensure this is present
}

android {
    namespace = "com.example.genie_on_call"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.genie_on_call" // Replace with your actual application ID if different
        minSdk = 23 // Ensure this is at least 21 for modern Firebase features and desugaring
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Enable core library desugaring
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    // Corrected syntax for Kotlin DSL: use property assignment with file()
    source = "../.." // CHANGED THIS LINE
}

dependencies {
    implementation(kotlin("stdlib-jdk8")) // Use kotlin-stdlib-jdk8 for Java 8 features
    implementation(platform("com.google.firebase:firebase-bom:32.7.0")) // Ensure Firebase BOM is used and up-to-date
    implementation("com.google.firebase:firebase-messaging") // Existing FCM dependency
    implementation("com.google.firebase:firebase-auth:22.3.1") // Assuming you have this for auth
    implementation("com.google.firebase:firebase-firestore") // Assuming you have this for firestore

    // Add the desugaring library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}