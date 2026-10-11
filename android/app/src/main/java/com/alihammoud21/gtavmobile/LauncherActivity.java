package com.alihammoud21.gtavmobile;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import java.io.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.json.JSONObject;

/** Imports through the system document picker; no broad storage permission. */
public final class LauncherActivity extends Activity {
    static { System.loadLibrary("gtav_mobile"); }
    private static native String importGame(String archive, String destination);
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private TextView status;
    private Button play, importer;
    private EditText server, player;
    private Switch multiplayer, host;
    private Spinner mode;
    private boolean importing;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        int pad = (int)(24 * getResources().getDisplayMetrics().density);
        layout.setPadding(pad, pad * 2, pad, pad);
        ScrollView scroll = new ScrollView(this); scroll.addView(layout); setContentView(scroll);
        TextView title = new TextView(this); title.setText("GTAV Mobile"); title.setTextSize(32); layout.addView(title);
        TextView intro = new TextView(this);
        intro.setText("Your game. On the move.\nImport your own compatible game ZIP to get started.");
        intro.setPadding(0, pad, 0, pad); layout.addView(intro);
        status = new TextView(this); layout.addView(status);
        importer = new Button(this); importer.setText("Import game ZIP"); layout.addView(importer);
        importer.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("*/*").addCategory(Intent.CATEGORY_OPENABLE);
            startActivityForResult(intent, 1);
        });
        mode = new Spinner(this);
        mode.setAdapter(new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, new String[]{"Story", "Sandbox"}));
        mode.setSelection(1); layout.addView(mode);
        multiplayer = new Switch(this); multiplayer.setText("Multiplayer"); layout.addView(multiplayer);
        host = new Switch(this); host.setText("Host a session"); layout.addView(host);
        server = new EditText(this); server.setHint("Server address (host:47520)"); server.setSingleLine(); layout.addView(server);
        player = new EditText(this); player.setHint("Player name"); player.setSingleLine(); layout.addView(player);
        loadSettings();
        play = new Button(this); play.setText("Play"); layout.addView(play);
        play.setOnClickListener(v -> {
            try {
                if (multiplayer.isChecked() && !host.isChecked() && server.getText().toString().trim().isEmpty()) {
                    status.setText("Enter a server address, or turn on Host a session."); return;
                }
                JSONObject config = new JSONObject();
                config.put("scale", 0.5); config.put("fullscreen", true); config.put("fps_limit", 30);
                config.put("start_mode", mode.getSelectedItemPosition() + 1);
                config.put("multiplayer", multiplayer.isChecked()); config.put("host", host.isChecked());
                config.put("server", server.getText().toString().trim()); config.put("player_name", player.getText().toString().trim());
                try (FileWriter writer = new FileWriter(new File(getFilesDir(), "config.json"))) { writer.write(config.toString()); }
                startActivity(new Intent(this, GameActivity.class));
            } catch (Exception error) { status.setText("Could not start: " + error.getMessage()); }
        });
        refresh();
    }

    @Override protected void onResume() {
        super.onResume();
        File error = new File(getFilesDir(), "last-error.txt");
        if (error.isFile()) {
            try {
                status.setText("Game could not start: " + new String(java.nio.file.Files.readAllBytes(error.toPath()), java.nio.charset.StandardCharsets.UTF_8));
                error.delete();
            } catch (IOException ignored) { status.setText("Game could not start. Check runtime.log for details."); }
        }
    }
    private void loadSettings() {
        try {
            JSONObject config = new JSONObject(new String(java.nio.file.Files.readAllBytes(new File(getFilesDir(), "config.json").toPath()), java.nio.charset.StandardCharsets.UTF_8));
            mode.setSelection(config.optInt("start_mode", 2) == 1 ? 0 : 1);
            multiplayer.setChecked(config.optBoolean("multiplayer")); host.setChecked(config.optBoolean("host"));
            server.setText(config.optString("server")); player.setText(config.optString("player_name"));
        } catch (Exception ignored) { /* First launch uses defaults. */ }
    }
    private boolean ready() {
        File game = new File(getFilesDir(), "game");
        if (!new File(game, "data/manifest.json").isFile()) return false;
        File[] builds = new File(game, "b").listFiles();
        if (builds != null) for (File build : builds) {
            if (new File(build, "game.wasm").isFile() && new File(build, "shaders/index.json").isFile()) return true;
        }
        return false;
    }
    private void refresh() {
        play.setEnabled(!importing && ready()); importer.setEnabled(!importing);
        if (!importing) status.setText(ready() ? "Ready. First launch compiles the game and can take several minutes." : "No game files imported yet.");
    }
    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != 1 || result != RESULT_OK || data == null || data.getData() == null) return;
        Uri uri = data.getData(); importing = true; refresh(); status.setText("Importing… Keep this app open.");
        // Prevent rotation from destroying the import UI while its worker is active.
        setRequestedOrientation(android.content.pm.ActivityInfo.SCREEN_ORIENTATION_LOCKED);
        worker.execute(() -> {
            File archive = new File(getCacheDir(), "game-import.zip");
            String error = null;
            try {
                try (InputStream in = getContentResolver().openInputStream(uri); OutputStream out = new FileOutputStream(archive)) {
                    if (in == null) throw new IOException("Cannot open selected file");
                    byte[] buffer = new byte[1024 * 1024]; int count;
                    while ((count = in.read(buffer)) != -1) out.write(buffer, 0, count);
                }
                error = importGame(archive.getAbsolutePath(), new File(getFilesDir(), "game").getAbsolutePath());
                if (error == null) error = "Native importer could not return a result";
            } catch (Exception failure) { error = failure.getMessage(); if (error == null) error = failure.toString(); }
            finally { archive.delete(); }
            final String message = error;
            runOnUiThread(() -> {
                if (isDestroyed()) return;
                importing = false; refresh();
                if (message != null && !message.isEmpty()) status.setText("Import failed: " + message);
                setRequestedOrientation(android.content.pm.ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
            });
        });
    }
    @Override public void onBackPressed() {
        if (importing) { status.setText("Please wait for the import to finish."); return; }
        super.onBackPressed();
    }
    @Override protected void onDestroy() { worker.shutdown(); super.onDestroy(); }
}
