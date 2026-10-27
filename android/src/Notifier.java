package com.example.tagesplaner;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

public class Notifier {
    static final String CH = "erinnerungen";
    static final String PREF = "notify";
    static final String KEY = "cfg";

    static String dayKey() {
        Calendar c = Calendar.getInstance();
        return String.format("%04d-%02d-%02d", c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH));
    }

    static void ensureChannel(Context c) {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm.getNotificationChannel(CH) == null) {
                NotificationChannel ch = new NotificationChannel(CH, "Erinnerungen", NotificationManager.IMPORTANCE_DEFAULT);
                ch.setDescription("Erinnerung an noch offene Punkte");
                nm.createNotificationChannel(ch);
            }
        }
    }

    static String load(Context c) {
        return c.getSharedPreferences(PREF, Context.MODE_PRIVATE).getString(KEY, "");
    }

    static void save(Context c, String json) {
        c.getSharedPreferences(PREF, Context.MODE_PRIVATE).edit().putString(KEY, json).apply();
    }

    private static PendingIntent alarmIntent(Context c, int idx) {
        Intent i = new Intent(c, ReminderReceiver.class);
        i.setAction("com.example.tagesplaner.REMIND");
        i.putExtra("idx", idx);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
        return PendingIntent.getBroadcast(c, idx, i, flags);
    }

    static void reschedule(Context c) {
        AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
        for (int i = 0; i < 2; i++) am.cancel(alarmIntent(c, i));
        try {
            String raw = load(c);
            if (raw.length() == 0) return;
            JSONObject o = new JSONObject(raw);
            if (!o.optBoolean("enabled")) return;
            JSONArray t = o.optJSONArray("times");
            if (t == null) return;
            for (int i = 0; i < t.length() && i < 2; i++) {
                String[] p = t.getString(i).split(":");
                Calendar cal = Calendar.getInstance();
                cal.set(Calendar.HOUR_OF_DAY, Integer.parseInt(p[0]));
                cal.set(Calendar.MINUTE, Integer.parseInt(p[1]));
                cal.set(Calendar.SECOND, 0);
                cal.set(Calendar.MILLISECOND, 0);
                if (cal.getTimeInMillis() <= System.currentTimeMillis() + 30000) cal.add(Calendar.DAY_OF_YEAR, 1);
                setAlarm(am, cal.getTimeInMillis(), alarmIntent(c, i));
            }
        } catch (Exception e) {
            // Ungueltige Konfiguration: keine Alarme
        }
    }

    private static void setAlarm(AlarmManager am, long at, PendingIntent pi) {
        try {
            if (Build.VERSION.SDK_INT >= 23) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi);
            else am.setExact(AlarmManager.RTC_WAKEUP, at, pi);
        } catch (SecurityException e) {
            if (Build.VERSION.SDK_INT >= 23) am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi);
            else am.set(AlarmManager.RTC_WAKEUP, at, pi);
        }
    }

    static void show(Context c, boolean test) {
        ensureChannel(c);
        List<String> items = new ArrayList<String>();
        String app = "Erinnerung", u1 = "Punkt", uN = "Punkte";
        try {
            String raw = load(c);
            if (raw.length() > 0) {
                JSONObject o = new JSONObject(raw);
                app = o.optString("app", app);
                u1 = o.optString("u1", u1);
                uN = o.optString("uN", uN);
                JSONObject days = o.optJSONObject("days");
                String k = dayKey();
                JSONArray a = (days != null && days.has(k)) ? days.getJSONArray(k) : o.optJSONArray("daily");
                if (a != null) for (int i = 0; i < a.length(); i++) items.add(a.getString(i));
            }
        } catch (Exception e) {
            // ignorieren
        }
        if (items.isEmpty() && !test) return;

        String title, summary, big;
        if (items.isEmpty()) {
            title = app;
            summary = "Test: Erinnerungen funktionieren.";
            big = summary;
        } else {
            int n = items.size();
            title = "Noch " + n + " " + (n == 1 ? u1 : uN) + " offen";
            StringBuilder sb = new StringBuilder();
            StringBuilder big2 = new StringBuilder();
            for (int i = 0; i < n && i < 8; i++) {
                if (i > 0) sb.append(", ");
                sb.append(items.get(i));
                if (i > 0) big2.append("\n");
                big2.append("• ").append(items.get(i));
            }
            if (n > 8) {
                sb.append(" …");
                big2.append("\n+ ").append(n - 8).append(" weitere");
            }
            summary = sb.toString();
            big = big2.toString();
        }

        Intent open = new Intent(c, MainActivity.class);
        open.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
        PendingIntent pi = PendingIntent.getActivity(c, 100, open, flags);

        Notification.Builder b = (Build.VERSION.SDK_INT >= 26) ? new Notification.Builder(c, CH) : new Notification.Builder(c);
        int icon = c.getResources().getIdentifier("ic_stat", "drawable", c.getPackageName());
        if (icon == 0) icon = android.R.drawable.ic_popup_reminder;
        b.setSmallIcon(icon);
        b.setContentTitle(title);
        b.setContentText(summary);
        b.setStyle(new Notification.BigTextStyle().bigText(big).setSummaryText(app));
        b.setContentIntent(pi);
        b.setAutoCancel(true);
        if (Build.VERSION.SDK_INT < 26) b.setPriority(Notification.PRIORITY_DEFAULT);

        NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
        nm.notify(test ? 2 : 1, b.build());
    }
}
