package news.afisha.mysterioussanta

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mysterioussanta/clipboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "copyImage") {
                val imageBytes = call.argument<ByteArray>("image")
                if (imageBytes != null) {
                    val success = copyImageToClipboard(imageBytes)
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("COPY_FAILED", "Failed to copy image to clipboard", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Image bytes are null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun copyImageToClipboard(imageBytes: ByteArray): Boolean {
        return try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            
            // Сохраняем изображение во временный файл
            val cacheDir = applicationContext.cacheDir
            val imageFile = File(cacheDir, "qr_code_${System.currentTimeMillis()}.png")
            FileOutputStream(imageFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            
            // Создаем URI для файла
            val imageUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    applicationContext,
                    "${applicationContext.packageName}.fileprovider",
                    imageFile
                )
            } else {
                Uri.fromFile(imageFile)
            }
            
            // Копируем в буфер обмена
            val clipData = ClipData.newUri(contentResolver, "QR Code", imageUri)
            clipboard.setPrimaryClip(clipData)
            
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}

