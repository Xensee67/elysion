import os, re, shutil
from PIL import Image

# 1. ColorOS 17 Stretchable Adaptive Icon (Transparent Foreground inside 62% safe zone + Pure #07040F Background!)
im = Image.open('icon-1024.png').convert('RGBA')
px = im.load()
w0, h0 = im.size
fg_src = Image.new('RGBA', (w0, h0), (0, 0, 0, 0))
fpx = fg_src.load()
for y in range(h0):
    for x in range(w0):
        r, g, b, a = px[x, y]
        # Key out dark #07040F background smoothly so ColorOS stretched tiles show pure #07040F with zero grey box!
        lum = max(r, g, b)
        if lum <= 22:
            fpx[x, y] = (r, g, b, 0)
        elif lum < 44:
            na = int(a * (lum - 22) / 22.0)
            fpx[x, y] = (r, g, b, na)
        else:
            fpx[x, y] = (r, g, b, a)

sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
fg_sizes = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
for d, sz in sizes.items():
    p = f'android/app/src/main/res/mipmap-{d}'
    os.makedirs(p, exist_ok=True)
    r = im.resize((sz, sz), Image.Resampling.LANCZOS)
    r.save(f'{p}/ic_launcher.png')
    r.save(f'{p}/ic_launcher_round.png')

    # Foreground: transparent 108dp canvas with logo scaled cleanly inside 62% safe zone!
    fsz = fg_sizes[d]
    inner = int(fsz * 0.62)
    canvas = Image.new('RGBA', (fsz, fsz), (0, 0, 0, 0))
    scaled = fg_src.resize((inner, inner), Image.Resampling.LANCZOS)
    off = (fsz - inner) // 2
    canvas.paste(scaled, (off, off), scaled)
    canvas.save(f'{p}/ic_launcher_foreground.png')

with open('android/app/src/main/res/values/ic_launcher_background.xml', 'w') as f:
    f.write('<?xml version="1.0" encoding="utf-8"?><resources><color name="ic_launcher_background">#07040F</color></resources>')

os.makedirs('android/app/src/main/res/mipmap-anydpi-v26', exist_ok=True)
adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""
with open('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml', 'w') as f:
    f.write(adaptive_xml)
with open('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml', 'w') as f:
    f.write(adaptive_xml)

# 2. Widget Resources (Dark Glass 4x1 / 4x2 Widget) & App Shortcuts XML
os.makedirs('android/app/src/main/res/drawable', exist_ok=True)
with open('android/app/src/main/res/drawable/elysion_widget_bg.xml', 'w') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#EB0C0818" />
    <corners android:radius="24dp" />
    <stroke android:width="1dp" android:color="#28FFFFFF" />
</shape>
""")

os.makedirs('android/app/src/main/res/layout', exist_ok=True)
with open('android/app/src/main/res/layout/elysion_widget.xml', 'w') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/elysion_widget_bg"
    android:gravity="center_vertical"
    android:orientation="horizontal"
    android:padding="12dp">

    <ImageView
        android:id="@+id/widget_cover"
        android:layout_width="52dp"
        android:layout_height="52dp"
        android:scaleType="centerCrop"
        android:src="@mipmap/ic_launcher" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical"
        android:paddingStart="12dp"
        android:paddingEnd="8dp">

        <TextView
            android:id="@+id/widget_title"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:text="Elysion"
            android:textColor="#FFFFFF"
            android:textSize="15sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/widget_artist"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:text="Наша музыка вдвоём"
            android:textColor="#B0FFFFFF"
            android:textSize="12sp" />
    </LinearLayout>

    <ImageButton
        android:id="@+id/widget_btn_prev"
        android:layout_width="36dp"
        android:layout_height="36dp"
        android:background="@android:color/transparent"
        android:src="@android:drawable/ic_media_previous"
        android:tint="#E6FFFFFF" />

    <ImageButton
        android:id="@+id/widget_btn_play"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:background="@android:color/transparent"
        android:src="@android:drawable/ic_media_play"
        android:tint="#FFFFFF" />

    <ImageButton
        android:id="@+id/widget_btn_next"
        android:layout_width="36dp"
        android:layout_height="36dp"
        android:background="@android:color/transparent"
        android:src="@android:drawable/ic_media_next"
        android:tint="#E6FFFFFF" />
</LinearLayout>
""")

os.makedirs('android/app/src/main/res/xml', exist_ok=True)
with open('android/app/src/main/res/xml/elysion_widget_info.xml', 'w') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="64dp"
    android:targetCellWidth="4"
    android:targetCellHeight="1"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/elysion_widget"
    android:widgetCategory="home_screen" />
""")

with open('android/app/src/main/res/xml/shortcuts.xml', 'w') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<shortcuts xmlns:android="http://schemas.android.com/apk/res/android">
    <shortcut android:shortcutId="wave" android:enabled="true" android:icon="@mipmap/ic_launcher" android:shortcutShortLabel="@string/sc_wave">
        <intent android:action="android.intent.action.VIEW" android:targetPackage="com.elysion.duo" android:targetClass="com.elysion.duo.MainActivity">
            <extra android:name="shortcut_action" android:value="wave" />
        </intent>
    </shortcut>
    <shortcut android:shortcutId="likes" android:enabled="true" android:icon="@mipmap/ic_launcher" android:shortcutShortLabel="@string/sc_likes">
        <intent android:action="android.intent.action.VIEW" android:targetPackage="com.elysion.duo" android:targetClass="com.elysion.duo.MainActivity">
            <extra android:name="shortcut_action" android:value="likes" />
        </intent>
    </shortcut>
    <shortcut android:shortcutId="search" android:enabled="true" android:icon="@mipmap/ic_launcher" android:shortcutShortLabel="@string/sc_search">
        <intent android:action="android.intent.action.VIEW" android:targetPackage="com.elysion.duo" android:targetClass="com.elysion.duo.MainActivity">
            <extra android:name="shortcut_action" android:value="search" />
        </intent>
    </shortcut>
    <shortcut android:shortcutId="jam" android:enabled="true" android:icon="@mipmap/ic_launcher" android:shortcutShortLabel="@string/sc_jam">
        <intent android:action="android.intent.action.VIEW" android:targetPackage="com.elysion.duo" android:targetClass="com.elysion.duo.MainActivity">
            <extra android:name="shortcut_action" android:value="jam" />
        </intent>
    </shortcut>
</shortcuts>
""")

strings_path = 'android/app/src/main/res/values/strings.xml'
if os.path.exists(strings_path):
    st_xml = open(strings_path, encoding='utf-8').read()
    if 'sc_wave' not in st_xml:
        extra_str = """    <string name="sc_wave">Наша Волна</string>
    <string name="sc_likes">Мне нравится</string>
    <string name="sc_search">Поиск</string>
    <string name="sc_jam">Live Jam</string>
</resources>"""
        st_xml = st_xml.replace('</resources>', extra_str, 1)
        open(strings_path, 'w', encoding='utf-8').write(st_xml)

# 3. Seamless Android 12+ SplashScreen + Transparent Edge-to-Edge System Bars
os.makedirs('android/app/src/main/res/values-v31', exist_ok=True)
with open('android/app/src/main/res/values-v31/styles.xml', 'w') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme.NoActionBarLaunch" parent="Theme.SplashScreen">
        <item name="android:windowBackground">#07040F</item>
        <item name="android:windowSplashScreenBackground">#07040F</item>
        <item name="android:windowSplashScreenAnimatedIcon">@android:color/transparent</item>
        <item name="android:statusBarColor">@android:color/transparent</item>
        <item name="android:navigationBarColor">@android:color/transparent</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
</resources>
""")

styles_path = 'android/app/src/main/res/values/styles.xml'
if os.path.exists(styles_path):
    st = open(styles_path).read()
    if '@drawable/splash' in st:
        st = st.replace('@drawable/splash', '#07040F')
    if 'android:statusBarColor' not in st:
        st = st.replace('</style>', '        <item name="android:statusBarColor">@android:color/transparent</item>\n        <item name="android:navigationBarColor">@android:color/transparent</item>\n    </style>', 1)
    open(styles_path, 'w').write(st)

# 4. Copy native MediaSession Service, Plugin & WidgetProvider
pkg_dir = 'android/app/src/main/java/com/elysion/duo'
os.makedirs(pkg_dir, exist_ok=True)
shutil.copy('android-native/ElysionMediaService.java', pkg_dir)
shutil.copy('android-native/ElysionMediaPlugin.java', pkg_dir)
shutil.copy('android-native/ElysionWidgetProvider.java', pkg_dir)

# 5. Register ElysionMediaPlugin + Edge-to-Edge + App Shortcut Intent Handler in MainActivity.java
with open(os.path.join(pkg_dir, 'MainActivity.java'), 'w') as f:
    f.write("""package com.elysion.duo;

import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(ElysionMediaPlugin.class);
        super.onCreate(savedInstanceState);
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        getWindow().setStatusBarColor(Color.TRANSPARENT);
        getWindow().setNavigationBarColor(Color.TRANSPARENT);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            WindowManager.LayoutParams lp = getWindow().getAttributes();
            lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            getWindow().setAttributes(lp);
        }
        WindowInsetsControllerCompat ctrl = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        if (ctrl != null) {
            ctrl.setAppearanceLightStatusBars(false);
            ctrl.setAppearanceLightNavigationBars(false);
        }
        handleShortcutIntent(getIntent());
    }
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleShortcutIntent(intent);
    }
    private void handleShortcutIntent(Intent intent) {
        if (intent != null && intent.hasExtra("shortcut_action")) {
            String sc = intent.getStringExtra("shortcut_action");
            if (sc != null && !sc.isEmpty()) ElysionMediaPlugin.emitShortcut(sc);
        }
    }
    @Override
    public void onStart() {
        super.onStart();
        if (getBridge() != null && getBridge().getWebView() != null) {
            getBridge().getWebView().setVerticalScrollBarEnabled(false);
            getBridge().getWebView().setHorizontalScrollBarEnabled(false);
            getBridge().getWebView().setOverScrollMode(View.OVER_SCROLL_NEVER);
        }
    }
}
""")

# 6. Configure permanent signing keystore, versionCode 26, versionName 2.6, and androidx.media
if os.path.exists('android-native/elysion.keystore'):
    shutil.copy('android-native/elysion.keystore', 'android/app/elysion.keystore')

bg = 'android/app/build.gradle'
s = open(bg).read()
s = re.sub(r'versionCode\s+\d+', 'versionCode 26', s)
s = re.sub(r'versionName\s+"[^"]+"', 'versionName "2.6"', s)
if 'androidx.media:media:' not in s:
    s = s.replace('dependencies {', 'dependencies {\n    implementation "androidx.media:media:1.7.0"')
if 'elysion.keystore' not in s and os.path.exists('android/app/elysion.keystore'):
    signing_block = """    signingConfigs {
        debug {
            storeFile file("elysion.keystore")
            storePassword "elysion2026"
            keyAlias "elysion"
            keyPassword "elysion2026"
        }
    }
    buildTypes {"""
    s = s.replace('buildTypes {', signing_block, 1)
open(bg, 'w').write(s)

# 7. Register Permissions, Foreground Service, Home Widget & App Shortcuts in AndroidManifest.xml
mf = 'android/app/src/main/AndroidManifest.xml'
ms = open(mf).read()
perms = """
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />"""
if 'FOREGROUND_SERVICE_MEDIA_PLAYBACK' not in ms:
    ms = ms.replace('<uses-permission android:name="android.permission.INTERNET" />',
                    '<uses-permission android:name="android.permission.INTERNET" />' + perms)
if 'android.app.shortcuts' not in ms:
    ms = ms.replace('</activity>', '            <meta-data android:name="android.app.shortcuts" android:resource="@xml/shortcuts" />\n        </activity>', 1)
svc_and_widget = """
        <service
            android:name=".ElysionMediaService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />
        <receiver
            android:name=".ElysionWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="com.elysion.duo.WIDGET_PREV" />
                <action android:name="com.elysion.duo.WIDGET_TOGGLE" />
                <action android:name="com.elysion.duo.WIDGET_NEXT" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/elysion_widget_info" />
        </receiver>
    </application>"""
if 'ElysionMediaService' not in ms:
    ms = ms.replace('</application>', svc_and_widget)
open(mf, 'w').write(ms)
print('ANDROID PATCH V2.6 OK (ADAPTIVE ICON + WIDGET + SHORTCUTS + BLUETOOTH + AUDIOFX)')
