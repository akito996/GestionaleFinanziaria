# Tesseract4Android (lettura delle foto): il codice nativo usa classi, campi e
# metodi Java per nome. La libreria non porta regole proprie: senza queste,
# l'ottimizzazione della build di release li rinominerebbe.
-keep class com.googlecode.tesseract.android.** { *; }
-keep class com.googlecode.leptonica.android.** { *; }
