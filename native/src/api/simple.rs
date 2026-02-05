use anyhow::Result;
use flutter_rust_bridge::frb;
use std::fs;

#[frb]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[frb]
pub fn init_app() {}

#[frb]
pub fn read_file(path: String) -> Result<String> {
    Ok(fs::read_to_string(path)?)
}

#[frb]
pub fn save_file(path: String, content: String) -> Result<()> {
    fs::write(path, content)?;
    Ok(())
}
