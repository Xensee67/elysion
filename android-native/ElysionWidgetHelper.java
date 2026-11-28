package com.elysion.duo;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapShader;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Shader;
import android.widget.RemoteViews;

public class ElysionWidgetHelper {
    public static final String ACTION_WIDGET_PREV = "com.elysion.duo.WIDGET_PREV";
    public static final String ACTION_WIDGET_TOGGLE = "com.elysion.duo.WIDGET_TOGGLE";
    public static final String ACTION_WIDGET_NEXT = "com.elysion.duo.WIDGET_NEXT";
    public static final String ACTION_WIDGET_LIKE = "com.elysion.duo.WIDGET_LIKE";

    private static String lastTitle = "Elysion";
    private static String lastArtist = "Наша музыка вдвоём";
    private static boolean lastPlaying = false;
    private static boolean lastLiked = false;
    private static Bitmap lastArt = null;
    private static String lastWidgetSignature = "";
    private static Bitmap cachedArtRef = null;
    private static Bitmap cachedCompactBg = null;
    private static Bitmap cachedLargeBg = null;
    private static Bitmap cachedCompactCover = null;
    private static Bitmap cachedLargeCover = null;
    private static Bitmap cachedSquareCover = null;

    public static void handleAction(Context context, String act) {
        if (ACTION_WIDGET_PREV.equals(act)) {
            ElysionMediaPlugin.emitAction("prev");
        } else if (ACTION_WIDGET_TOGGLE.equals(act)) {
            ElysionMediaPlugin.emitAction(lastPlaying ? "pause" : "play");
        } else if (ACTION_WIDGET_NEXT.equals(act)) {
            ElysionMediaPlugin.emitAction("next");
        } else if (ACTION_WIDGET_LIKE.equals(act)) {
            lastLiked = !lastLiked;
            ElysionMediaPlugin.emitAction("like");
            refreshAllProviders(context);
        }
    }

    public static void updateAll(Context context, String title, String artist, boolean playing, boolean liked, Bitmap art) {
        String normTitle = (title != null && !title.isEmpty()) ? title : "Elysion";
        String normArtist = (artist != null && !artist.isEmpty()) ? artist : "Наша музыка вдвоём";
        Bitmap effectiveArt = (art != null) ? art : lastArt;
        int artId = (effectiveArt != null) ? System.identityHashCode(effectiveArt) : 0;
        String sig = normTitle + "|" + normArtist + "|" + playing + "|" + liked + "|" + artId;
        if (sig.equals(lastWidgetSignature)) return;
        lastWidgetSignature = sig;
        lastTitle = normTitle;
        lastArtist = normArtist;
        lastPlaying = playing;
        lastLiked = liked;
        if (art != null && art != cachedArtRef) {
            lastArt = art;
            cachedArtRef = art;
            cachedCompactBg = makeAdaptiveBgBitmap(art, 520, 150, 44);
            cachedLargeBg = makeAdaptiveBgBitmap(art, 520, 290, 48);
            cachedCompactCover = makeRoundedBitmap(art, 144, 28);
            cachedLargeCover = makeRoundedBitmap(art, 180, 34);
            cachedSquareCover = makeRoundedBitmap(art, 320, 48);
        }
        refreshAllProviders(context);
    }

    public static void refreshAllProviders(Context context) {
        try {
            AppWidgetManager mgr = AppWidgetManager.getInstance(context);
            int[] ids1 = mgr.getAppWidgetIds(new ComponentName(context, ElysionWidgetProvider.class));
            if (ids1 != null && ids1.length > 0) {
                RemoteViews rv1 = buildCompactViews(context);
                for (int id : ids1) mgr.updateAppWidget(id, rv1);
            }
            int[] ids2 = mgr.getAppWidgetIds(new ComponentName(context, ElysionWidgetLargeProvider.class));
            if (ids2 != null && ids2.length > 0) {
                RemoteViews rv2 = buildLargeViews(context);
                for (int id : ids2) mgr.updateAppWidget(id, rv2);
            }
            int[] ids3 = mgr.getAppWidgetIds(new ComponentName(context, ElysionWidgetSquareProvider.class));
            if (ids3 != null && ids3.length > 0) {
                RemoteViews rv3 = buildSquareViews(context);
                for (int id : ids3) mgr.updateAppWidget(id, rv3);
            }
        } catch (Exception ignored) {}
    }

    public static RemoteViews buildCompactViews(Context context) {
        RemoteViews rv = new RemoteViews(context.getPackageName(), R.layout.elysion_widget);
        if (cachedCompactBg == null) cachedCompactBg = makeAdaptiveBgBitmap(lastArt, 520, 150, 44);
        rv.setImageViewBitmap(R.id.widget_bg_img, cachedCompactBg);
        rv.setTextViewText(R.id.widget_title, lastTitle);
        rv.setTextViewText(R.id.widget_artist, lastArtist);
        rv.setImageViewResource(R.id.widget_btn_play, lastPlaying ? R.drawable.ic_w_pause : R.drawable.ic_w_play);
        if (lastArt != null) {
            if (cachedCompactCover == null) cachedCompactCover = makeRoundedBitmap(lastArt, 144, 28);
            rv.setImageViewBitmap(R.id.widget_cover, cachedCompactCover);
        } else {
            rv.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher);
        }
        rv.setOnClickPendingIntent(R.id.widget_root, makeOpenAppPi(context, null, 10));
        rv.setOnClickPendingIntent(R.id.widget_btn_prev, makeBroadcastPi(context, ElysionWidgetProvider.class, ACTION_WIDGET_PREV, 11));
        rv.setOnClickPendingIntent(R.id.widget_btn_play, makeBroadcastPi(context, ElysionWidgetProvider.class, ACTION_WIDGET_TOGGLE, 12));
        rv.setOnClickPendingIntent(R.id.widget_btn_next, makeBroadcastPi(context, ElysionWidgetProvider.class, ACTION_WIDGET_NEXT, 13));
        return rv;
    }

    public static RemoteViews buildLargeViews(Context context) {
        RemoteViews rv = new RemoteViews(context.getPackageName(), R.layout.elysion_widget_large);
        if (cachedLargeBg == null) cachedLargeBg = makeAdaptiveBgBitmap(lastArt, 520, 290, 48);
        rv.setImageViewBitmap(R.id.widget_bg_img, cachedLargeBg);
        rv.setTextViewText(R.id.widget_title, lastTitle);
        rv.setTextViewText(R.id.widget_artist, lastArtist);
        rv.setImageViewResource(R.id.widget_btn_play, lastPlaying ? R.drawable.ic_w_pause : R.drawable.ic_w_play);
        rv.setImageViewResource(R.id.widget_btn_like, lastLiked ? R.drawable.ic_w_heart_filled : R.drawable.ic_w_heart_outline);
        if (lastArt != null) {
            if (cachedLargeCover == null) cachedLargeCover = makeRoundedBitmap(lastArt, 180, 34);
            rv.setImageViewBitmap(R.id.widget_cover, cachedLargeCover);
        } else {
            rv.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher);
        }
        rv.setOnClickPendingIntent(R.id.widget_root, makeOpenAppPi(context, null, 20));
        rv.setOnClickPendingIntent(R.id.widget_btn_prev, makeBroadcastPi(context, ElysionWidgetLargeProvider.class, ACTION_WIDGET_PREV, 21));
        rv.setOnClickPendingIntent(R.id.widget_btn_play, makeBroadcastPi(context, ElysionWidgetLargeProvider.class, ACTION_WIDGET_TOGGLE, 22));
        rv.setOnClickPendingIntent(R.id.widget_btn_next, makeBroadcastPi(context, ElysionWidgetLargeProvider.class, ACTION_WIDGET_NEXT, 23));
        rv.setOnClickPendingIntent(R.id.widget_btn_like, makeBroadcastPi(context, ElysionWidgetLargeProvider.class, ACTION_WIDGET_LIKE, 24));
        rv.setOnClickPendingIntent(R.id.widget_btn_wave, makeOpenAppPi(context, "wave", 25));
        return rv;
    }

    public static RemoteViews buildSquareViews(Context context) {
        RemoteViews rv = new RemoteViews(context.getPackageName(), R.layout.elysion_widget_square);
        rv.setTextViewText(R.id.widget_title, lastTitle);
        rv.setTextViewText(R.id.widget_artist, lastArtist);
        rv.setImageViewResource(R.id.widget_btn_play, lastPlaying ? R.drawable.ic_w_pause : R.drawable.ic_w_play);
        if (lastArt != null) {
            if (cachedSquareCover == null) cachedSquareCover = makeRoundedBitmap(lastArt, 320, 48);
            rv.setImageViewBitmap(R.id.widget_cover, cachedSquareCover);
        } else {
            rv.setImageViewBitmap(R.id.widget_cover, makeAdaptiveBgBitmap(null, 320, 320, 48));
        }
        rv.setOnClickPendingIntent(R.id.widget_root, makeOpenAppPi(context, null, 30));
        rv.setOnClickPendingIntent(R.id.widget_btn_play, makeBroadcastPi(context, ElysionWidgetSquareProvider.class, ACTION_WIDGET_TOGGLE, 31));
        return rv;
    }

    private static PendingIntent makeOpenAppPi(Context context, String shortcut, int reqCode) {
        Intent i = new Intent(context, MainActivity.class);
        i.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
        if (shortcut != null && !shortcut.isEmpty()) {
            i.putExtra("shortcut_action", shortcut);
        }
        return PendingIntent.getActivity(context, reqCode, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    private static PendingIntent makeBroadcastPi(Context context, Class<?> cls, String action, int reqCode) {
        Intent i = new Intent(context, cls);
        i.setAction(action);
        return PendingIntent.getBroadcast(context, reqCode, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    private static Bitmap makeRoundedBitmap(Bitmap src, int sizePx, int radiusPx) {
        Bitmap out = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(out);
        int sw = src.getWidth(), sh = src.getHeight();
        int min = Math.min(sw, sh);
        Bitmap cropped = Bitmap.createBitmap(src, (sw - min) / 2, (sh - min) / 2, min, min);
        Bitmap scaled = Bitmap.createScaledBitmap(cropped, sizePx, sizePx, true);
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        p.setShader(new BitmapShader(scaled, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP));
        c.drawRoundRect(new RectF(0, 0, sizePx, sizePx), radiusPx, radiusPx, p);
        return out;
    }

    private static int extractDominantColor(Bitmap src) {
        if (src == null) return Color.rgb(34, 18, 56);
        try {
            Bitmap tiny = Bitmap.createScaledBitmap(src, 16, 16, true);
            long rSum = 0, gSum = 0, bSum = 0, cnt = 0;
            for (int y = 2; y < 14; y++) {
                for (int x = 2; x < 14; x++) {
                    int px = tiny.getPixel(x, y);
                    rSum += Color.red(px);
                    gSum += Color.green(px);
                    bSum += Color.blue(px);
                    cnt++;
                }
            }
            if (cnt == 0) return Color.rgb(34, 18, 56);
            int r = (int) Math.min(110, Math.max(20, (rSum / cnt) * 0.42f));
            int g = (int) Math.min(95, Math.max(14, (gSum / cnt) * 0.36f));
            int b = (int) Math.min(130, Math.max(28, (bSum / cnt) * 0.48f));
            return Color.rgb(r, g, b);
        } catch (Exception e) {
            return Color.rgb(34, 18, 56);
        }
    }

    private static Bitmap makeAdaptiveBgBitmap(Bitmap art, int w, int h, int radiusPx) {
        Bitmap out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(out);
        int accent = extractDominantColor(art);
        int deep = Color.argb(242, 12, 8, 22);
        int start = Color.argb(246, Color.red(accent), Color.green(accent), Color.blue(accent));
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        p.setShader(new LinearGradient(0, 0, w, h, start, deep, Shader.TileMode.CLAMP));
        RectF rect = new RectF(1, 1, w - 1, h - 1);
        c.drawRoundRect(rect, radiusPx, radiusPx, p);
        Paint border = new Paint(Paint.ANTI_ALIAS_FLAG);
        border.setStyle(Paint.Style.STROKE);
        border.setStrokeWidth(2f);
        border.setColor(Color.argb(48, 255, 255, 255));
        c.drawRoundRect(rect, radiusPx, radiusPx, border);
        return out;
    }
}
