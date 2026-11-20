//! Social share card rendering (the Rust replacement for the ImageMagick pipeline in
//! `Images::GenerateSocialImageMagickally`).
//!
//! Every stage ports the ImageMagick 6 algorithm the Ruby service used to shell out to,
//! so cards keep the same geometry, typography, and colors while rendering in-process with
//! no subprocesses, temp files, or ImageMagick dependency.

pub mod avatar;
pub mod canvas;
pub mod card;
pub mod decode;
pub mod draw;
pub mod filter;
pub mod text;

pub use canvas::{Canvas, Rgba};
pub use decode::decode_image;
pub use text::Font;

/// Errors surfaced to Ruby as exceptions.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SocialImageError {
    InvalidFont(String),
    InvalidImage(String),
    InvalidColor(String),
    Encode(String),
}

impl std::fmt::Display for SocialImageError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SocialImageError::InvalidFont(m) => write!(f, "invalid font: {m}"),
            SocialImageError::InvalidImage(m) => write!(f, "invalid image: {m}"),
            SocialImageError::InvalidColor(m) => write!(f, "invalid color: {m}"),
            SocialImageError::Encode(m) => write!(f, "failed to encode PNG: {m}"),
        }
    }
}

impl std::error::Error for SocialImageError {}

/// Encodes `canvas` as an 8-bit RGB PNG (`-alpha off -depth 8`, then PNG).
pub fn encode_png(canvas: &Canvas) -> Result<Vec<u8>, SocialImageError> {
    let mut out = Vec::new();
    {
        let mut encoder = png::Encoder::new(&mut out, canvas.width as u32, canvas.height as u32);
        encoder.set_color(png::ColorType::Rgb);
        encoder.set_depth(png::BitDepth::Eight);
        encoder.set_compression(png::Compression::Balanced);
        let mut writer = encoder
            .write_header()
            .map_err(|e| SocialImageError::Encode(e.to_string()))?;
        writer
            .write_image_data(&canvas.to_rgb8())
            .map_err(|e| SocialImageError::Encode(e.to_string()))?;
    }
    Ok(out)
}

/// Encodes `canvas` as an 8-bit RGBA PNG when `canvas.has_alpha` is true, or an 8-bit RGB PNG
/// when opaque, preserving transparency for logos, favicons, and PNG uploads.
pub fn encode_png_preserving_alpha(canvas: &Canvas) -> Result<Vec<u8>, SocialImageError> {
    if !canvas.has_alpha {
        return encode_png(canvas);
    }
    let mut out = Vec::new();
    {
        let mut encoder = png::Encoder::new(&mut out, canvas.width as u32, canvas.height as u32);
        encoder.set_color(png::ColorType::Rgba);
        encoder.set_depth(png::BitDepth::Eight);
        encoder.set_compression(png::Compression::Balanced);
        let mut writer = encoder
            .write_header()
            .map_err(|e| SocialImageError::Encode(e.to_string()))?;
        writer
            .write_image_data(&canvas.to_rgba8())
            .map_err(|e| SocialImageError::Encode(e.to_string()))?;
    }
    Ok(out)
}
