//! Android activity entry point and launcher/input bridge.
use jni::{
    objects::{JClass, JString},
    sys::{jboolean, jfloat, jint, jstring},
    JNIEnv,
};
use std::collections::HashSet;
use std::sync::{Mutex, OnceLock};
use winit::platform::android::activity::AndroidApp;

pub static APP: OnceLock<AndroidApp> = OnceLock::new();
static KEYS: Mutex<Option<HashSet<String>>> = Mutex::new(None);

#[no_mangle]
fn android_main(app: AndroidApp) {
    let log = app.internal_data_path().map(|p| p.join("runtime.log"));
    if let Some(path) = log {
        if let Ok(file) = std::fs::File::create(path) {
            use std::os::fd::AsRawFd;
            unsafe {
                libc::dup2(file.as_raw_fd(), 1);
                libc::dup2(file.as_raw_fd(), 2);
            }
        }
    }
    if APP.set(app).is_err() {
        return;
    }
    if let Err(error) = crate::run() {
        fail(&format!("{error:#}"));
    }
    // The game owns detached worker threads. A separate :game process allows a
    // clean restart without leaving them alive in the launcher process.
    std::process::exit(0);
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_LauncherActivity_importGame(
    mut env: JNIEnv,
    _class: JClass,
    archive: JString,
    destination: JString,
) -> jstring {
    let result = (|| -> anyhow::Result<()> {
        let archive: String = env.get_string(&archive)?.into();
        let destination: String = env.get_string(&destination)?.into();
        crate::import::import(
            std::path::Path::new(&archive),
            std::path::Path::new(&destination),
            true,
            |_, _| {},
        )
    })();
    let message = result.err().map(|e| format!("{e:#}")).unwrap_or_default();
    env.new_string(message)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_GameActivity_nativeKey(
    mut env: JNIEnv,
    _class: JClass,
    name: JString,
    down: jboolean,
) {
    let Ok(name) = env.get_string(&name) else {
        return;
    };
    let name: String = name.into();
    let pressed = down != 0;
    if pressed && !crate::pad::FOCUSED.load(std::sync::atomic::Ordering::Relaxed) {
        return;
    }
    let mut guard = KEYS.lock().unwrap();
    let keys = guard.get_or_insert_with(HashSet::new);
    let changed = if pressed {
        keys.insert(name.clone())
    } else {
        keys.remove(&name)
    };
    if changed {
        crate::input::set_locked(true);
        if pressed {
            crate::mp::key_pressed(&name);
        }
        crate::input::key(&name, pressed, false, None, false);
    }
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_GameActivity_nativeLook(
    _env: JNIEnv,
    _class: JClass,
    dx: jfloat,
    dy: jfloat,
) {
    if crate::pad::FOCUSED.load(std::sync::atomic::Ordering::Relaxed)
        && dx.is_finite()
        && dy.is_finite()
    {
        crate::input::set_locked(true);
        crate::input::mouse_delta_f(dx as f64, dy as f64);
    }
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_GameActivity_nativeButton(
    _env: JNIEnv,
    _class: JClass,
    button: jint,
    down: jboolean,
) {
    if (0..=2).contains(&button) {
        crate::input::button(button as usize, down != 0);
    }
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_GameActivity_nativeRelease(
    _env: JNIEnv,
    _class: JClass,
) {
    release_input();
}

pub fn release_input() {
    if let Some(keys) = KEYS.lock().unwrap().take() {
        for key in keys {
            crate::input::key(&key, false, false, None, false);
        }
    }
    for button in 0..=2 {
        crate::input::button(button, false);
    }
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_GameActivity_nativeInVehicle(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    crate::pad::IN_VEHICLE.load(std::sync::atomic::Ordering::Relaxed) as jboolean
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_GameActivity_nativeHorn(
    _env: JNIEnv,
    _class: JClass,
    down: jboolean,
) {
    crate::pad::HORN_TOUCH.store(down != 0, std::sync::atomic::Ordering::Relaxed);
}

pub fn fail(message: &str) -> ! {
    eprintln!("[android] {message}");
    if let Some(path) = APP.get().and_then(|app| app.internal_data_path()) {
        let _ = std::fs::write(path.join("last-error.txt"), message);
    }
    std::process::exit(1);
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_GameActivity_nativeLoading(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    (crate::gpu::PRESENTS.load(std::sync::atomic::Ordering::Relaxed) == 0) as jboolean
}

#[no_mangle]
pub extern "system" fn Java_com_alihammoud21_gtavmobile_LauncherActivity_gameSetup(
    mut env: JNIEnv,
    _class: JClass,
    destination: JString,
    archive: JString,
    index: jint,
) -> jstring {
    let result = (|| -> anyhow::Result<String> {
        let destination: String = env.get_string(&destination)?.into();
        let dest = std::path::Path::new(&destination);
        if index == -2 {
            return Ok(crate::game_data::status(dest, true));
        }
        if index == -1 {
            crate::game_data::finish(dest, true)?;
        } else {
            let archive: String = env.get_string(&archive)?.into();
            crate::game_data::install_part(
                dest,
                std::path::Path::new(&archive),
                index as usize,
                true,
            )?;
        }
        Ok(String::new())
    })();
    let message = result.unwrap_or_else(|e| format!("{e:#}"));
    env.new_string(message)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}
