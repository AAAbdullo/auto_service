package com.example.auto_service

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("20a40c6c-d27c-46b6-b96a-b4b6a4cb47ba")
        MapKitFactory.initialize(this)
    }
}
