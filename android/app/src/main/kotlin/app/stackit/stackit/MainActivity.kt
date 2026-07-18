package app.stackit.stackit

import android.content.Intent
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val logTag = "StackitCapture"
    private val channelName = "app.stackit/capture"
    private val preferencesName = "stackit_vocabulary"
    private var channel: MethodChannel? = null
    private var pendingSelection: Map<String, String?>? = null
    private var textToSpeech: TextToSpeech? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingSelection = captureFrom(intent) ?: loadPendingCapture()
        pendingSelection?.let(::storePendingCapture)
        super.onCreate(savedInstanceState)
        textToSpeech = TextToSpeech(this, this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also { bridge ->
            bridge.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeInitialSelection" -> {
                        val capture = pendingSelection ?: loadPendingCapture()
                        pendingSelection = null
                        clearStoredCapture()
                        result.success(capture)
                    }
                    "loadEntries" -> {
                        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
                        result.success(preferences.getString("entries", "[]"))
                    }
                    "saveEntries" -> {
                        val encoded = call.arguments as? String
                        if (encoded == null) {
                            result.error("invalid_entries", "Expected a JSON string", null)
                        } else {
                            getSharedPreferences(preferencesName, MODE_PRIVATE)
                                .edit()
                                .putString("entries", encoded)
                                .apply()
                            result.success(null)
                        }
                    }
                    "loadLanguagePair" -> {
                        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
                        result.success(preferences.getString("language_pair", null))
                    }
                    "saveLanguagePair" -> {
                        val pair = call.arguments as? String
                        if (pair.isNullOrBlank()) {
                            result.error("invalid_language_pair", "Expected a language-pair id", null)
                        } else {
                            getSharedPreferences(preferencesName, MODE_PRIVATE)
                                .edit()
                                .putString("language_pair", pair)
                                .apply()
                            result.success(null)
                        }
                    }
                    "loadPreferredTargetLanguage" -> {
                        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
                        result.success(preferences.getString("preferred_target_language", null))
                    }
                    "savePreferredTargetLanguage" -> {
                        val language = call.arguments as? String
                        if (language.isNullOrBlank()) {
                            result.error("invalid_target_language", "Expected a language code", null)
                        } else {
                            getSharedPreferences(preferencesName, MODE_PRIVATE)
                                .edit()
                                .putString("preferred_target_language", language)
                                .apply()
                            result.success(null)
                        }
                    }
                    "loadInterfaceLanguage" -> {
                        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
                        result.success(preferences.getString("interface_language", null))
                    }
                    "saveInterfaceLanguage" -> {
                        val language = call.arguments as? String
                        val editor = getSharedPreferences(preferencesName, MODE_PRIVATE).edit()
                        if (language.isNullOrBlank()) {
                            editor.remove("interface_language")
                        } else {
                            editor.putString("interface_language", language)
                        }
                        editor.apply()
                        result.success(null)
                    }
                    "loadReviewReminders" -> {
                        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
                        result.success(preferences.getBoolean("review_reminders", false))
                    }
                    "saveReviewReminders" -> {
                        val enabled = call.arguments as? Boolean
                        if (enabled == null) {
                            result.error("invalid_review_reminders", "Expected a boolean", null)
                        } else {
                            getSharedPreferences(preferencesName, MODE_PRIVATE)
                                .edit()
                                .putBoolean("review_reminders", enabled)
                                .apply()
                            result.success(null)
                        }
                    }
                    "loadUserProfile" -> {
                        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
                        result.success(preferences.getString("user_profile", null))
                    }
                    "saveUserProfile" -> {
                        val encoded = call.arguments as? String
                        if (encoded.isNullOrBlank()) {
                            result.error("invalid_user_profile", "Expected a JSON string", null)
                        } else {
                            getSharedPreferences(preferencesName, MODE_PRIVATE)
                                .edit()
                                .putString("user_profile", encoded)
                                .apply()
                            result.success(null)
                        }
                    }
                    "clearUserProfile" -> {
                        getSharedPreferences(preferencesName, MODE_PRIVATE)
                            .edit()
                            .remove("user_profile")
                            .apply()
                        result.success(null)
                    }
                    "speak" -> {
                        val arguments = call.arguments as? Map<*, *>
                        val text = arguments?.get("text") as? String
                        val localeTag = arguments?.get("localeTag") as? String
                        if (text.isNullOrBlank()) {
                            result.error("invalid_text", "Expected text to pronounce", null)
                        } else {
                            if (!localeTag.isNullOrBlank()) {
                                textToSpeech?.language = Locale.forLanguageTag(localeTag)
                            }
                            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "stackit-pronunciation")
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val capture = captureFrom(intent) ?: return
        pendingSelection = capture
        storePendingCapture(capture)
        deliverCapture(capture)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) textToSpeech?.language = Locale.US
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        super.onDestroy()
    }

    private fun captureFrom(intent: Intent?): Map<String, String?>? {
        val sourceIntent = intent ?: return null
        val selected = when (sourceIntent.action) {
            Intent.ACTION_PROCESS_TEXT -> sourceIntent
                .getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
                ?.toString()
                ?.trim()
            Intent.ACTION_SEND -> sourceIntent
                .getCharSequenceExtra(Intent.EXTRA_TEXT)
                ?.toString()
                ?.trim()
            else -> null
        }
        if (selected.isNullOrBlank()) return null
        return mapOf(
            "text" to selected,
            "source" to sourceIntent.getStringExtra(Intent.EXTRA_REFERRER_NAME),
        )
    }

    private fun deliverCapture(capture: Map<String, String?>) {
        val activeChannel = channel ?: return
        activeChannel.invokeMethod(
            "selectionReceived",
            capture,
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (pendingSelection == capture) {
                        pendingSelection = null
                        clearStoredCapture()
                    }
                    Log.d(logTag, "Capture acknowledged by Flutter")
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.w(logTag, "Flutter capture delivery failed: $errorCode $errorMessage")
                }

                override fun notImplemented() {
                    Log.w(logTag, "Flutter capture handler is not ready")
                }
            },
        )
    }

    private fun storePendingCapture(capture: Map<String, String?>) {
        getSharedPreferences(preferencesName, MODE_PRIVATE)
            .edit()
            .putString("pending_capture_text", capture["text"])
            .apply {
                val source = capture["source"]
                if (source.isNullOrBlank()) {
                    remove("pending_capture_source")
                } else {
                    putString("pending_capture_source", source)
                }
            }
            .apply()
    }

    private fun loadPendingCapture(): Map<String, String?>? {
        val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
        val text = preferences.getString("pending_capture_text", null)?.trim()
        if (text.isNullOrBlank()) return null
        return mapOf(
            "text" to text,
            "source" to preferences.getString("pending_capture_source", null),
        )
    }

    private fun clearStoredCapture() {
        getSharedPreferences(preferencesName, MODE_PRIVATE)
            .edit()
            .remove("pending_capture_text")
            .remove("pending_capture_source")
            .apply()
    }
}
