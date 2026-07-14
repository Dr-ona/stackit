package app.stackit.stackit

import android.content.Intent
import android.os.Bundle
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val channelName = "app.stackit/capture"
    private val preferencesName = "stackit_vocabulary"
    private var channel: MethodChannel? = null
    private var pendingSelection: Map<String, String?>? = null
    private var textToSpeech: TextToSpeech? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingSelection = captureFrom(intent)
        super.onCreate(savedInstanceState)
        textToSpeech = TextToSpeech(this, this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also { bridge ->
            bridge.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeInitialSelection" -> {
                        result.success(pendingSelection)
                        pendingSelection = null
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
                    "speak" -> {
                        val text = call.arguments as? String
                        if (text.isNullOrBlank()) {
                            result.error("invalid_text", "Expected text to pronounce", null)
                        } else {
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
        val activeChannel = channel
        if (activeChannel == null) {
            pendingSelection = capture
        } else {
            activeChannel.invokeMethod("selectionReceived", capture)
        }
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
        if (intent?.action != Intent.ACTION_PROCESS_TEXT) return null
        val selected = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()?.trim()
        if (selected.isNullOrBlank()) return null
        return mapOf(
            "text" to selected,
            "source" to intent.getStringExtra(Intent.EXTRA_REFERRER_NAME),
        )
    }
}
