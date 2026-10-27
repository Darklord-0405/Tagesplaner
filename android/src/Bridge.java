package com.example.tagesplaner;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.webkit.JavascriptInterface;

public class Bridge {
    private final Context c;

    public Bridge(Context c) {
        this.c = c;
    }

    @JavascriptInterface
    public void sync(String json) {
        Notifier.save(c, json);
        Notifier.reschedule(c);
    }

    @JavascriptInterface
    public String test() {
        if (Build.VERSION.SDK_INT >= 24) {
            NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
            if (!nm.areNotificationsEnabled()) return "off";
        }
        Notifier.show(c, true);
        return "ok";
    }

    @JavascriptInterface
    public void openSettings() {
        Intent i;
        if (Build.VERSION.SDK_INT >= 26) {
            i = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            i.putExtra(Settings.EXTRA_APP_PACKAGE, c.getPackageName());
        } else {
            i = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            i.setData(Uri.parse("package:" + c.getPackageName()));
        }
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        c.startActivity(i);
    }
}
