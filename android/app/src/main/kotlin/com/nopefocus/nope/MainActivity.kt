package com.nopefocus.nope

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.net.Uri
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.nopefocus.nope/protection"
        private const val PREFS = "nope_focus"
        private const val LATEST_RELEASE_URL =
            "https://api.github.com/repos/ChaiGmzR/NOPE/releases/latest"
        private val AUTHENTICATOR_PACKAGES = listOf(
            "com.google.android.apps.authenticator2",
            "com.azure.authenticator",
            "com.authy.authy",
            "com.twofasapp",
            "com.beemdevelopment.aegis",
            "com.bitwarden.authenticator",
            "com.duosecurity.duomobile",
            "com.okta.android.auth",
            "org.fedorahosted.freeotp",
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "accessibilityEnabled" -> result.success(isProtectionEnabled())
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "syncProtectionState" -> {
                        val preferences = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                        preferences.edit()
                            .putLong("activeUntil", call.argument<Number>("activeUntil")?.toLong() ?: 0L)
                            .putLong("pausedUntil", call.argument<Number>("pausedUntil")?.toLong() ?: 0L)
                            .putString("schedulesJson", call.argument<String>("schedulesJson") ?: "[]")
                            .apply()
                        result.success(null)
                    }
                    "launchEssential" -> {
                        result.success(launchEssential(call.argument<String>("target") ?: ""))
                    }
                    "isEssentialAvailable" -> {
                        val target = call.argument<String>("target") ?: ""
                        result.success(
                            target != "authenticator" || findAuthenticatorIntent() != null,
                        )
                    }
                    "checkForUpdate" -> checkForUpdate(result)
                    "downloadAndInstallUpdate" -> downloadAndInstallUpdate(
                        call.argument<String>("downloadUrl") ?: "",
                        call.argument<String>("version") ?: "",
                        call.argument<String>("digest") ?: "",
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun isProtectionEnabled(): Boolean {
        val manager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        return manager
            .getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.resolveInfo.serviceInfo.packageName == packageName }
    }

    private fun launchEssential(target: String): Boolean {
        val intent = when (target) {
            "phone" -> Intent(Intent.ACTION_DIAL)
            "sms" -> Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:"))
            "whatsapp" -> packageManager.getLaunchIntentForPackage("com.whatsapp")
                ?: packageManager.getLaunchIntentForPackage("com.whatsapp.w4b")
            "authenticator" -> findAuthenticatorIntent()
            else -> null
        } ?: return false

        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun findAuthenticatorIntent(): Intent? {
        for (authenticatorPackage in AUTHENTICATOR_PACKAGES) {
            packageManager.getLaunchIntentForPackage(authenticatorPackage)?.let { return it }
        }
        return null
    }

    private fun checkForUpdate(result: MethodChannel.Result) {
        thread(name = "nope-update-check") {
            val response = try {
                val connection = (URL(LATEST_RELEASE_URL).openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 8_000
                    readTimeout = 8_000
                    setRequestProperty("Accept", "application/vnd.github+json")
                    setRequestProperty("X-GitHub-Api-Version", "2022-11-28")
                    setRequestProperty("User-Agent", "NOPE-Android/$appVersion")
                }
                if (connection.responseCode == HttpURLConnection.HTTP_NOT_FOUND) {
                    connection.disconnect()
                    noUpdateResponse()
                } else {
                    if (connection.responseCode !in 200..299) {
                        throw IllegalStateException("GitHub HTTP ${connection.responseCode}")
                    }
                    val body = connection.inputStream.bufferedReader().use { it.readText() }
                    connection.disconnect()
                    parseRelease(JSONObject(body))
                }
            } catch (_: Exception) {
                noUpdateResponse()
            }
            runOnUiThread { result.success(response) }
        }
    }

    private fun parseRelease(release: JSONObject): Map<String, Any?> {
        val current = appVersion
        val latest = release.optString("tag_name").trimStart('v', 'V')
        val assets = release.optJSONArray("assets")
        var apk: JSONObject? = null
        if (assets != null) {
            for (index in 0 until assets.length()) {
                val candidate = assets.optJSONObject(index) ?: continue
                if (candidate.optString("name").endsWith(".apk", ignoreCase = true)) {
                    apk = candidate
                    break
                }
            }
        }
        val downloadUrl = apk?.optString("browser_download_url").orEmpty()
        return mapOf(
            "available" to (isNewer(latest, current) && downloadUrl.isNotBlank()),
            "currentVersion" to current,
            "latestVersion" to latest,
            "downloadUrl" to downloadUrl,
            "notes" to release.optString("body").take(1_600),
            "digest" to apk?.optString("digest").orEmpty(),
        )
    }

    private fun noUpdateResponse(): Map<String, Any?> = mapOf(
        "available" to false,
        "currentVersion" to appVersion,
    )

    private fun isNewer(candidate: String, current: String): Boolean {
        fun parts(value: String): List<Int> = value
            .trimStart('v', 'V')
            .substringBefore('-')
            .substringBefore('+')
            .split('.')
            .map { it.toIntOrNull() ?: 0 }

        val candidateParts = parts(candidate)
        val currentParts = parts(current)
        val size = maxOf(candidateParts.size, currentParts.size, 3)
        for (index in 0 until size) {
            val left = candidateParts.getOrElse(index) { 0 }
            val right = currentParts.getOrElse(index) { 0 }
            if (left != right) return left > right
        }
        return false
    }

    private fun downloadAndInstallUpdate(
        downloadUrl: String,
        version: String,
        expectedDigest: String,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ),
            )
            result.success(mapOf("status" to "needsPermission"))
            return
        }

        val uri = Uri.parse(downloadUrl)
        val host = uri.host.orEmpty().lowercase()
        val trustedHost = host == "github.com" ||
            host.endsWith(".github.com") ||
            host.endsWith(".githubusercontent.com")
        if (uri.scheme != "https" || !trustedHost) {
            result.success(mapOf("status" to "failed"))
            return
        }

        thread(name = "nope-update-download") {
            try {
                val safeVersion = version.replace(Regex("[^0-9A-Za-z._-]"), "_")
                val updateDirectory = File(cacheDir, "updates").apply { mkdirs() }
                val apkFile = File(updateDirectory, "NOPE-$safeVersion.apk")
                if (apkFile.exists()) apkFile.delete()

                val connection = (URL(downloadUrl).openConnection() as HttpURLConnection).apply {
                    instanceFollowRedirects = true
                    connectTimeout = 15_000
                    readTimeout = 120_000
                    setRequestProperty("Accept", "application/octet-stream")
                    setRequestProperty("User-Agent", "NOPE-Android/$appVersion")
                }
                if (connection.responseCode !in 200..299) {
                    throw IllegalStateException("Download HTTP ${connection.responseCode}")
                }

                val digest = MessageDigest.getInstance("SHA-256")
                connection.inputStream.use { input ->
                    apkFile.outputStream().buffered().use { output ->
                        val buffer = ByteArray(64 * 1024)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            digest.update(buffer, 0, count)
                            output.write(buffer, 0, count)
                        }
                    }
                }
                connection.disconnect()

                val actualDigest = digest.digest().joinToString("") { "%02x".format(it) }
                val expected = expectedDigest
                    .removePrefix("sha256:")
                    .trim()
                    .lowercase()
                if (expected.isNotEmpty() && expected != actualDigest) {
                    apkFile.delete()
                    throw SecurityException("Update digest mismatch")
                }

                runOnUiThread {
                    try {
                        val contentUri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            apkFile,
                        )
                        val installIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(
                                contentUri,
                                "application/vnd.android.package-archive",
                            )
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(installIntent)
                        result.success(mapOf("status" to "installerStarted"))
                    } catch (_: Exception) {
                        result.success(mapOf("status" to "failed"))
                    }
                }
            } catch (_: Exception) {
                runOnUiThread { result.success(mapOf("status" to "failed")) }
            }
        }
    }

    @Suppress("DEPRECATION")
    private val appVersion: String
        get() = packageManager.getPackageInfo(packageName, 0).versionName ?: "0.2.0"
}
