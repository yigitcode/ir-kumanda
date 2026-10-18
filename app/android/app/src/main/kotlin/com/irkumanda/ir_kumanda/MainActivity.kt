package com.irkumanda.ir_kumanda

import android.hardware.ConsumerIrManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Bridges the Dart side to ConsumerIrManager. transmit() blocks for the whole burst, so it runs off the UI thread. */
class MainActivity : FlutterActivity() {
    private val irThread: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainThread = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ir = getSystemService(CONSUMER_IR_SERVICE) as? ConsumerIrManager
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ir_kumanda/ir").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasEmitter" -> result.success(ir?.hasIrEmitter() == true)
                "transmit" -> {
                    val frequency = call.argument<Int>("frequency")
                    val pattern = call.argument<IntArray>("pattern")
                    if (ir == null || frequency == null || pattern == null || pattern.isEmpty()) {
                        result.error("bad_request", "IR verici ya da desen yok", null)
                        return@setMethodCallHandler
                    }
                    irThread.execute {
                        try {
                            ir.transmit(frequency, pattern)
                            mainThread.post { result.success(null) }
                        } catch (e: Exception) {
                            mainThread.post { result.error("transmit_failed", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        irThread.shutdown()
        super.onDestroy()
    }
}
