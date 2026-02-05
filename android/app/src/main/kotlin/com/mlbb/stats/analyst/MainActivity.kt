package com.mlbb.stats.analyst

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.File
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths

class MainActivity: FlutterActivity(), Shizuku.OnRequestPermissionResultListener {
    private val CHANNEL = "com.mlbb.stats.analyst/saf"
    private val REQUEST_CODE_OPEN_DIRECTORY = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var shizukuPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Shizuku.addRequestPermissionResultListener(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // --- SAF METHODS ---
                "openDocumentTree" -> {
                    pendingResult = result
                    val initialUri = call.argument<String>("initialUri")
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    if (initialUri != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse(initialUri))
                    }
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    startActivityForResult(intent, REQUEST_CODE_OPEN_DIRECTORY)
                }
                "listFiles" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr == null) result.error("INVALID_URI", "URI is null", null)
                    else listFilesSaf(Uri.parse(uriStr), result)
                }
                "readFile" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr == null) result.error("INVALID_URI", "URI is null", null)
                    else readFileSaf(Uri.parse(uriStr), result)
                }
                
                // --- NATIVE FILE METHODS (All Files Access) ---
                "requestAllFilesAccess" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        if (!Environment.isExternalStorageManager()) {
                            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                            intent.data = Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(false) 
                        } else result.success(true) 
                    } else result.success(true) 
                }
                "checkAllFilesAccess" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(Environment.isExternalStorageManager())
                    } else result.success(true)
                }
                "listNativeDirectory" -> {
                    val path = call.argument<String>("path")
                    if (path != null) listNativeDirectory(path, result) else result.error("ERR", "Path null", null)
                }

                // --- SHIZUKU METHODS ---
                "checkShizukuAvailable" -> {
                    try {
                        if (Shizuku.pingBinder()) {
                            if (checkShizukuPermission()) result.success("GRANTED") else result.success("DENIED")
                        } else result.success("UNAVAILABLE")
                    } catch (e: Exception) {
                        result.success("ERROR") 
                    }
                }
                "requestShizukuPermission" -> {
                    try {
                        if (checkShizukuPermission()) {
                            result.success(true)
                        } else {
                            shizukuPermissionResult = result
                            Shizuku.requestPermission(0)
                        }
                    } catch (e: Exception) {
                        result.error("SHIZUKU_ERR", e.message, null)
                    }
                }
                "shizukuShell" -> {
                    val cmd = call.argument<String>("cmd")
                    if (cmd != null) executeShizukuShell(cmd, result) else result.error("ERR", "Cmd null", null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun checkShizukuPermission(): Boolean {
        return try {
            Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
        } catch (e: Throwable) {
            false
        }
    }

    override fun onRequestPermissionResult(requestCode: Int, grantResult: Int) {
        if (shizukuPermissionResult != null) {
            if (grantResult == PackageManager.PERMISSION_GRANTED) {
                shizukuPermissionResult?.success(true)
            } else {
                shizukuPermissionResult?.success(false)
            }
            shizukuPermissionResult = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Shizuku.removeRequestPermissionResultListener(this)
    }

    private fun executeShizukuShell(command: String, result: MethodChannel.Result) {
        Thread {
            try {
                // Use newProcess if possible, otherwise rely on ShizukuProvider
                val process = Shizuku.newProcess(arrayOf("sh", "-c", command), null, null)
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                val sb = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    sb.append(line).append("\n")
                }
                process.waitFor() 
                
                if (process.exitValue() == 0) {
                    runOnUiThread { result.success(sb.toString()) }
                } else {
                    val errorReader = BufferedReader(InputStreamReader(process.errorStream))
                    val sbErr = StringBuilder()
                    while (errorReader.readLine().also { line = it } != null) {
                        sbErr.append(line).append("\n")
                    }
                    runOnUiThread { result.error("SHELL_EXIT_".plus(process.exitValue()), sbErr.toString(), null) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("SHIZUKU_EX", e.message, null) }
            }
        }.start()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_OPEN_DIRECTORY) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    try {
                        contentResolver.takePersistableUriPermission(
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        )
                    } catch (e: SecurityException) {}
                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.error("URI_NULL", "Uri is null", null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun listFilesSaf(uri: Uri, result: MethodChannel.Result) {
        Thread {
            try {
                val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                    uri,
                    DocumentsContract.getTreeDocumentId(uri)
                )
                val files = mutableListOf<Map<String, Any>>()
                val projection = arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                    DocumentsContract.Document.COLUMN_MIME_TYPE
                )
                val cursor = contentResolver.query(childrenUri, projection, null, null, null)
                cursor?.use {
                    while (it.moveToNext()) {
                        val docId = it.getString(0)
                        val name = it.getString(1)
                        val lastModified = it.getLong(2)
                        val fileUri = DocumentsContract.buildDocumentUriUsingTree(uri, docId)
                        files.add(mapOf("uri" to fileUri.toString(), "name" to name, "lastModified" to lastModified))
                    }
                }
                runOnUiThread { result.success(files) }
            } catch (e: Exception) {
                runOnUiThread { result.error("LIST_ERROR", e.message, null) }
            }
        }.start()
    }

    private fun readFileSaf(uri: Uri, result: MethodChannel.Result) {
        Thread {
            try {
                val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                if (bytes != null) {
                    runOnUiThread { result.success(bytes) }
                } else {
                    runOnUiThread { result.error("READ_ERROR", "Stream null", null) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("READ_ERROR", e.message, null) }
            }
        }.start()
    }

    // Native Java IO Implementation (NIO.2)
    private fun listNativeDirectory(path: String, result: MethodChannel.Result) {
        Thread {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val dirPath = Paths.get(path)
                    if (!Files.exists(dirPath)) {
                        runOnUiThread { result.error("DIR_ERROR", "Path does not exist: $path", null) }
                        return@Thread
                    }
                    
                    val files = mutableListOf<Map<String, Any>>()
                    try {
                        Files.newDirectoryStream(dirPath).use { stream ->
                            stream.forEach { entry ->
                                val file = entry.toFile()
                                files.add(mapOf(
                                    "path" to file.absolutePath,
                                    "name" to file.name,
                                    "lastModified" to file.lastModified()
                                ))
                            }
                        }
                        runOnUiThread { result.success(files) }
                    } catch (e: IOException) {
                        runOnUiThread { result.error("ACCESS_DENIED", "NIO: ".plus(e.message), null) }
                    }
                } else {
                    val directory = File(path)
                    val list = directory.listFiles()
                    if (list == null) {
                        runOnUiThread { result.error("ACCESS_DENIED", "Legacy: Access denied", null) }
                    } else {
                        val mapped = list.map { file ->
                            mapOf("path" to file.absolutePath, "name" to file.name, "lastModified" to file.lastModified())
                        }
                        runOnUiThread { result.success(mapped) }
                    }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("NATIVE_ERROR", e.message, null) }
            }
        }.start()
    }
}