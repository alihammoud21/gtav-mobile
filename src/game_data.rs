//! Pinned, resumable game setup shared by the iOS and Android launchers.
use anyhow::{bail, Context, Result};
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::{
    fs::{self, File},
    io::{Read, Write},
    path::Path,
};

pub const MANIFEST: &str = include_str!("../distribution/game-manifest.json");
fn manifest() -> Value {
    serde_json::from_str(MANIFEST).expect("bundled game manifest")
}
fn staging(dest: &Path) -> std::path::PathBuf {
    dest.with_extension("download-8b0b5899ed")
}
fn hash_file(path: &Path) -> Result<String> {
    let mut input = File::open(path)?;
    let mut hash = Sha256::new();
    let mut buffer = vec![0; 1 << 20];
    loop {
        let n = input.read(&mut buffer)?;
        if n == 0 {
            break;
        }
        hash.update(&buffer[..n]);
    }
    Ok(format!("{:x}", hash.finalize()))
}
fn wanted(file: &Value, keep_code: bool) -> bool {
    keep_code || !file["relative"].as_str().unwrap().ends_with("game.wasm")
}
fn marker(root: &Path, index: usize, keep_code: bool) -> std::path::PathBuf {
    root.join(format!(
        ".part-{index}-{}",
        if keep_code { "android" } else { "ios" }
    ))
}
pub fn status(dest: &Path, keep_code: bool) -> String {
    let mut m = manifest();
    for (i, p) in m["parts"].as_array_mut().unwrap().iter_mut().enumerate() {
        p["done"] = Value::Bool(
            fs::read_to_string(marker(&staging(dest), i, keep_code))
                .ok()
                .as_deref()
                == p["sha256"].as_str(),
        );
    }
    m.as_object_mut().unwrap().remove("files");
    m.to_string()
}
fn extract(
    archive: &Path,
    root: &Path,
    part: &Value,
    files: &[Value],
    keep_code: bool,
) -> Result<()> {
    if fs::metadata(archive)?.len() != part["bytes"].as_u64().context("part size")? {
        bail!("Incomplete download; retry setup");
    }
    if hash_file(archive)? != part["sha256"].as_str().context("part hash")? {
        bail!("Download checksum failed; retry setup");
    }
    let mut zip = zip::ZipArchive::new(std::io::BufReader::new(File::open(archive)?))?;
    let mut buffer = vec![0; 1 << 20];
    for f in files
        .iter()
        .filter(|f| f["part"] == part["name"] && wanted(f, keep_code))
    {
        let rel = f["relative"].as_str().context("file path")?;
        if rel.starts_with('/')
            || rel.contains('\\')
            || rel.contains(':')
            || rel
                .split('/')
                .any(|c| c == ".." || c == "." || c.is_empty())
        {
            bail!("Unsafe game path");
        }
        let mut entry = zip.by_name(f["path"].as_str().context("archive path")?)?;
        if entry.is_symlink() || entry.size() != f["bytes"].as_u64().context("file size")? {
            bail!("Invalid game file: {rel}");
        }
        let output = root.join(rel);
        fs::create_dir_all(output.parent().unwrap())?;
        let temp = output.with_extension("downloading");
        let mut out = File::create(&temp)?;
        let mut hash = Sha256::new();
        loop {
            let n = entry.read(&mut buffer)?;
            if n == 0 {
                break;
            }
            out.write_all(&buffer[..n])?;
            hash.update(&buffer[..n]);
        }
        out.sync_all()?;
        if format!("{:x}", hash.finalize()) != f["sha256"].as_str().context("file hash")? {
            fs::remove_file(temp)?;
            bail!("Game file checksum failed: {rel}");
        }
        fs::rename(temp, output)?;
    }
    Ok(())
}
pub fn install_part(dest: &Path, archive: &Path, index: usize, keep_code: bool) -> Result<()> {
    let m = manifest();
    let part = m["parts"]
        .as_array()
        .unwrap()
        .get(index)
        .context("Unknown download part")?;
    let root = staging(dest);
    fs::create_dir_all(&root)?;
    extract(
        archive,
        &root,
        part,
        m["files"].as_array().unwrap(),
        keep_code,
    )?;
    fs::write(
        marker(&root, index, keep_code),
        part["sha256"].as_str().unwrap(),
    )?;
    Ok(())
}
pub fn finish(dest: &Path, keep_code: bool) -> Result<()> {
    let m = manifest();
    let root = staging(dest);
    for (i, p) in m["parts"].as_array().unwrap().iter().enumerate() {
        if fs::read_to_string(marker(&root, i, keep_code))
            .ok()
            .as_deref()
            != p["sha256"].as_str()
        {
            bail!("Setup is incomplete; resume the download");
        }
    }
    // Recheck staged content on resume, including when the process was interrupted.
    for f in m["files"]
        .as_array()
        .unwrap()
        .iter()
        .filter(|f| wanted(f, keep_code))
    {
        let file = root.join(f["relative"].as_str().unwrap());
        if hash_file(&file).ok().as_deref() != f["sha256"].as_str() {
            let index = m["parts"]
                .as_array()
                .unwrap()
                .iter()
                .position(|p| p["name"] == f["part"])
                .unwrap();
            let _ = fs::remove_file(marker(&root, index, keep_code));
            bail!("A game file needs repair; tap Download game again");
        }
    }
    crate::import::tidy_lists(&root.join("data"))?;
    let backup = dest.with_extension("previous");
    if backup.exists() && !dest.exists() {
        fs::rename(&backup, dest)?;
    }
    if backup.exists() {
        fs::remove_dir_all(&backup)?;
    }
    let had_game = dest.exists();
    if had_game {
        fs::rename(dest, &backup)?;
    }
    if let Err(error) = fs::rename(&root, dest) {
        if had_game {
            fs::rename(&backup, dest).context("Restoring previous installation")?;
        }
        return Err(error.into());
    }
    if had_game {
        let _ = fs::remove_dir_all(backup);
    }
    Ok(())
}

#[cfg(target_os = "ios")]
mod ios {
    use super::*;
    use std::{
        ffi::{c_char, CStr, CString},
        sync::Mutex,
    };
    static RESPONSE: Mutex<Option<CString>> = Mutex::new(None);
    #[no_mangle]
    pub extern "C" fn gtav_setup(index: i32, archive: *const c_char) -> *const c_char {
        let dest = crate::config::game_dir();
        let message = if index == -2 {
            status(&dest, false)
        } else {
            let result = if index == -1 {
                finish(&dest, false)
            } else if archive.is_null() {
                Err(anyhow::anyhow!("Missing download"))
            } else {
                let path = unsafe { CStr::from_ptr(archive) }.to_string_lossy();
                install_part(&dest, Path::new(path.as_ref()), index as usize, false)
            };
            result.err().map(|e| format!("{e:#}")).unwrap_or_default()
        };
        let mut response = RESPONSE.lock().unwrap();
        *response = Some(CString::new(message.replace('\0', "")).unwrap());
        response.as_ref().unwrap().as_ptr()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn pinned_manifest_is_complete_and_paths_are_safe() {
        let m = manifest();
        let parts = m["parts"].as_array().unwrap();
        assert_eq!(parts.len(), 11);
        let mut seen = std::collections::HashSet::new();
        for f in m["files"].as_array().unwrap() {
            let p = f["relative"].as_str().unwrap();
            assert!(!p.starts_with('/') && !p.contains("..") && !p.contains('\\'));
            assert!(seen.insert(p));
            assert!(parts.iter().any(|part| part["name"] == f["part"]));
        }
        assert!(seen.contains("data/manifest.json"));
        assert!(seen.contains("b/8b0b5899ed/game.wasm"));
    }
    #[test]
    fn resumes_only_parts_with_matching_completion_hashes() {
        let dest = std::env::temp_dir()
            .join(format!("gtav-resume-test-{}", std::process::id()))
            .join("game");
        let root = staging(&dest);
        fs::create_dir_all(&root).unwrap();
        let m = manifest();
        fs::write(
            marker(&root, 0, true),
            m["parts"][0]["sha256"].as_str().unwrap(),
        )
        .unwrap();
        fs::write(marker(&root, 1, true), "wrong").unwrap();
        let android: Value = serde_json::from_str(&status(&dest, true)).unwrap();
        assert_eq!(android["parts"][0]["done"], true);
        assert_eq!(android["parts"][1]["done"], false);
        assert!(android.get("files").is_none());
        let ios: Value = serde_json::from_str(&status(&dest, false)).unwrap();
        assert_eq!(ios["parts"][0]["done"], false);
        assert!(install_part(&dest, Path::new("missing.zip"), 14, true).is_err());
        fs::remove_dir_all(dest.parent().unwrap()).unwrap();
    }
    #[test]
    fn extraction_checks_hashes_and_keeps_previous_install() {
        let root = std::env::temp_dir().join(format!("gtav-download-test-{}", std::process::id()));
        fs::create_dir_all(&root).unwrap();
        let archive = root.join("part.zip");
        let mut zip = zip::ZipWriter::new(File::create(&archive).unwrap());
        zip.start_file("mirror/data/test", zip::write::SimpleFileOptions::default())
            .unwrap();
        zip.write_all(b"hello").unwrap();
        zip.finish().unwrap();
        let part = serde_json::json!({"name":"part.zip","bytes":fs::metadata(&archive).unwrap().len(),"sha256":hash_file(&archive).unwrap()});
        let mut bad_part = part.clone();
        bad_part["sha256"] = Value::String("wrong".into());
        assert!(extract(&archive, &root.join("bad"), &bad_part, &[], true).is_err());
        let mut f = serde_json::json!({"part":"part.zip","path":"mirror/data/test","relative":"data/test","bytes":5,"sha256":format!("{:x}",Sha256::digest(b"hello"))});
        let dest = root.join("game");
        fs::create_dir_all(&dest).unwrap();
        fs::write(dest.join("existing"), "keep").unwrap();
        extract(&archive, &staging(&dest), &part, &[f.clone()], true).unwrap();
        assert_eq!(
            fs::read(staging(&dest).join("data/test")).unwrap(),
            b"hello"
        );
        f["sha256"] = Value::String("bad".into());
        assert!(extract(&archive, &staging(&dest), &part, &[f.clone()], true).is_err());
        f["relative"] = Value::String("../escape".into());
        assert!(extract(&archive, &staging(&dest), &part, &[f], true).is_err());
        assert!(finish(&dest, true).is_err());
        assert_eq!(fs::read_to_string(dest.join("existing")).unwrap(), "keep");
        fs::remove_dir_all(root).unwrap();
    }
}
