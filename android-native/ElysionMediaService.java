package com.elysion.duo;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.os.IBinder;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import androidx.core.app.NotificationCompat;
import androidx.media.app.NotificationCompat.MediaStyle;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class ElysionMediaService extends Service {
    public static final String CHANNEL_ID = "elysion_playback";
    public static final int NOTIF_ID = 1016;
    private MediaSessionCompat mediaSession;
    private Bitmap cachedArtwork = null;
    private String cachedArtUrl = "";

    @Override
    public void onCreate() {
        super.onCreate();
        createChannel();
        mediaSession = new MediaSessionCompat(this, "ElysionMediaSession");
        mediaSession.setCallback(new MediaSessionCompat.Callback() {
            @Override public void onPlay() { ElysionMediaPlugin.emitAction("play"); }
            @Override public void onPause() { ElysionMediaPlugin.emitAction("pause"); }
            @Override public void onSkipToNext() { ElysionMediaPlugin.emitAction("next"); }
            @Override public void onSkipToPrevious() { ElysionMediaPlugin.emitAction("prev"); }
        });
        mediaSession.setActive(true);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) return START_STICKY;
        String action = intent.getAction();
        if ("ACTION_PLAY".equals(action)) { ElysionMediaPlugin.emitAction("play"); return START_STICKY; }
        if ("ACTION_PAUSE".equals(action)) { ElysionMediaPlugin.emitAction("pause"); return START_STICKY; }
        if ("ACTION_NEXT".equals(action)) { ElysionMediaPlugin.emitAction("next"); return START_STICKY; }
        if ("ACTION_PREV".equals(action)) { ElysionMediaPlugin.emitAction("prev"); return START_STICKY; }

        final String title = intent.getStringExtra("title") != null ? intent.getStringExtra("title") : "Elysion";
        final String artist = intent.getStringExtra("artist") != null ? intent.getStringExtra("artist") : "Elysion";
        final String artUrl = intent.getStringExtra("artwork") != null ? intent.getStringExtra("artwork") : "";
        final boolean isPlaying = intent.getBooleanExtra("isPlaying", false);
        final long duration = intent.getLongExtra("duration", 0);
        final long position = intent.getLongExtra("position", 0);

        updateMediaNotification(title, artist, cachedArtwork, isPlaying, duration, position);

        if (!artUrl.isEmpty() && !artUrl.equals(cachedArtUrl)) {
            cachedArtUrl = artUrl;
            new Thread(() -> {
                try {
                    HttpURLConnection conn = (HttpURLConnection) new URL(artUrl).openConnection();
                    conn.setConnectTimeout(4000);
                    conn.setReadTimeout(4000);
                    try (InputStream is = conn.getInputStream()) {
                        Bitmap bmp = BitmapFactory.decodeStream(is);
                        if (bmp != null) {
                            cachedArtwork = bmp;
                            updateMediaNotification(title, artist, bmp, isPlaying, duration, position);
                        }
                    }
                } catch (Exception ignored) {}
            }).start();
        }
        return START_STICKY;
    }

    private void updateMediaNotification(String title, String artist, Bitmap art, boolean isPlaying, long duration, long position) {
        MediaMetadataCompat.Builder meta = new MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artist)
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, duration);
        if (art != null) meta.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, art);
        mediaSession.setMetadata(meta.build());

        int pbState = isPlaying ? PlaybackStateCompat.STATE_PLAYING : PlaybackStateCompat.STATE_PAUSED;
        long actions = PlaybackStateCompat.ACTION_PLAY | PlaybackStateCompat.ACTION_PAUSE |
                       PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_SKIP_TO_NEXT |
                       PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS;
        mediaSession.setPlaybackState(new PlaybackStateCompat.Builder()
            .setState(pbState, position, isPlaying ? 1.0f : 0.0f)
            .setActions(actions)
            .build());

        Intent openIntent = new Intent(this, MainActivity.class);
        PendingIntent contentPi = PendingIntent.getActivity(this, 0, openIntent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationCompat.Builder nb = new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(artist)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setLargeIcon(art)
            .setContentIntent(contentPi)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(isPlaying)
            .setOnlyAlertOnce(true)
            .addAction(android.R.drawable.ic_media_previous, "Prev", servicePi("ACTION_PREV", 1))
            .addAction(isPlaying ? android.R.drawable.ic_media_pause : android.R.drawable.ic_media_play, isPlaying ? "Pause" : "Play", servicePi(isPlaying ? "ACTION_PAUSE" : "ACTION_PLAY", 2))
            .addAction(android.R.drawable.ic_media_next, "Next", servicePi("ACTION_NEXT", 3))
            .setStyle(new MediaStyle().setMediaSession(mediaSession.getSessionToken()).setShowActionsInCompactView(0, 1, 2));

        Notification notif = nb.build();
        startForeground(NOTIF_ID, notif);
    }

    private PendingIntent servicePi(String action, int reqCode) {
        Intent i = new Intent(this, ElysionMediaService.class);
        i.setAction(action);
        return PendingIntent.getService(this, reqCode, i, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
    }

    private void createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel ch = new NotificationChannel(CHANNEL_ID, "Elysion Playback", NotificationManager.IMPORTANCE_LOW);
            ch.setShowBadge(false);
            NotificationManager nm = getSystemService(NotificationManager.class);
            if (nm != null) nm.createNotificationChannel(ch);
        }
    }

    @Override public void onDestroy() { if (mediaSession != null) mediaSession.release(); super.onDestroy(); }
    @Override public IBinder onBind(Intent intent) { return null; }
}
