package org.psito.chirp

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread

// O rádio Bluetooth do Chirp no Android (fase 8): o núcleo em Rust chama estes métodos
// pelo JNI (core/chirp-core/src/ble/android.rs) e recebe os avisos pelos `external`.
// Aqui só se anuncia, procura e abre canais L2CAP; o que passa por eles já vai cifrado
// (o Noise do núcleo), e nada é guardado nem registrado no log.
object ChirpBle {
    // O mesmo do núcleo (ble::SERVICE_UUID).
    private val SERVICE: ParcelUuid =
        ParcelUuid(UUID.fromString("3200ffb9-0d62-480b-bc00-63ec5fe3365c"))

    private var context: Context? = null
    private var server: BluetoothServerSocket? = null
    private var advertising: AdvertiseCallback? = null
    private var scanning: ScanCallback? = null
    private val sockets = ConcurrentHashMap<Int, BluetoothSocket>()
    private val seen = ConcurrentHashMap<String, BluetoothDevice>()
    private val nextId = AtomicInteger(1)

    // Liga o núcleo a esta classe. A biblioteca é a mesma que o Dart abre.
    fun init(context: Context) {
        if (this.context != null) return
        this.context = context.applicationContext
        try {
            System.loadLibrary("chirp_core")
            nativeInit()
        } catch (_: Throwable) {
            // Sem a biblioteca, o núcleo também não abre: nada a fazer.
        }
    }

    @JvmStatic private external fun nativeInit()

    @JvmStatic private external fun onIncoming(id: Int)

    @JvmStatic private external fun onSighting(address: String, data: ByteArray)

    // As licenças que o Chirp pede para o Bluetooth: no Android 12 ou mais novo, as do
    // Bluetooth (sem localização); no 10 e no 11, a localização, que é o que o sistema
    // exige para procurar.
    fun permissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
            )
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    fun granted(context: Context): Boolean =
        permissions().all {
            context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
        }

    // O canal L2CAP sem pareamento é do Android 10.
    fun supported(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    private fun adapter(): BluetoothAdapter? =
        context?.getSystemService(BluetoothManager::class.java)?.adapter

    @JvmStatic
    @SuppressLint("MissingPermission")
    fun available(): Boolean {
        val context = context ?: return false
        if (!supported() || !granted(context)) return false
        val adapter = adapter() ?: return false
        return try {
            adapter.isEnabled && adapter.bluetoothLeAdvertiser != null &&
                adapter.bluetoothLeScanner != null
        } catch (_: SecurityException) {
            false
        }
    }

    @JvmStatic
    @SuppressLint("MissingPermission", "NewApi")
    fun listen(): Int {
        if (!available()) return -1
        return try {
            server?.close()
            val socket = adapter()!!.listenUsingInsecureL2capChannel()
            server = socket
            thread(name = "chirp-ble-accept", isDaemon = true) {
                while (true) {
                    val accepted =
                        try {
                            socket.accept()
                        } catch (_: Exception) {
                            break
                        }
                    onIncoming(keep(accepted))
                }
            }
            socket.psm
        } catch (_: Exception) {
            -1
        }
    }

    @JvmStatic
    @SuppressLint("MissingPermission")
    fun advertise(data: ByteArray): Boolean {
        val advertiser = adapter()?.bluetoothLeAdvertiser ?: return false
        return try {
            advertising?.let { advertiser.stopAdvertising(it) }
            // Conectável (para o outro abrir o canal), sem nome nem potência: só os dados
            // de serviço, como no Linux. As flags e os dados enchem os 31 bytes.
            val settings =
                AdvertiseSettings.Builder()
                    .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
                    .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                    .setConnectable(true)
                    .setTimeout(0)
                    .build()
            val advert =
                AdvertiseData.Builder()
                    .setIncludeDeviceName(false)
                    .setIncludeTxPowerLevel(false)
                    .addServiceData(SERVICE, data)
                    .build()
            val callback = object : AdvertiseCallback() {}
            advertising = callback
            advertiser.startAdvertising(settings, advert, callback)
            true
        } catch (_: Exception) {
            false
        }
    }

    @JvmStatic
    @SuppressLint("MissingPermission")
    fun scan(): Boolean {
        val scanner = adapter()?.bluetoothLeScanner ?: return false
        return try {
            scanning?.let { scanner.stopScan(it) }
            val callback =
                object : ScanCallback() {
                    override fun onScanResult(callbackType: Int, result: ScanResult) {
                        val data = result.scanRecord?.getServiceData(SERVICE) ?: return
                        val address = result.device.address
                        seen[address] = result.device
                        onSighting(address, data)
                    }

                    override fun onBatchScanResults(results: MutableList<ScanResult>) {
                        results.forEach { onScanResult(0, it) }
                    }
                }
            scanning = callback
            // O filtro pelo serviço deixa a busca seguir com a tela apagada.
            val filter =
                ScanFilter.Builder().setServiceData(SERVICE, ByteArray(0)).build()
            val settings =
                ScanSettings.Builder()
                    .setScanMode(ScanSettings.SCAN_MODE_BALANCED)
                    .build()
            scanner.startScan(listOf(filter), settings, callback)
            true
        } catch (_: Exception) {
            false
        }
    }

    // Bloqueia até o outro aceitar. O aparelho é o visto na busca (com o tipo de
    // endereço certo); o número do soquete, ou -1.
    @JvmStatic
    @SuppressLint("MissingPermission", "NewApi")
    fun connect(address: String, psm: Int): Int {
        val device = seen[address] ?: return -1
        return try {
            val socket = device.createInsecureL2capChannel(psm)
            socket.connect()
            keep(socket)
        } catch (_: Exception) {
            -1
        }
    }

    @JvmStatic
    fun read(id: Int, buffer: ByteArray): Int {
        val socket = sockets[id] ?: return -1
        return try {
            socket.inputStream.read(buffer)
        } catch (_: Exception) {
            -1
        }
    }

    @JvmStatic
    fun write(id: Int, data: ByteArray): Boolean {
        val socket = sockets[id] ?: return false
        return try {
            socket.outputStream.write(data)
            socket.outputStream.flush()
            true
        } catch (_: Exception) {
            false
        }
    }

    @JvmStatic
    fun close(id: Int) {
        try {
            sockets.remove(id)?.close()
        } catch (_: Exception) {
        }
    }

    @JvmStatic
    @SuppressLint("MissingPermission")
    fun stop() {
        val adapter = adapter()
        try {
            advertising?.let { adapter?.bluetoothLeAdvertiser?.stopAdvertising(it) }
            scanning?.let { adapter?.bluetoothLeScanner?.stopScan(it) }
        } catch (_: Exception) {
        }
        advertising = null
        scanning = null
        try {
            server?.close()
        } catch (_: Exception) {
        }
        server = null
        sockets.keys.forEach { close(it) }
        seen.clear()
    }

    private fun keep(socket: BluetoothSocket): Int {
        val id = nextId.getAndIncrement()
        sockets[id] = socket
        return id
    }
}
