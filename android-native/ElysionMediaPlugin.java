package com.elysion.duo;

import android.content.ContentValues;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.OutputStream;

@CapacitorPlugin(name = "ElysionMedia")
public class ElysionMediaPlugin extends Plugin {
    private static ElysionMediaPlugin instance;

    @Override public void load() { instance = this; }

    public static void emitAction(String action) {
        if (instance != null) {
            JSObject data = new JSObject();
            data.put("action", action);
            instance.notifyListeners("mediaAction", data);
        }
    }

    public static void emitSeek(long posMs) {
        if (instance != null) {
            JSObject data = new JSObject();
            data.put("action", "seek");
            data.put("position", posMs);
            instance.notifyListeners("mediaAction", data);
        }
    }

    @PluginMethod
    public void updateState(PluginCall call) {
        Intent i = new Intent(getContext(), ElysionMediaService.class);
        i.putExtra("title", call.getString("title", "Elysion"));
        i.putExtra("artist", call.getString("artist", "Elysion"));
        i.putExtra("artwork", call.getString("artwork", ""));
        i.putExtra("isPlaying", call.getBoolean("isPlaying", false));
        i.putExtra("duration", (long) call.getInt("duration", 0));
        i.putExtra("position", (long) call.getInt("position", 0));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) getContext().startForegroundService(i);
        else getContext().startService(i);
        call.resolve();
    }

    @PluginMethod
    public void saveImage(PluginCall call) {
        String b64 = call.getString("base64", "");
        String filename = call.getString("filename", "elysion_quote_" + System.currentTimeMillis() + ".png");
        if (b64 == null || b64.isEmpty()) {
            call.reject("Empty image");
            return;
        }
        try {
            int comma = b64.indexOf(",");
            String pure = comma >= 0 ? b64.substring(comma + 1) : b64;
            byte[] bytes = Base64.decode(pure, Base64.DEFAULT);

            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, filename);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/png");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Elysion");
                values.put(MediaStore.Images.Media.IS_PENDING, 1);
            }
            Uri uri = getContext().getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                call.reject("MediaStore insert failed");
                return;
            }
            try (OutputStream os = getContext().getContentResolver().openOutputStream(uri)) {
                os.write(bytes);
                os.flush();
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ContentValues done = new ContentValues();
                done.put(MediaStore.Images.Media.IS_PENDING, 0);
                getContext().getContentResolver().update(uri, done, null, null);
            }
            JSObject ret = new JSObject();
            ret.put("saved", true);
            ret.put("uri", uri.toString());
            call.resolve(ret);
        } catch (Exception e) {
            call.reject("Save failed: " + e.getMessage());
        }
    }
}
