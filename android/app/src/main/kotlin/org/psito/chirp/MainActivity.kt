package org.psito.chirp

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

// A tela do Chirp. O motor do Flutter não é dela: fica guardado no processo
// (FlutterEngineCache), e o ReceiveService mantém o processo vivo. Assim, quando o
// Android fecha a tela (ou quem usa tira o app dos recentes), o Dart continua com o
// nó, os eventos e as notificações; ao abrir de novo, a tela se liga ao mesmo motor.
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine = engine(context)

    // O motor sobrevive à tela.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    // O pedido do microfone em andamento (a resposta vem no onRequestPermissionsResult).
    private var micAnswer: MethodChannel.Result? = null

    // O mesmo para as licenças do Bluetooth.
    private var bluetoothAnswer: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        current = WeakReference(this)
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
                    // Pela tela aberta agora (fraca: o motor dura mais que ela).
                    "askMicrophone" ->
                        current?.get()?.askMicrophone(result) ?: result.success(false)
                    "askBluetooth" ->
                        current?.get()?.askBluetooth(result) ?: result.success(false)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        if (current?.get() === this) current = null
        micAnswer?.success(false)
        micAnswer = null
        bluetoothAnswer?.success(false)
        bluetoothAnswer = null
        super.onDestroy()
    }

    // O microfone, para as notas de voz: o sistema pergunta uma vez.
    private fun askMicrophone(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (micAnswer != null) {
            result.success(false)
            return
        }
        micAnswer = result
        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), MIC_REQUEST)
    }

    // As licenças do Bluetooth (ChirpBle.permissions): o sistema pergunta ao ligar.
    private fun askBluetooth(result: MethodChannel.Result) {
        if (!ChirpBle.supported()) {
            result.success(false)
            return
        }
        if (ChirpBle.granted(this)) {
            result.success(true)
            return
        }
        if (bluetoothAnswer != null) {
            result.success(false)
            return
        }
        bluetoothAnswer = result
        requestPermissions(ChirpBle.permissions(), BLUETOOTH_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            MIC_REQUEST -> {
                micAnswer?.success(
                    grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
                )
                micAnswer = null
            }
            BLUETOOTH_REQUEST -> {
                bluetoothAnswer?.success(
                    grantResults.isNotEmpty() &&
                        grantResults.all { it == PackageManager.PERMISSION_GRANTED },
                )
                bluetoothAnswer = null
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
        private const val MIC_REQUEST = 7
        private const val BLUETOOTH_REQUEST = 8
        private var current: WeakReference<MainActivity>? = null

        fun engine(context: Context): FlutterEngine {
            val cache = FlutterEngineCache.getInstance()
            cache.get(ENGINE)?.let { return it }
            // Antes do Dart: o núcleo acha o rádio do app quando ligar a rede.
            ChirpBle.init(context)
            val engine = FlutterEngine(context.applicationContext)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
            )
            cache.put(ENGINE, engine)
            return engine
        }
    }
}
