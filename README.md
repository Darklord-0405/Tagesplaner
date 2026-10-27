# Tagesplaner

Plane deinen nächsten Tag: einzelne Aufgaben, täglich und wöchentlich wiederkehrende Routinen, Kategorien und Erinnerungen.

## Funktionen
- Aufgaben für **Heute, Morgen** oder jeden anderen Tag, optional mit Uhrzeit
- **Einmalig, täglich oder wöchentlich** (frei wählbare Wochentage)
- **Kategorien** wie Sport, Schule, Tägliche Hygiene, Haushalt – eigene anlegen, umbenennen und löschen; Aufgaben nach Kategorie gruppiert und filterbar
- Offene Aufgaben aus früheren Tagen mit einem Tipp auf den heutigen Tag holen
- Hell, Dunkel oder Auto, Layout für Handy, Tablet und Laptop
- **Geräte-Sync** (siehe unten) und **Erinnerungen** in der Android-App

## Inhalt
| Ordner / Datei | Was es ist |
| --- | --- |
| `index.html` | Die Web-App in einer einzigen Datei. Öffnen oder über GitHub Pages hosten. |
| `android/Tagesplaner.apk` | Android-App mit Erinnerungen für offene Aufgaben (Quellcode in `android/src`). |
| `apple/` | Native SwiftUI-App für Mac und iPad, ohne App Store (Anleitung in `apple/ANLEITUNG.txt`). |

Die Apple-App ist ein früherer Stand: ohne Kategorien, Geräte-Sync und Erinnerungen.

## Daten und Geräte-Sync
- Ohne Anbindung speichert die App alles **lokal im Browser** des jeweiligen Geräts.
- Läuft die Seite als Claude-Artefakt (angemeldetes Konto), gleichen sich Aufgaben, Häkchen und Kategorien **live zwischen Geräten** ab. Änderungen werden zusammengeführt, nicht überschrieben, und nach Offline-Phasen nachgeholt.
- Für Kopien ohne Anbindung (GitHub Pages, Datei, APK) gibt es unter „Geräte-Sync & Backup“ → „Daten übertragen“ einen Export/Import per Text.

## Android-App
- Zeigt `index.html` in einer WebView, funktioniert offline.
- Erinnerungen zu zwei frei wählbaren Uhrzeiten (Standard 08:00 und 18:00) mit den noch offenen Aufgaben des Tages.
- Beim ersten Start fragt Android ab Version 13 nach der Erlaubnis für Benachrichtigungen.
- Die APK ist mit einem privaten Schlüssel signiert, der nicht im Repository liegt. Updates lassen sich daher nur mit demselben Schlüssel über eine vorhandene Installation legen.
