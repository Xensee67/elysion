import os, re, shutil
from PIL import Image

# 1. ColorOS 17 Stretchable Adaptive Icon (Transparent Foreground inside 62% safe zone + Pure #07040F Background)
im = Image.open('icon-1024.png').convert('RGBA')
px = im.load()
w0, h0 = im.size
fg_src = Image.new('RGBA', (w0, h0), (0, 0, 0, 0))
fpx = fg_src.load()
for y in range(h0):
    for x in range(w0):
        r, g, b, a = px[x, y]
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

# 2. Custom Vector Drawables & Shapes for 3 Elysion Widgets
os.makedirs('android/app/src/main/res/drawable', exist_ok=True)

drawables = {
    'elysion_widget_bg.xml': """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#EB0C0818" />
    <corners android:radius="24dp" />
    <stroke android:width="1dp" android:color="#28FFFFFF" />
</shape>""",
    'elysion_widget_play_circle.xml': """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="#FFFFFF" />
</shape>""",
    'elysion_widget_pill_bg.xml': """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#24FFFFFF" />
    <corners android:radius="99dp" />
    <stroke android:width="1dp" android:color="#22FFFFFF" />
</shape>""",
    'elysion_widget_scrim.xml': """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <gradient android:angle="90" android:startColor="#E807040F" android:centerColor="#7A07040F" android:endColor="#0007040F" />
    <corners android:bottomLeftRadius="22dp" android:bottomRightRadius="22dp" />
</shape>""",
    'ic_w_play.xml': """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="20dp" android:height="20dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#0B0714" android:pathData="M8,5.14v13.72a1,1 0 0,0 1.52,0.85l10.65,-6.86a1,1 0 0,0 0,-1.7L9.52,4.29A1,1 0 0,0 8,5.14z" />
</vector>""",
    'ic_w_pause.xml': """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="20dp" android:height="20dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#0B0714" android:pathData="M6.5,5h3.5a1,1 0 0,1 1,1v12a1,1 0 0,1 -1,1H6.5a1,1 0 0,1 -1,-1V6a1,1 0 0,1 1,-1zM14,5h3.5a1,1 0 0,1 1,1v12a1,1 0 0,1 -1,1H14a1,1 0 0,1 -1,-1V6a1,1 0 0,1 1,-1z" />
</vector>""",
    'ic_w_prev.xml': """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="22dp" android:height="22dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#F2FFFFFF" android:pathData="M6,6h2v12H6V6zM9.5,12l8.5,6V6l-8.5,6z" />
</vector>""",
    'ic_w_next.xml': """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="22dp" android:height="22dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#F2FFFFFF" android:pathData="M6,18l8.5,-6L6,6v12zM16,6v12h2V6h-2z" />
</vector>""",
    'ic_w_heart_outline.xml': """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="20dp" android:height="20dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#00000000" android:strokeColor="#D9FFFFFF" android:strokeWidth="2" android:pathData="M12,21.35l-1.45,-1.32C5.4,15.36 2,12.28 2,8.5 2,5.42 4.42,3 7.5,3c1.74,0 3.41,0.81 4.5,2.09C13.09,3.81 14.76,3 16.5,3 19.58,3 22,5.42 22,8.5c0,3.78 -3.4,6.86 -8.55,11.54L12,21.35z" />
</vector>""",
    'ic_w_heart_filled.xml': """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="20dp" android:height="20dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#EC4899" android:pathData="M12,21.35l-1.45,-1.32C5.4,15.36 2,12.28 2,8.5 2,5.42 4.42,3 7.5,3c1.74,0 3.41,0.81 4.5,2.09C13.09,3.81 14.76,3 16.5,3 19.58,3 22,5.42 22,8.5c0,3.78 -3.4,6.86 -8.55,11.54L12,21.35z" />
</vector>""",
    'ic_w_wave.xml': """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="16dp" android:height="16dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#00000000" android:strokeColor="#F472B6" android:strokeWidth="2.2" android:strokeLineCap="round" android:pathData="M3,12h2M7,8v8M11,5v14M15,8v8M19,10v4" />
</vector>""",
}
for name, body in drawables.items():
    with open(f'android/app/src/main/res/drawable/{name}', 'w', encoding='utf-8') as f:
        f.write(body)

# 3. Three Widget Layouts (4x1 Compact, 4x2 Full Player, 2x2 Square Cover)
os.makedirs('android/app/src/main/res/layout', exist_ok=True)

with open('android/app/src/main/res/layout/elysion_widget.xml', 'w', encoding='utf-8') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ImageView
        android:id="@+id/widget_bg_img"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="fitXY"
        android:src="@drawable/elysion_widget_bg" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:gravity="center_vertical"
        android:orientation="horizontal"
        android:padding="12dp">

        <ImageView
            android:id="@+id/widget_cover"
            android:layout_width="50dp"
            android:layout_height="50dp"
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
                android:textColor="#B8FFFFFF"
                android:textSize="12sp" />
        </LinearLayout>

        <ImageButton
            android:id="@+id/widget_btn_prev"
            android:layout_width="34dp"
            android:layout_height="34dp"
            android:background="@android:color/transparent"
            android:scaleType="centerInside"
            android:src="@drawable/ic_w_prev" />

        <ImageButton
            android:id="@+id/widget_btn_play"
            android:layout_width="40dp"
            android:layout_height="40dp"
            android:layout_marginStart="4dp"
            android:layout_marginEnd="4dp"
            android:background="@drawable/elysion_widget_play_circle"
            android:padding="10dp"
            android:scaleType="centerInside"
            android:src="@drawable/ic_w_play" />

        <ImageButton
            android:id="@+id/widget_btn_next"
            android:layout_width="34dp"
            android:layout_height="34dp"
            android:background="@android:color/transparent"
            android:scaleType="centerInside"
            android:src="@drawable/ic_w_next" />
    </LinearLayout>
</FrameLayout>
""")

with open('android/app/src/main/res/layout/elysion_widget_large.xml', 'w', encoding='utf-8') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ImageView
        android:id="@+id/widget_bg_img"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="fitXY"
        android:src="@drawable/elysion_widget_bg" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical"
        android:padding="14dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1"
            android:gravity="center_vertical"
            android:orientation="horizontal">

            <ImageView
                android:id="@+id/widget_cover"
                android:layout_width="64dp"
                android:layout_height="64dp"
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
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:letterSpacing="0.16"
                    android:text="ELYSION"
                    android:textColor="#88FFFFFF"
                    android:textSize="9sp"
                    android:textStyle="bold" />

                <TextView
                    android:id="@+id/widget_title"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:text="Elysion"
                    android:textColor="#FFFFFF"
                    android:textSize="16sp"
                    android:textStyle="bold" />

                <TextView
                    android:id="@+id/widget_artist"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:text="Наша музыка вдвоём"
                    android:textColor="#B8FFFFFF"
                    android:textSize="12sp" />
            </LinearLayout>

            <ImageButton
                android:id="@+id/widget_btn_like"
                android:layout_width="38dp"
                android:layout_height="38dp"
                android:background="@drawable/elysion_widget_pill_bg"
                android:padding="9dp"
                android:scaleType="centerInside"
                android:src="@drawable/ic_w_heart_outline" />
        </LinearLayout>

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="10dp"
            android:gravity="center_vertical"
            android:orientation="horizontal">

            <LinearLayout
                android:id="@+id/widget_btn_wave"
                android:layout_width="wrap_content"
                android:layout_height="36dp"
                android:background="@drawable/elysion_widget_pill_bg"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="12dp"
                android:paddingEnd="14dp">

                <ImageView
                    android:layout_width="15dp"
                    android:layout_height="15dp"
                    android:src="@drawable/ic_w_wave" />

                <TextView
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="6dp"
                    android:text="Волна"
                    android:textColor="#FFFFFF"
                    android:textSize="12sp"
                    android:textStyle="bold" />
            </LinearLayout>

            <LinearLayout
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:gravity="end|center_vertical"
                android:orientation="horizontal">

                <ImageButton
                    android:id="@+id/widget_btn_prev"
                    android:layout_width="38dp"
                    android:layout_height="38dp"
                    android:background="@android:color/transparent"
                    android:scaleType="centerInside"
                    android:src="@drawable/ic_w_prev" />

                <ImageButton
                    android:id="@+id/widget_btn_play"
                    android:layout_width="44dp"
                    android:layout_height="44dp"
                    android:layout_marginStart="6dp"
                    android:layout_marginEnd="6dp"
                    android:background="@drawable/elysion_widget_play_circle"
                    android:padding="12dp"
                    android:scaleType="centerInside"
                    android:src="@drawable/ic_w_play" />

                <ImageButton
                    android:id="@+id/widget_btn_next"
                    android:layout_width="38dp"
                    android:layout_height="38dp"
                    android:background="@android:color/transparent"
                    android:scaleType="centerInside"
                    android:src="@drawable/ic_w_next" />
            </LinearLayout>
        </LinearLayout>
    </LinearLayout>
</FrameLayout>
""")

with open('android/app/src/main/res/layout/elysion_widget_square.xml', 'w', encoding='utf-8') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ImageView
        android:id="@+id/widget_cover"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="centerCrop"
        android:src="@mipmap/ic_launcher" />

    <ImageView
        android:layout_width="match_parent"
        android:layout_height="84dp"
        android:layout_gravity="bottom"
        android:src="@drawable/elysion_widget_scrim" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        android:gravity="center_vertical"
        android:orientation="horizontal"
        android:padding="12dp">

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:paddingEnd="8dp">

            <TextView
                android:id="@+id/widget_title"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:maxLines="1"
                android:text="Elysion"
                android:textColor="#FFFFFF"
                android:textSize="13sp"
                android:textStyle="bold" />

            <TextView
                android:id="@+id/widget_artist"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:maxLines="1"
                android:text="Наша музыка"
                android:textColor="#CCFFFFFF"
                android:textSize="11sp" />
        </LinearLayout>

        <ImageButton
            android:id="@+id/widget_btn_play"
            android:layout_width="38dp"
            android:layout_height="38dp"
            android:background="@drawable/elysion_widget_play_circle"
            android:padding="10dp"
            android:scaleType="centerInside"
            android:src="@drawable/ic_w_play" />
    </LinearLayout>
</FrameLayout>
""")

# 4. Widget Info XMLs & App Shortcuts XML
os.makedirs('android/app/src/main/res/xml', exist_ok=True)
with open('android/app/src/main/res/xml/elysion_widget_info.xml', 'w', encoding='utf-8') as f:
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

with open('android/app/src/main/res/xml/elysion_widget_large_info.xml', 'w', encoding='utf-8') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="130dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/elysion_widget_large"
    android:widgetCategory="home_screen" />
""")

with open('android/app/src/main/res/xml/elysion_widget_square_info.xml', 'w', encoding='utf-8') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="130dp"
    android:minHeight="130dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/elysion_widget_square"
    android:widgetCategory="home_screen" />
""")

with open('android/app/src/main/res/xml/shortcuts.xml', 'w', encoding='utf-8') as f:
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
    <string name="w_compact">Elysion · Компактный</string>
    <string name="w_large">Elysion · Полный плеер</string>
    <string name="w_square">Elysion · Обложка</string>
</resources>"""
        st_xml = st_xml.replace('</resources>', extra_str, 1)
        open(strings_path, 'w', encoding='utf-8').write(st_xml)

# 5. Seamless Android 12+ SplashScreen + Transparent Edge-to-Edge System Bars
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

# 6. Copy native MediaSession Service, Plugin & 3 Widget Providers + Helper
pkg_dir = 'android/app/src/main/java/com/elysion/duo'
os.makedirs(pkg_dir, exist_ok=True)
for jf in ['ElysionMediaService.java', 'ElysionMediaPlugin.java', 'ElysionWidgetHelper.java', 'ElysionWidgetProvider.java', 'ElysionWidgetLargeProvider.java', 'ElysionWidgetSquareProvider.java']:
    shutil.copy(f'android-native/{jf}', pkg_dir)

# 7. Register ElysionMediaPlugin + Edge-to-Edge + App Shortcut Intent Handler in MainActivity.java
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

# 8. Configure permanent signing keystore, versionCode 29, versionName 2.7, and androidx.media
if os.path.exists('android-native/elysion.keystore'):
    shutil.copy('android-native/elysion.keystore', 'android/app/elysion.keystore')

bg = 'android/app/build.gradle'
s = open(bg).read()
s = re.sub(r'versionCode\s+\d+', 'versionCode 31', s)
s = re.sub(r'versionName\s+"[^"]+"', 'versionName "3.1"', s)
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

# 9. Register Permissions, Foreground Service, 3 Home Widgets & App Shortcuts in AndroidManifest.xml
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
svc_and_widgets = """
        <service
            android:name=".ElysionMediaService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />
        <receiver
            android:name=".ElysionWidgetProvider"
            android:label="@string/w_compact"
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
        <receiver
            android:name=".ElysionWidgetLargeProvider"
            android:label="@string/w_large"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="com.elysion.duo.WIDGET_PREV" />
                <action android:name="com.elysion.duo.WIDGET_TOGGLE" />
                <action android:name="com.elysion.duo.WIDGET_NEXT" />
                <action android:name="com.elysion.duo.WIDGET_LIKE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/elysion_widget_large_info" />
        </receiver>
        <receiver
            android:name=".ElysionWidgetSquareProvider"
            android:label="@string/w_square"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="com.elysion.duo.WIDGET_TOGGLE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/elysion_widget_square_info" />
        </receiver>
    </application>"""
if 'ElysionMediaService' not in ms:
    ms = ms.replace('</application>', svc_and_widgets)
open(mf, 'w').write(ms)
print('ANDROID PATCH V3.1 OK (3 WIDGETS + ADAPTIVE ICON + SHORTCUTS + BLUETOOTH + AUDIOFX)')
