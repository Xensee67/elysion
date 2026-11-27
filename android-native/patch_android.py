import os, re, shutil
from PIL import Image

# 1. Generate centered Elysion 16A icons for all Android densities
im = Image.open('icon-1024.png').convert('RGBA')
sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
fg_sizes = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
for d, sz in sizes.items():
    p = f'android/app/src/main/res/mipmap-{d}'
    os.makedirs(p, exist_ok=True)
    r = im.resize((sz, sz), Image.Resampling.LANCZOS)
    r.save(f'{p}/ic_launcher.png')
    r.save(f'{p}/ic_launcher_round.png')
    fg = im.resize((fg_sizes[d], fg_sizes[d]), Image.Resampling.LANCZOS)
    fg.save(f'{p}/ic_launcher_foreground.png')

with open('android/app/src/main/res/values/ic_launcher_background.xml', 'w') as f:
    f.write('<?xml version="1.0" encoding="utf-8"?><resources><color name="ic_launcher_background">#07040F</color></resources>')

# 2. Seamless Android 12+ SplashScreen (#07040F + transparent system icon)
os.makedirs('android/app/src/main/res/values-v31', exist_ok=True)
with open('android/app/src/main/res/values-v31/styles.xml', 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme.NoActionBarLaunch" parent="Theme.SplashScreen">
        <item name="android:windowBackground">#07040F</item>
        <item name="android:windowSplashScreenBackground">#07040F</item>
        <item name="android:windowSplashScreenAnimatedIcon">@android:color/transparent</item>
        <item name="android:statusBarColor">#07040F</item>
        <item name="android:navigationBarColor">#07040F</item>
    </style>
</resources>
''')

styles_path = 'android/app/src/main/res/values/styles.xml'
if os.path.exists(styles_path):
    st = open(styles_path).read()
    if '@drawable/splash' in st:
        st = st.replace('@drawable/splash', '#07040F')
        open(styles_path, 'w').write(st)

# 3. Copy native MediaSession Service & Plugin
pkg_dir = 'android/app/src/main/java/com/elysion/duo'
os.makedirs(pkg_dir, exist_ok=True)
shutil.copy('android-native/ElysionMediaService.java', pkg_dir)
shutil.copy('android-native/ElysionMediaPlugin.java', pkg_dir)

# 4. Register ElysionMediaPlugin in MainActivity.java
with open(os.path.join(pkg_dir, 'MainActivity.java'), 'w') as f:
    f.write('''package com.elysion.duo;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(ElysionMediaPlugin.class);
        super.onCreate(savedInstanceState);
    }
    @Override
    public void onStart() {
        super.onStart();
        if (getBridge() != null && getBridge().getWebView() != null) {
            getBridge().getWebView().setVerticalScrollBarEnabled(false);
            getBridge().getWebView().setHorizontalScrollBarEnabled(false);
            getBridge().getWebView().setOverScrollMode(android.view.View.OVER_SCROLL_NEVER);
        }
    }
}
''')

# 5. Configure permanent signing keystore, versionCode 18, versionName 1.6, and androidx.media
if os.path.exists('android-native/elysion.keystore'):
    shutil.copy('android-native/elysion.keystore', 'android/app/elysion.keystore')

bg = 'android/app/build.gradle'
s = open(bg).read()
s = re.sub(r'versionCode\s+\d+', 'versionCode 18', s)
s = re.sub(r'versionName\s+"[^"]+"', 'versionName "1.8"', s)
if 'androidx.media:media:' not in s:
    s = s.replace('dependencies {', 'dependencies {\n    implementation "androidx.media:media:1.7.0"')
if 'elysion.keystore' not in s and os.path.exists('android/app/elysion.keystore'):
    signing_block = '''    signingConfigs {
        debug {
            storeFile file("elysion.keystore")
            storePassword "elysion2026"
            keyAlias "elysion"
            keyPassword "elysion2026"
        }
    }
    buildTypes {'''
    s = s.replace('buildTypes {', signing_block, 1)
open(bg, 'w').write(s)

# 6. Add permissions & Foreground Media Service to AndroidManifest.xml
mf = 'android/app/src/main/AndroidManifest.xml'
ms = open(mf).read()
perms = '''
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />'''
if 'FOREGROUND_SERVICE_MEDIA_PLAYBACK' not in ms:
    ms = ms.replace('<uses-permission android:name="android.permission.INTERNET" />',
                    '<uses-permission android:name="android.permission.INTERNET" />' + perms)
svc = '''
        <service
            android:name=".ElysionMediaService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />
    </application>'''
if 'ElysionMediaService' not in ms:
    ms = ms.replace('</application>', svc)
open(mf, 'w').write(ms)
print('ANDROID PATCH V1.8 OK (PERMANENT KEYSTORE ENABLED)')
