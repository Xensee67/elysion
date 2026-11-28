package com.elysion.duo;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.widget.RemoteViews;

public class ElysionWidgetProvider extends AppWidgetProvider {
    public static final String ACTION_WIDGET_PREV = "com.elysion.duo.WIDGET_PREV";
    public static final String ACTION_WIDGET_TOGGLE = "com.elysion.duo.WIDGET_TOGGLE";
    public static final String ACTION_WIDGET_NEXT = "com.elysion.duo.WIDGET_NEXT";

    private static String lastTitle = "Elysion";
    private static String lastArtist = "Наша музыка вдвоём";
    private static boolean lastPlaying = false;
    private static Bitmap lastArt = null;

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int id : appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context));
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        String act = intent != null ? intent.getAction() : null;
        if (ACTION_WIDGET_PREV.equals(act)) {
            ElysionMediaPlugin.emitAction("prev");
        } else if (ACTION_WIDGET_TOGGLE.equals(act)) {
            ElysionMediaPlugin.emitAction(lastPlaying ? "pause" : "play");
        } else if (ACTION_WIDGET_NEXT.equals(act)) {
            ElysionMediaPlugin.emitAction("next");
        }
    }

    public static void updateAll(Context context, String title, String artist, boolean playing, Bitmap art) {
        lastTitle = (title != null && !title.isEmpty()) ? title : "Elysion";
        lastArtist = (artist != null && !artist.isEmpty()) ? artist : "Elysion";
        lastPlaying = playing;
        if (art != null) lastArt = art;
        try {
            AppWidgetManager mgr = AppWidgetManager.getInstance(context);
            int[] ids = mgr.getAppWidgetIds(new ComponentName(context, ElysionWidgetProvider.class));
            if (ids != null && ids.length > 0) {
                RemoteViews rv = buildViews(context);
                for (int id : ids) mgr.updateAppWidget(id, rv);
            }
        } catch (Exception ignored) {}
    }

    private static RemoteViews buildViews(Context context) {
        RemoteViews rv = new RemoteViews(context.getPackageName(), R.layout.elysion_widget);
        rv.setTextViewText(R.id.widget_title, lastTitle);
        rv.setTextViewText(R.id.widget_artist, lastArtist);
        rv.setImageViewResource(R.id.widget_btn_play, lastPlaying ? android.R.drawable.ic_media_pause : android.R.drawable.ic_media_play);
        if (lastArt != null) {
            rv.setImageViewBitmap(R.id.widget_cover, lastArt);
        } else {
            rv.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher);
        }

        Intent openIntent = new Intent(context, MainActivity.class);
        openIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent openPi = PendingIntent.getActivity(context, 10, openIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        rv.setOnClickPendingIntent(R.id.widget_root, openPi);

        rv.setOnClickPendingIntent(R.id.widget_btn_prev, makeActionPi(context, ACTION_WIDGET_PREV, 11));
        rv.setOnClickPendingIntent(R.id.widget_btn_play, makeActionPi(context, ACTION_WIDGET_TOGGLE, 12));
        rv.setOnClickPendingIntent(R.id.widget_btn_next, makeActionPi(context, ACTION_WIDGET_NEXT, 13));
        return rv;
    }

    private static PendingIntent makeActionPi(Context context, String action, int reqCode) {
        Intent i = new Intent(context, ElysionWidgetProvider.class);
        i.setAction(action);
        return PendingIntent.getBroadcast(context, reqCode, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }
}
