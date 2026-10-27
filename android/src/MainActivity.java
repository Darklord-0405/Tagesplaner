package com.example.tagesplaner;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;

public class MainActivity extends Activity {
    private WebView wv;
    private String loadedDay = "";

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        Notifier.ensureChannel(this);
        wv = new WebView(this);
        WebSettings s = wv.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        wv.addJavascriptInterface(new Bridge(getApplicationContext()), "AndroidApp");
        setContentView(wv);
        loadedDay = Notifier.dayKey();
        wv.loadUrl("file:///android_asset/index.html");
        Notifier.reschedule(this);
        askNotificationPermission();
    }

    private void askNotificationPermission() {
        if (Build.VERSION.SDK_INT < 33) return;
        SharedPreferences p = getSharedPreferences("notify", Context.MODE_PRIVATE);
        if (p.getBoolean("asked", false)) return;
        if (checkSelfPermission("android.permission.POST_NOTIFICATIONS") != PackageManager.PERMISSION_GRANTED) {
            p.edit().putBoolean("asked", true).apply();
            requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 1);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Neuer Tag seit dem Laden? Dann Seite neu laden, damit "heute" stimmt.
        String d = Notifier.dayKey();
        if (!d.equals(loadedDay) && wv != null) {
            loadedDay = d;
            wv.reload();
        }
    }
}
