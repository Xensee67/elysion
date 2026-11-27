import os, shutil
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
    f.write('<?xml version="1.0" encoding="utf-8"?><resources><color name="ic_launcher_background">#09060F</color></resources>')

# 2. Copy native MediaSession Service & Plugin
pkg_dir = 'android/app/src/main/java/com/elysion/duo'
os.makedirs(pkg_dir, exist_ok=True)
shutil.copy('android-native/ElysionMediaService.java', pkg_dir)
shutil.copy('android-native/ElysionMediaPlugin.java', pkg_dir)

# 3. Register ElysionMediaPlugin in MainActivity.java
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
}
''')

# 4. Add androidx.media dependency
bg = 'android/app/build.gradle'
s = open(bg).read()
if 'androidx.media:media:' not in s:
    s = s.replace('dependencies {', 'dependencies {\n    implementation "androidx.media:media:1.7.0"')
    open(bg, 'w').write(s)

# 5. Add permissions & Foreground Media Service to AndroidManifest.xml
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
print('ANDROID PATCH OK')
