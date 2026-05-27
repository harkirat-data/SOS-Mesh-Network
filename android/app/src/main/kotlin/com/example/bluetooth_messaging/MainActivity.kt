package com.example.bluetooth_messaging

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bluetooth_messaging/ble_advertiser"
    private var advertiser: BluetoothLeAdvertiser? = null
    private var currentCallback: AdvertiseCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdvertising" -> {
                    val serviceUuid = call.argument<String>("serviceUuid") ?: ""
                    val payload = call.argument<ByteArray>("payload") ?: byteArrayOf()
                    startAdvertising(serviceUuid, payload, result)
                }
                "stopAdvertising" -> {
                    stopAdvertising(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startAdvertising(serviceUuid: String, payload: ByteArray, result: MethodChannel.Result) {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter: BluetoothAdapter? = bluetoothManager.adapter

        if (adapter == null || !adapter.isEnabled) {
            result.error("BT_OFF", "Bluetooth is not enabled", null)
            return
        }

        advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            result.error("NO_ADVERTISER", "BLE Advertising is not supported on this device", null)
            return
        }

        // Stop any previous advertising
        currentCallback?.let { advertiser?.stopAdvertising(it) }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .build()

        val uuid = ParcelUuid(UUID.fromString(serviceUuid))

        // BLE advertisement payload is limited to ~31 bytes.
        // We put the service UUID in the advert and the actual data in scan response.
        val advertiseData = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addServiceUuid(uuid)
            .build()

        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addManufacturerData(0xFFFF, payload)
            .build()

        currentCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                result.success(true)
            }

            override fun onStartFailure(errorCode: Int) {
                result.error("ADV_FAIL", "Advertising failed with error code: $errorCode", null)
            }
        }

        advertiser?.startAdvertising(settings, advertiseData, scanResponse, currentCallback)
    }

    private fun stopAdvertising(result: MethodChannel.Result) {
        currentCallback?.let { advertiser?.stopAdvertising(it) }
        currentCallback = null
        result.success(true)
    }
}
