package com.focusx.focusx

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val channelName = "focusx/usage_access"
    private val preferencesName = "focusx_app_limits"
    private val apps = listOf(
        SupportedApp("com.instagram.android", "Instagram"),
        SupportedApp("com.zhiliaoapp.musically", "TikTok"),
        SupportedApp("com.facebook.katana", "Facebook"),
        SupportedApp("com.google.android.youtube", "YouTube"),
        SupportedApp("com.snapchat.android", "Snapchat"),
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getCapabilities" -> result.success(capabilities())
                "requestAuthorization" -> result.success(requestUsageAccess())
                "getAvailableApps" -> result.success(availableApps())
                "selectApps" -> result.success(selectApps(call))
                "getSelectedApps" -> result.success(selectedApps())
                "getUsageSummary" -> result.success(usageSummary())
                "configureAppLimit" -> result.success(configureLimit(call))
                "startDetoxSchedule", "stopDetoxSchedule" ->
                    result.success(mapOf("state" to "unsupported"))
                "getIntegrationStatus" -> result.success(integrationStatus())
                else -> result.notImplemented()
            }
        } catch (error: UsageAccessRequiredException) {
            result.error("permission_required", error.message, null)
        } catch (error: IllegalArgumentException) {
            result.error("invalid_argument", error.message, null)
        } catch (error: Exception) {
            result.error("integration_error", error.message, null)
        }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageAccess(): Map<String, String> {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        return mapOf(
            "state" to if (hasUsageAccess()) "supported" else "permissionRequired",
        )
    }

    private fun installedApps(): List<SupportedApp> = apps.mapNotNull { app ->
        try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getApplicationInfo(
                    app.packageName,
                    android.content.pm.PackageManager.ApplicationInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getApplicationInfo(app.packageName, 0)
            }
            app.copy(name = info.loadLabel(packageManager).toString())
        } catch (_: android.content.pm.PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun availableApps(): Map<String, Any> = mapOf(
        "apps" to installedApps().map { app ->
            mapOf("id" to app.packageName, "name" to app.name)
        },
    )

    private fun selectApps(call: MethodCall): Map<String, Any?> {
        val ids = call.argument<List<String>>("appIds")
            ?: throw IllegalArgumentException("appIds is required")
        val available = installedApps().associateBy { it.packageName }
        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
        val editor = preferences.edit()
        for (id in ids.distinct()) {
            if (id !in available) {
                throw IllegalArgumentException("Unsupported or uninstalled app")
            }
            if (!preferences.contains(limitKey(id))) {
                editor.putString(limitKey(id), encodeLimit(30, false, 0, 0))
            }
        }
        editor.apply()
        return selectedApps()
    }

    private fun selectedApps(): Map<String, Any?> {
        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
        val appsWithLimits = installedApps().associateBy { it.packageName }
        val result = preferences.all.keys
            .filter { it.startsWith("limit.") }
            .mapNotNull { key ->
                val id = key.removePrefix("limit.")
                val definition = appsWithLimits[id] ?: return@mapNotNull null
                val limit = decodeLimit(preferences.getString(key, null))
                    ?: return@mapNotNull null
                val reset = resetStart(limit.resetHour, limit.resetMinute)
                val used = if (hasUsageAccess()) {
                    usedMilliseconds(id, reset)
                } else {
                    null
                }
                if (used != null) {
                    persistUsageSummary(id, reset, used)
                }
                val usedMinutes = used?.let { (it / 60_000L).toInt() }
                val state = when {
                    !hasUsageAccess() -> "permissionRequired"
                    limit.enabled && usedMinutes != null &&
                        usedMinutes >= limit.minutes -> "limitReached"
                    else -> "unsupported"
                }
                mapOf(
                    "id" to id,
                    "name" to definition.name,
                    "dailyLimitMinutes" to limit.minutes,
                    "enabled" to limit.enabled,
                    "usedMinutes" to usedMinutes,
                    "remainingMinutes" to usedMinutes?.let {
                        (limit.minutes - it).coerceAtLeast(0)
                    },
                    "resetHour" to limit.resetHour,
                    "resetMinute" to limit.resetMinute,
                    "state" to state,
                )
            }
        return mapOf(
            "apps" to result,
            "authorization" to if (hasUsageAccess()) "supported" else "permissionRequired",
        )
    }

    private fun usageSummary(): Map<String, Any> {
        if (!hasUsageAccess()) throw UsageAccessRequiredException()
        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
        val usage = mutableMapOf<String, Int>()
        preferences.all.keys
            .filter { it.startsWith("limit.") }
            .forEach { key ->
                val id = key.removePrefix("limit.")
                val limit = decodeLimit(preferences.getString(key, null)) ?: return@forEach
                val reset = resetStart(limit.resetHour, limit.resetMinute)
                val milliseconds = usedMilliseconds(id, reset)
                persistUsageSummary(id, reset, milliseconds)
                usage[id] = (milliseconds / 60_000L).toInt()
            }
        return mapOf("state" to "supported", "usageMinutes" to usage)
    }

    private fun usedMilliseconds(packageId: String, start: Long): Long {
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val event = UsageEvents.Event()
        val queryStart = (start - 24 * 60 * 60 * 1000L).coerceAtLeast(0L)
        var foregroundAt: Long? = null
        var total = 0L

        val queriedEvents = manager.queryEvents(queryStart, end)
        while (queriedEvents.hasNextEvent()) {
            queriedEvents.getNextEvent(event)
            if (event.packageName != packageId) continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (foregroundAt == null) foregroundAt = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val began = foregroundAt
                    if (began != null) {
                        val countedStart = maxOf(start, began)
                        total += (event.timeStamp - countedStart).coerceAtLeast(0L)
                        foregroundAt = null
                    }
                }
            }
        }
        foregroundAt?.let {
            total += (end - maxOf(start, it)).coerceAtLeast(0L)
        }
        return total
    }

    private fun resetStart(hour: Int, minute: Int): Long {
        val now = Calendar.getInstance()
        val reset = now.clone() as Calendar
        reset.set(Calendar.HOUR_OF_DAY, hour)
        reset.set(Calendar.MINUTE, minute)
        reset.set(Calendar.SECOND, 0)
        reset.set(Calendar.MILLISECOND, 0)
        if (now.timeInMillis < reset.timeInMillis) {
            reset.add(Calendar.DAY_OF_YEAR, -1)
        }
        return reset.timeInMillis
    }

    private fun persistUsageSummary(packageId: String, resetStart: Long, usedMillis: Long) {
        getSharedPreferences(preferencesName, MODE_PRIVATE).edit()
            .putString("summary.$packageId", "$resetStart|$usedMillis")
            .apply()
    }

    private fun configureLimit(call: MethodCall): Map<String, String> {
        val id = call.argument<String>("appId")
            ?: throw IllegalArgumentException("appId is required")
        if (installedApps().none { it.packageName == id }) {
            throw IllegalArgumentException("Unsupported or uninstalled app")
        }
        val minutes = call.argument<Int>("dailyLimitMinutes")
            ?: throw IllegalArgumentException("dailyLimitMinutes is required")
        require(minutes in 1..1440) { "dailyLimitMinutes must be between 1 and 1440" }
        val enabled = call.argument<Boolean>("enabled") ?: false
        val hour = call.argument<Int>("resetHour") ?: 0
        val minute = call.argument<Int>("resetMinute") ?: 0
        require(hour in 0..23 && minute in 0..59) { "Invalid reset time" }
        getSharedPreferences(preferencesName, MODE_PRIVATE).edit()
            .putString(limitKey(id), encodeLimit(minutes, enabled, hour, minute))
            .apply()
        return mapOf(
            "state" to if (hasUsageAccess()) "unsupported" else "permissionRequired",
        )
    }

    private fun capabilities(): Map<String, Any> {
        val usageState = if (hasUsageAccess()) "supported" else "permissionRequired"
        return mapOf(
            "platform" to "Android",
            "authorization" to usageState,
            "capabilities" to listOf(
                capability("usageAccess", usageState),
                capability("appSelection", "supported"),
                capability("appBlocking", "unsupported"),
                capability("backgroundMonitoring", "unsupported"),
            ),
        )
    }

    private fun integrationStatus(): Map<String, Any> {
        val permission = if (hasUsageAccess()) "supported" else "permissionRequired"
        val selected = selectedApps()
        val selectedList = selected["apps"] as? List<*> ?: emptyList<Any>()
        return mapOf(
            "platform" to "Android",
            "authorization" to permission,
            "capabilities" to listOf(
                capability("usageAccess", permission),
                capability("appSelection", "supported"),
                capability("appBlocking", "unsupported"),
                capability("backgroundMonitoring", "unsupported"),
            ),
            "apps" to selectedList,
            "message" to "Usage Access reads app duration only; Android does not expose a consumer app-blocking API.",
        )
    }

    private fun capability(name: String, state: String) =
        mapOf("name" to name, "state" to state)

    private fun limitKey(id: String) = "limit.$id"
    private fun encodeLimit(
        minutes: Int,
        enabled: Boolean,
        hour: Int,
        minute: Int,
    ): String = "$minutes|$enabled|$hour|$minute"

    private fun decodeLimit(value: String?): Limit? {
        val parts = value?.split('|') ?: return null
        if (parts.size != 4) return null
        return try {
            Limit(
                minutes = parts[0].toInt(),
                enabled = parts[1].toBooleanStrict(),
                resetHour = parts[2].toInt(),
                resetMinute = parts[3].toInt(),
            )
        } catch (_: NumberFormatException) {
            null
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private data class SupportedApp(val packageName: String, val name: String)

    private data class Limit(
        val minutes: Int,
        val enabled: Boolean,
        val resetHour: Int,
        val resetMinute: Int,
    )

    private class UsageAccessRequiredException :
        Exception("Grant Usage Access to read actual app usage.")
}
