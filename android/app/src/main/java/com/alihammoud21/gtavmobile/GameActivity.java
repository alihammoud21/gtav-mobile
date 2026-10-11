package com.alihammoud21.gtavmobile;

import android.app.NativeActivity;
import android.os.Bundle;
import android.graphics.*;
import android.view.*;
import java.util.*;

/** Native renderer plus multitouch controls and standard Android gamepad input. */
public final class GameActivity extends NativeActivity {
    static { System.loadLibrary("gtav_mobile"); }
    private static native void nativeKey(String key, boolean down);
    private static native void nativeLook(float dx, float dy);
    private static native void nativeButton(int button, boolean down);
    private static native void nativeRelease();
    private static native boolean nativeInVehicle();
    private static native boolean nativeLoading();
    private static native void nativeHorn(boolean down);
    private final Map<String, Set<String>> held = new HashMap<>();
    private Controls controls;
    private android.widget.PopupWindow overlay;
    private boolean active;
    private float lookX, lookY;
    private final android.os.Handler handler = new android.os.Handler(android.os.Looper.getMainLooper());
    private final Runnable lookTick = new Runnable() {
        @Override public void run() {
            if (!active) return;
            if (Math.abs(lookX) > .15f || Math.abs(lookY) > .15f) nativeLook(lookX * 12, lookY * 12);
            handler.postDelayed(this, 16);
        }
    };
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        // Keep Java input dispatch: winit otherwise consumes the native input queue
        // before the touch overlay or gamepad handlers can receive events.
        getWindow().takeInputQueue(null);
        controls = new Controls();
        // NativeActivity owns the main surface. Draw controls in their own window.
        overlay = new android.widget.PopupWindow(controls, -1, -1, false);
        overlay.setBackgroundDrawable(new android.graphics.drawable.ColorDrawable(Color.TRANSPARENT));
        overlay.setClippingEnabled(false);
        overlay.setInputMethodMode(android.widget.PopupWindow.INPUT_METHOD_NOT_NEEDED);
    }
    @Override protected void onResume() {
        super.onResume(); active = true;
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        handler.post(lookTick);
        getWindow().getDecorView().post(() -> {
            if (active && !isFinishing() && !overlay.isShowing()) overlay.showAtLocation(getWindow().getDecorView(), Gravity.TOP | Gravity.START, 0, 0);
        });
    }
    @Override protected void onPause() {
        overlay.dismiss();
        active = false; handler.removeCallbacks(lookTick); lookX = lookY = 0;
        held.clear(); controls.contacts.clear(); nativeRelease(); nativeHorn(false);
        super.onPause();
    }
    private void key(String source, String key, boolean down) {
        if (!active) return;
        Set<String> owners = held.computeIfAbsent(key, k -> new HashSet<>());
        boolean before = !owners.isEmpty();
        if (down) owners.add(source); else owners.remove(source);
        boolean after = !owners.isEmpty();
        if (before != after) {
            if (key.equals("Fire")) nativeButton(0, after);
            else if (key.equals("Aim")) nativeButton(2, after);
            else if (key.equals("Horn")) nativeHorn(after);
            else nativeKey(key, after);
        }
    }
    private void release(String source) {
        for (String key : new ArrayList<>(held.keySet())) key(source, key, false);
    }
    private void stick(String source, float x, float y) {
        key(source, "KeyA", x < -.25f); key(source, "KeyD", x > .25f);
        key(source, "KeyW", y < -.25f); key(source, "KeyS", y > .25f);
    }
    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        if ((event.getSource() & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD || (event.getSource() & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK) {
            String key = switch (event.getKeyCode()) {
                case KeyEvent.KEYCODE_BUTTON_A -> "Enter";
                case KeyEvent.KEYCODE_BUTTON_B -> "Backspace";
                case KeyEvent.KEYCODE_BUTTON_X -> "Space";
                case KeyEvent.KEYCODE_BUTTON_Y -> "KeyF";
                case KeyEvent.KEYCODE_BUTTON_L1 -> "Tab";
                case KeyEvent.KEYCODE_BUTTON_R1 -> "KeyQ";
                case KeyEvent.KEYCODE_BUTTON_START -> "Escape";
                case KeyEvent.KEYCODE_BUTTON_SELECT -> "KeyV";
                case KeyEvent.KEYCODE_BUTTON_THUMBL -> "ControlLeft";
                case KeyEvent.KEYCODE_BUTTON_THUMBR -> "KeyC";
                case KeyEvent.KEYCODE_DPAD_UP -> "ArrowUp";
                case KeyEvent.KEYCODE_DPAD_DOWN -> "ArrowDown";
                case KeyEvent.KEYCODE_DPAD_LEFT -> "ArrowLeft";
                case KeyEvent.KEYCODE_DPAD_RIGHT -> "ArrowRight";
                default -> null;
            };
            if (key != null) {
                key("pad-key-" + event.getKeyCode(), key, event.getAction() == KeyEvent.ACTION_DOWN);
                return true;
            }
        }
        if (event.getKeyCode() == KeyEvent.KEYCODE_BACK) {
            if (event.getAction() == KeyEvent.ACTION_UP) onBackPressed();
            return true;
        }
        String keyboard = keyboardKey(event.getKeyCode());
        if (keyboard != null) {
            key("keyboard-" + event.getKeyCode(), keyboard, event.getAction() == KeyEvent.ACTION_DOWN);
            return true;
        }
        // Bypass NativeActivity.dispatchKeyEvent, which would redirect to the
        // disabled native queue. Activity's KeyEvent callbacks handle volume.
        return event.dispatch(this);
    }
    private static String keyboardKey(int code) {
        if (code >= KeyEvent.KEYCODE_A && code <= KeyEvent.KEYCODE_Z) return "Key" + (char)('A' + code - KeyEvent.KEYCODE_A);
        if (code >= KeyEvent.KEYCODE_0 && code <= KeyEvent.KEYCODE_9) return "Digit" + (code - KeyEvent.KEYCODE_0);
        return switch (code) {
            case KeyEvent.KEYCODE_ENTER -> "Enter";
            case KeyEvent.KEYCODE_ESCAPE -> "Escape";
            case KeyEvent.KEYCODE_SPACE -> "Space";
            case KeyEvent.KEYCODE_TAB -> "Tab";
            case KeyEvent.KEYCODE_DEL -> "Backspace";
            case KeyEvent.KEYCODE_SHIFT_LEFT, KeyEvent.KEYCODE_SHIFT_RIGHT -> "ShiftLeft";
            case KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_CTRL_RIGHT -> "ControlLeft";
            case KeyEvent.KEYCODE_ALT_LEFT, KeyEvent.KEYCODE_ALT_RIGHT -> "AltLeft";
            case KeyEvent.KEYCODE_DPAD_UP -> "ArrowUp";
            case KeyEvent.KEYCODE_DPAD_DOWN -> "ArrowDown";
            case KeyEvent.KEYCODE_DPAD_LEFT -> "ArrowLeft";
            case KeyEvent.KEYCODE_DPAD_RIGHT -> "ArrowRight";
            default -> null;
        };
    }
    @Override public boolean onGenericMotionEvent(MotionEvent event) {
        if ((event.getSource() & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK) {
            stick("pad-stick", event.getAxisValue(MotionEvent.AXIS_X), event.getAxisValue(MotionEvent.AXIS_Y));
            lookX = event.getAxisValue(MotionEvent.AXIS_Z); lookY = event.getAxisValue(MotionEvent.AXIS_RZ);
            float rt = Math.max(event.getAxisValue(MotionEvent.AXIS_RTRIGGER), event.getAxisValue(MotionEvent.AXIS_GAS));
            float lt = Math.max(event.getAxisValue(MotionEvent.AXIS_LTRIGGER), event.getAxisValue(MotionEvent.AXIS_BRAKE));
            boolean car = nativeInVehicle();
            key("pad-trigger", "Fire", !car && rt > .2f); key("pad-trigger", "Aim", !car && lt > .2f);
            key("pad-trigger", "KeyW", car && rt > .2f); key("pad-trigger", "KeyS", car && lt > .2f);
            float hx = event.getAxisValue(MotionEvent.AXIS_HAT_X), hy = event.getAxisValue(MotionEvent.AXIS_HAT_Y);
            key("pad-hat", "ArrowLeft", hx < -.5f); key("pad-hat", "ArrowRight", hx > .5f);
            key("pad-hat", "ArrowUp", hy < -.5f); key("pad-hat", "ArrowDown", hy > .5f);
            return true;
        }
        return super.onGenericMotionEvent(event);
    }
    @Override public void onBackPressed() {
        new android.app.AlertDialog.Builder(this).setMessage("Leave the game?")
            .setNegativeButton("Stay", null).setPositiveButton("Leave", (d, w) -> finish()).show();
    }

    private final class Controls extends View {
        final Map<Integer, Contact> contacts = new HashMap<>();
        final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        final String[] labels = {"PAUSE", "PHONE", "WEAPON", "CAM", "SWITCH", "◀", "▲", "▼", "▶", "OK", "BACK", "FIRE", "AIM", "JUMP", "ENTER", "RUN", "RELOAD"};
        final String[] actions = {"Escape", "ArrowUp", "Tab", "KeyV", "AltLeft", "ArrowLeft", "ArrowUp", "ArrowDown", "ArrowRight", "Enter", "Backspace", "Fire", "Aim", "Space", "KeyF", "ShiftLeft", "KeyR"};
        Controls() { super(GameActivity.this); setFocusable(false); setContentDescription("Game controls: left stick moves, drag the right side to look, buttons perform actions"); }
        float unit() { return Math.min(getHeight() / 8f, getWidth() / 16f); }
        RectF box(int i) {
            float u = unit();
            if (i < 11) { float width = getWidth() / 11f; return new RectF(i * width + 2, 6, (i + 1) * width - 2, u * .8f); }
            int n = i - 11;
            float x = getWidth() - (3 - n % 3) * u * 1.1f;
            float y = getHeight() - (2 - n / 3) * u * 1.05f;
            return new RectF(x, y, x + u, y + u * .9f);
        }
        @Override protected void onDraw(Canvas canvas) {
            boolean car = nativeInVehicle();
            for (int i = 0; i < labels.length; i++) {
                RectF rect = box(i); paint.setColor(0x66464D48); canvas.drawRoundRect(rect, 16, 16, paint);
                paint.setColor(0xEEFFFFFF); paint.setTextSize(unit() * .18f); paint.setTextAlign(Paint.Align.CENTER);
                String label = car && i == 11 ? "GAS" : car && i == 12 ? "BRAKE" : car && i == 16 ? "HORN" : labels[i];
                canvas.drawText(label, rect.centerX(), rect.centerY() + paint.getTextSize() / 3, paint);
            }
            if (nativeLoading()) {
                paint.setColor(0xEE141815);
                canvas.drawRoundRect(new RectF(getWidth() * .2f, getHeight() * .35f, getWidth() * .8f, getHeight() * .6f), 20, 20, paint);
                paint.setColor(Color.WHITE); paint.setTextAlign(Paint.Align.CENTER); paint.setTextSize(unit() * .28f);
                canvas.drawText("Preparing your game…", getWidth() / 2f, getHeight() * .45f, paint);
                paint.setTextSize(unit() * .18f);
                canvas.drawText("First launch can take several minutes.", getWidth() / 2f, getHeight() * .52f, paint);
            }
            paint.setColor(0x55464D48); canvas.drawCircle(unit() * 1.5f, getHeight() - unit() * 1.5f, unit(), paint);
            paint.setColor(0xBBFFFFFF); paint.setTextSize(unit() * .2f);
            canvas.drawText("MOVE", unit() * 1.5f, getHeight() - unit() * 1.5f, paint);
            postInvalidateDelayed(250);
        }
        @Override public boolean onTouchEvent(MotionEvent e) {
            int action = e.getActionMasked(), index = e.getActionIndex();
            if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
                int id = e.getPointerId(index); float x = e.getX(index), y = e.getY(index);
                Contact c = new Contact(x, y); contacts.put(id, c);
                for (int i = 0; i < actions.length; i++) if (box(i).contains(x, y)) {
                    c.action = nativeInVehicle() && i == 11 ? "KeyW" : nativeInVehicle() && i == 12 ? "KeyS" : nativeInVehicle() && i == 16 ? "Horn" : actions[i];
                    key("touch-" + id, c.action, true); return true;
                }
                c.move = x < getWidth() * .35f;
            } else if (action == MotionEvent.ACTION_MOVE) {
                for (int i = 0; i < e.getPointerCount(); i++) {
                    int id = e.getPointerId(i); Contact c = contacts.get(id); if (c == null || c.action != null) continue;
                    float x = e.getX(i), y = e.getY(i);
                    if (c.move) stick("touch-" + id, (x - c.x) / unit(), (y - c.y) / unit());
                    else { nativeLook((x - c.x) * 2, (y - c.y) * 2); c.x = x; c.y = y; }
                }
            } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP) {
                int id = e.getPointerId(index); release("touch-" + id); contacts.remove(id); performClick();
            } else if (action == MotionEvent.ACTION_CANCEL) {
                for (Integer id : contacts.keySet()) release("touch-" + id); contacts.clear();
            }
            return true;
        }
        @Override public boolean performClick() { super.performClick(); return true; }
    }
    private static final class Contact {
        float x, y; boolean move; String action;
        Contact(float x, float y) { this.x = x; this.y = y; }
    }
}
