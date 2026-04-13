package com.jinoca.vpn

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "nocix/launcher"
    private val NOTIF_CHANNEL_ID = "nocix_vpn_channel"
    private val NOTIF_ID = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Open URL in browser ─────────────────
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("OPEN_URL_ERROR", e.message, null)
                            }
                        } else {
                            result.error("INVALID_URL", "URL is null", null)
                        }
                    }

                    // ── Show persistent VPN notification ────
                    "showNotification" -> {
                        val title = call.argument<String>("title") ?: "NOCIX VPN"
                        val body  = call.argument<String>("body")  ?: "Connected"
                        try {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                                    as NotificationManager
                            val notif = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
                                .setSmallIcon(android.R.drawable.ic_lock_lock)
                                .setContentTitle(title)
                                .setContentText(body)
                                .setPriority(NotificationCompat.PRIORITY_LOW)
                                .setOngoing(true)   // cannot be swiped away while VPN is on
                                .setAutoCancel(false)
                                .build()
                            nm.notify(NOTIF_ID, notif)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NOTIF_ERROR", e.message, null)
                        }
                    }

                    // ── Cancel VPN notification ─────────────
                    "cancelNotification" -> {
                        try {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                                    as NotificationManager
                            nm.cancel(NOTIF_ID)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CANCEL_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // Creates the notification channel required on Android 8+
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                "VPN Status",
                NotificationManager.IMPORTANCE_LOW   // silent, no sound
            ).apply {
                description = "Shows when NOCIX VPN is active"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
}
