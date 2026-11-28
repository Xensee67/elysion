#!/usr/bin/env python3
"""
Configures generated Android scaffold for Elysion Native v1.0:
- Package ID: com.elysion.native (installs side-by-side with com.elysion.duo)
- Permanent signing with ../android-native/elysion.keystore
- minSdk 24, targetSdk 35, versionCode 1, versionName "1.0"
- AudioServiceActivity + AudioService + MediaButtonReceiver + foreground media permissions
- App label "Elysion" & launcher icon from assets/icon-512.png
"""
import os, re, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
ANDROID = os.path.join(ROOT, 'android')
APP = os.path.join(ANDROID, 'app')
KEYSTORE_SRC = os.path.abspath(os.path.join(ROOT, '..', 'android-native', 'elysion.keystore'))
KEYSTORE_DST = os.path.join(APP, 'elysion.keystore')

# 1. Copy permanent keystore
has_keystore = False
if os.path.exists(KEYSTORE_SRC):
    shutil.copy(KEYSTORE_SRC, KEYSTORE_DST)
    has_keystore = True
    print("Copied permanent elysion.keystore")
else:
    print("WARNING: ../android-native/elysion.keystore not found; using debug signing fallback")

# 2. Patch build.gradle.kts OR build.gradle
kts_path = os.path.join(APP, 'build.gradle.kts')
groovy_path = os.path.join(APP, 'build.gradle')

if os.path.exists(kts_path):
    with open(kts_path, 'r', encoding='utf-8') as f:
        s = f.read()
    s = re.sub(r'applicationId\s*=\s*"[^"]+"', 'applicationId = "com.elysion.native"', s)
    s = re.sub(r'minSdk\s*=\s*[^\n]+', 'minSdk = 24', s)
    s = re.sub(r'targetSdk\s*=\s*[^\n]+', 'targetSdk = 35', s)
    s = re.sub(r'versionCode\s*=\s*[^\n]+', 'versionCode = 1', s)
    s = re.sub(r'versionName\s*=\s*[^\n]+', 'versionName = "1.0"', s)
    if has_keystore and 'elysion.keystore' not in s:
        signing_kts = """    signingConfigs {
        create("release") {
            storeFile = file("elysion.keystore")
            storePassword = System.getenv("ELYSION_STORE_PASS") ?: "elysion2026"
            keyAlias = "elysion"
            keyPassword = System.getenv("ELYSION_KEY_PASS") ?: "elysion2026"
        }
    }
    buildTypes {"""
        s = s.replace('buildTypes {', signing_kts, 1)
        s = s.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
    with open(kts_path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("Patched build.gradle.kts -> com.elysion.native v1.0")
elif os.path.exists(groovy_path):
    with open(groovy_path, 'r', encoding='utf-8') as f:
        s = f.read()
    s = re.sub(r'applicationId\s+["\'][^"\']+["\']', 'applicationId "com.elysion.native"', s)
    s = re.sub(r'minSdk\s+\S+', 'minSdk 24', s)
    s = re.sub(r'minSdkVersion\s+\S+', 'minSdkVersion 24', s)
    s = re.sub(r'targetSdk\s+\S+', 'targetSdk 35', s)
    s = re.sub(r'versionCode\s+\S+', 'versionCode 1', s)
    s = re.sub(r'versionName\s+\S+', 'versionName "1.0"', s)
    if has_keystore and 'elysion.keystore' not in s:
        signing_groovy = """    signingConfigs {
        release {
            storeFile file("elysion.keystore")
            storePassword "elysion2026"
            keyAlias "elysion"
            keyPassword "elysion2026"
        }
    }
    buildTypes {"""
        s = s.replace('buildTypes {', signing_groovy, 1)
        s = s.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
    with open(groovy_path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("Patched build.gradle -> com.elysion.native v1.0")

# 3. Patch MainActivity.kt to extend AudioServiceActivity
for root_dir, _, files in os.walk(os.path.join(APP, 'src', 'main')):
    for fn in files:
        if fn == 'MainActivity.kt':
            p = os.path.join(root_dir, fn)
            with open(p, 'r', encoding='utf-8') as f:
                kt = f.read()
            pkg_m = re.search(r'^package\s+([\w\.]+)', kt, re.M)
            pkg_line = f"package {pkg_m.group(1)}" if pkg_m else "package com.elysion.elysion_native"
            new_kt = f"""{pkg_line}

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity()
"""
            with open(p, 'w', encoding='utf-8') as f:
                f.write(new_kt)
            print("Patched MainActivity.kt -> AudioServiceActivity")

# 4. Patch AndroidManifest.xml with permissions, app label, and AudioService declarations
manifest_path = os.path.join(APP, 'src', 'main', 'AndroidManifest.xml')
if os.path.exists(manifest_path):
    with open(manifest_path, 'r', encoding='utf-8') as f:
        m = f.read()
    m = re.sub(r'android:label="[^"]+"', 'android:label="Elysion"', m, count=1)
    perms = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
"""
    if 'FOREGROUND_SERVICE_MEDIA_PLAYBACK' not in m:
        m = m.replace('<application', perms + '    <application', 1)
    if 'usesCleartextTraffic' not in m:
        m = m.replace('<application', '<application android:usesCleartextTraffic="true"', 1)
    audio_svc = """        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver
            android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
    </application>"""
    if 'com.ryanheise.audioservice.AudioService' not in m:
        m = m.replace('</application>', audio_svc, 1)
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(m)
    print("Patched AndroidManifest.xml with AudioService & MediaButtonReceiver")

# 5. Copy icon-512.png into mipmap-* launcher icons
icon_src = os.path.join(ROOT, 'assets', 'icon-512.png')
if os.path.exists(icon_src):
    res_dir = os.path.join(APP, 'src', 'main', 'res')
    for sub in ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi']:
        d = os.path.join(res_dir, sub)
        if os.path.isdir(d):
            shutil.copy(icon_src, os.path.join(d, 'ic_launcher.png'))
    print("Installed Elysion launcher icons")

print("ELYSION NATIVE ANDROID PATCH v1.0 COMPLETE!")
