package org.psito.chirp

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

// A tela do Chirp. O motor do Flutter não é dela: fica guardado no processo
// (FlutterEngineCache), e o ReceiveService mantém o processo vivo. Assim, quando o
// Android fecha a tela (ou quem usa tira o app dos recentes), o Dart continua com o
// nó, os eventos e as notificações; ao abrir de novo, a tela se liga ao mesmo motor.
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine = engine(context)

    // O motor sobrevive à tela.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val app = applicationContext
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        ReceiveService.start(
                            app,
                            call.argument<String>("title") ?: "",
                            call.argument<String>("text") ?: "",
                            call.argument<String>("channel") ?: "",
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        ReceiveService.stop(app)
                        result.success(null)
                    }
                    "batteryRestricted" -> result.success(batteryRestricted(app))
                    "askUnrestrictedBattery" -> {
                        askUnrestrictedBattery(app)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun batteryRestricted(context: Context): Boolean {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return !power.isIgnoringBatteryOptimizations(context.packageName)
    }

    // O pedido do sistema para o Chirp ficar fora da economia de bateria (sem ele, o
    // Android pode atrasar a rede com o celular parado). Quem decide é quem usa. Pelo
    // contexto do app: o canal vive no motor, que dura mais que esta tela.
    private fun askUnrestrictedBattery(context: Context) {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(Uri.parse("package:${context.packageName}"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            context.startActivity(
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    companion object {
        private const val CHANNEL = "org.psito.chirp/background"
        private const val ENGINE = "chirp"

        fun engine(context: Context): FlutterEngine {
            val cache = FlutterEngineCache.getInstance()
            cache.get(ENGINE)?.let { return it }
            val engine = FlutterEngine(context.applicationContext)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
            )
            cache.put(ENGINE, engine)
            return engine
        }
    }
}
