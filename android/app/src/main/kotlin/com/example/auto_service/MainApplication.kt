package com.example.auto_service

import android.app.Application
import com.yandex.mapkit.MapKitFactory
import com.yandex.mapkit.directions.DirectionsFactory
import android.util.Log

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("21ce4ce6-0677-46c6-9f24-d669e0d8f2ef")
        MapKitFactory.initialize(this)
        try {
            DirectionsFactory.getInstance()
            Log.d("MainApplication", "DirectionsFactory initialized successfully")
        } catch (e: Exception) {
            Log.e("MainApplication", "Error initializing DirectionsFactory", e)
        }
    }
}
