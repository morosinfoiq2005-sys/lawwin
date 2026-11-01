set -e
mkdir -p www && cp index.html www/index.html
echo '{"name":"lawwin","version":"1.0.0","private":true}' > package.json
npm i @capacitor/core@6 @capacitor/cli@6 @capacitor/android@6
echo '{"appId":"com.lawwin.app","appName":"لوّن","webDir":"www"}' > capacitor.config.json
npx cap add android
P=android/app/src/main/java/com/lawwin/app
mkdir -p $P
cat > $P/WallpaperPlugin.java << 'JEOF'
package com.lawwin.app;
import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "Wallpaper")
public class WallpaperPlugin extends Plugin {
  @PluginMethod
  public void setWallpaper(final PluginCall call) {
    final String data = call.getString("image");
    final String target = call.getString("target", "both");
    if (data == null) { call.reject("no image"); return; }
    new Thread(() -> {
      try {
        byte[] b = Base64.decode(data, Base64.DEFAULT);
        Bitmap bmp = BitmapFactory.decodeByteArray(b, 0, b.length);
        WallpaperManager wm = WallpaperManager.getInstance(getContext());
        int flag = target.equals("home") ? WallpaperManager.FLAG_SYSTEM
                 : target.equals("lock") ? WallpaperManager.FLAG_LOCK
                 : (WallpaperManager.FLAG_SYSTEM | WallpaperManager.FLAG_LOCK);
        wm.setBitmap(bmp, null, true, flag);
        call.resolve();
      } catch (Exception e) { call.reject(String.valueOf(e.getMessage())); }
    }).start();
  }
}
JEOF
cat > $P/MainActivity.java << 'JEOF'
package com.lawwin.app;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
public class MainActivity extends BridgeActivity {
  @Override
  public void onCreate(Bundle savedInstanceState) {
    registerPlugin(WallpaperPlugin.class);
    super.onCreate(savedInstanceState);
  }
}
JEOF
sed -i 's#<uses-permission android:name="android.permission.INTERNET" />#&\n    <uses-permission android:name="android.permission.SET_WALLPAPER" />#' android/app/src/main/AndroidManifest.xml
cd android && chmod +x gradlew && ./gradlew assembleDebug
