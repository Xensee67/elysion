package com.elysion.duo;

import android.content.Intent;
import android.os.Build;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

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
}
