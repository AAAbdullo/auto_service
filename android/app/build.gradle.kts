plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.auto_service"  // ваш namespace
    compileSdk = 36
    
    defaultConfig {
        applicationId = "com.example.auto_service"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

         val properties = org.jetbrains.kotlin.konan.properties.Properties()
         val localPropertiesFile = rootProject.file("local.properties")
         if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        
        val yandexMapkitApiKey = properties.getProperty("YANDEX_MAPKIT_API_KEY") ?: ""
        manifestPlaceholders["YANDEX_MAPKIT_API_KEY"] = yandexMapkitApiKey
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

    dependencies {
    // Force full version of MapKit with Driving support
    implementation("com.yandex.android:maps.mobile:4.22.0-full")
}

configurations.all {
    resolutionStrategy {
        eachDependency {
            if (requested.group == "com.yandex.android" && requested.name == "maps.mobile") {
                useTarget("com.yandex.android:maps.mobile:4.22.0-full")
            }
        }
    }
}
