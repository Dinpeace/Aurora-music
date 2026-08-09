package com.example.aurora_music

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "aurora_music/media"
        private const val REQUEST_PERMISSION = 1001
    }

    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "requestPermission" -> {
                    requestPermission(result)
                }

                "getSongs" -> {
                    result.success(getSongs())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {

        val permission =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Manifest.permission.READ_MEDIA_AUDIO
            } else {
                Manifest.permission.READ_EXTERNAL_STORAGE
            }

        if (
            ContextCompat.checkSelfPermission(
                this,
                permission
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        permissionResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(permission),
            REQUEST_PERMISSION
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        if (requestCode == REQUEST_PERMISSION) {
            permissionResult?.success(
                grantResults.isNotEmpty() &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED
            )

            permissionResult = null
        }
    }

    private fun getSongs(): List<HashMap<String, Any>> {

        val songs = mutableListOf<HashMap<String, Any>>()
        val scannedPaths = mutableSetOf<String>()

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA
        )

        val selection =
            "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        val sortOrder =
            "${MediaStore.Audio.Media.TITLE} ASC"

        val cursor = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder
        )

        cursor?.use { c ->

            val idColumn =
                c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)

            val titleColumn =
                c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)

            val artistColumn =
                c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)

            val albumColumn =
                c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)

            val albumIdColumn =
                c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

            val durationColumn =
                c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            val pathColumn =
                c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

            while (c.moveToNext()) {

                val path =
                    c.getString(pathColumn) ?: ""

                if (path.isBlank()) {
                    continue
                }

                if (!scannedPaths.add(path)) {
                    continue
                }

                val lowerPath = path.lowercase()

                if (
                    lowerPath.contains("record") ||
                    lowerPath.contains("recording") ||
                    lowerPath.contains("call") ||
                    lowerPath.contains("notification") ||
                    lowerPath.contains("ringtone") ||
                    lowerPath.contains("alarm")
                ) {
                    continue
                }

                val id =
                    c.getLong(idColumn)

                val title =
                    c.getString(titleColumn)?.takeIf {
                        it.isNotBlank()
                    } ?: "Unknown Title"

                val artist =
                    c.getString(artistColumn)?.takeIf {
                        it.isNotBlank() &&
                                it != "<unknown>"
                    } ?: "Unknown Artist"

                val album =
                    c.getString(albumColumn)?.takeIf {
                        it.isNotBlank()
                    } ?: "Unknown Album"

                val albumId =
                    c.getLong(albumIdColumn)

                val duration =
                    c.getLong(durationColumn)

                val artwork =
                    "content://media/external/audio/albumart/$albumId"

                val song = hashMapOf<String, Any>()

                song["id"] = id
                song["title"] = title
                song["artist"] = artist
                song["album"] = album
                song["duration"] = duration
                song["artwork"] = artwork
                song["path"] = path

                songs.add(song)
            }
        }

        return songs
    }
}