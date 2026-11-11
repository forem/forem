//! Pure-Rust image inspection, frame counting, lossless container metadata stripping,
//! EXIF auto-orientation, CarrierWave version resizing (`resize_to_fill` / `resize_to_limit`),
//! SVG-to-PNG rasterization (`LogoSvgUploader`), and subforem image compositing
//! (`Images::GenerateSubforemImages`).
//!
//! Replaces all remaining `MiniMagick` / ImageMagick CLI (`identify`, `mogrify`, `convert`,
//! `composite`) subprocesses across Forem with zero external system dependencies.

use std::borrow::Cow;
use std::collections::HashMap;

use crate::social_image::canvas::{quantize8, Canvas, Rgba};
use crate::social_image::decode::decode_image;
use crate::social_image::draw::{
    circle, draw_subpaths_styled, ellipse, line, parse_svg_path, polygon, polyline, rectangle,
    round_rectangle, FillRule, LineCap, LineJoin, Point, StrokeStyle, Subpath,
};
use crate::social_image::encode_png_preserving_alpha;
use crate::social_image::filter::{resize, resize_fit, ResizeFilter};
use crate::social_image::text::{render_label, Font};

/// Matches `BaseUploader` (`CarrierWave::BombShelter`) 4096x4096 pixel-dimension cap.
pub const MAX_PIXEL_DIMENSION: u32 = 4_096;
const MAX_TIFF_IFDS: usize = 10_000;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ImageFormat {
    Jpeg,
    Png,
    Gif,
    Webp,
    Bmp,
    Ico,
    Tiff,
    Svg,
}

impl ImageFormat {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Jpeg => "jpeg",
            Self::Png => "png",
            Self::Gif => "gif",
            Self::Webp => "webp",
            Self::Bmp => "bmp",
            Self::Ico => "ico",
            Self::Tiff => "tiff",
            Self::Svg => "svg",
        }
    }

    pub const fn default_extension(self) -> &'static str {
        match self {
            Self::Jpeg => "jpg",
            Self::Png => "png",
            Self::Gif => "gif",
            Self::Webp => "webp",
            Self::Bmp => "bmp",
            Self::Ico => "ico",
            Self::Tiff => "tiff",
            Self::Svg => "svg",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct ImageInfo {
    pub format: ImageFormat,
    pub width: u32,
    pub height: u32,
    pub frame_count: usize,
    pub exif_orientation: u8,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ImageOpError {
    InvalidFormat(String),
    DimensionsExceeded { width: u32, height: u32 },
    Encode(String),
}

impl std::fmt::Display for ImageOpError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidFormat(msg) => write!(f, "invalid image: {msg}"),
            Self::DimensionsExceeded { width, height } => {
                write!(f, "image dimensions {width}x{height} exceed {MAX_PIXEL_DIMENSION}x{MAX_PIXEL_DIMENSION}")
            }
            Self::Encode(msg) => write!(f, "image encoding error: {msg}"),
        }
    }
}

impl std::error::Error for ImageOpError {}

// ============================================================================
// 1. Header Inspection & Frame Counting (Zero Pixel Decompression)
// ============================================================================

/// Inspects an image container in memory without decompressing pixel streams, returning its
/// format, dimensions, frame count, and EXIF orientation (`1..=8`).
pub fn inspect_image(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    if bytes.len() < 4 {
        return Err(ImageOpError::InvalidFormat(
            "empty or truncated file".to_owned(),
        ));
    }
    if bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
        inspect_png(bytes)
    } else if bytes.starts_with(b"\xFF\xD8\xFF") {
        inspect_jpeg(bytes)
    } else if bytes.starts_with(b"GIF87a") || bytes.starts_with(b"GIF89a") {
        inspect_gif(bytes)
    } else if bytes.len() >= 12 && &bytes[0..4] == b"RIFF" && &bytes[8..12] == b"WEBP" {
        inspect_webp(bytes)
    } else if bytes.starts_with(b"BM") {
        inspect_bmp(bytes)
    } else if bytes.starts_with(b"\x00\x00\x01\x00") || bytes.starts_with(b"\x00\x00\x02\x00") {
        inspect_ico(bytes)
    } else if bytes.starts_with(b"II*\x00") || bytes.starts_with(b"MM\x00*") {
        inspect_tiff(bytes)
    } else if looks_like_svg(bytes) {
        inspect_svg(bytes)
    } else {
        Err(ImageOpError::InvalidFormat(
            "unrecognized image signature".to_owned(),
        ))
    }
}

/// Counts frames in `bytes` without decompressing pixels. Returns `Err` for unrecognized or
/// truncated image headers.
pub fn count_frames(bytes: &[u8]) -> Result<usize, ImageOpError> {
    Ok(inspect_image(bytes)?.frame_count)
}

fn looks_like_svg(bytes: &[u8]) -> bool {
    let prefix_len = bytes.len().min(4096);
    let Ok(prefix) = std::str::from_utf8(&bytes[..prefix_len]) else {
        return false;
    };
    let trimmed = prefix.trim_start_matches('\u{feff}').trim_start();
    (trimmed.starts_with("<svg")
        || trimmed.starts_with("<?xml")
        || trimmed.starts_with("<!DOCTYPE")
        || trimmed.starts_with("<!--"))
        && prefix.contains("<svg")
}

/// Parses TIFF/EXIF IFD0 (either starting directly with `II*\0`/`MM\0*` or prefixed by `Exif\0\0`).
/// Returns `(width_opt, height_opt, orientation, ifd_count)`.
fn parse_tiff_metadata(raw: &[u8]) -> Option<(Option<u32>, Option<u32>, u8, usize)> {
    let tiff = if raw.starts_with(b"Exif\0\0") {
        &raw[6..]
    } else {
        raw
    };
    if tiff.len() < 8 {
        return None;
    }
    let little = match &tiff[0..4] {
        b"II*\x00" => true,
        b"MM\x00*" => false,
        _ => return None,
    };
    let read_u16 = |off: usize| -> Option<u16> {
        let b = tiff.get(off..off + 2)?;
        Some(if little {
            u16::from_le_bytes([b[0], b[1]])
        } else {
            u16::from_be_bytes([b[0], b[1]])
        })
    };
    let read_u32 = |off: usize| -> Option<u32> {
        let b = tiff.get(off..off + 4)?;
        Some(if little {
            u32::from_le_bytes([b[0], b[1], b[2], b[3]])
        } else {
            u32::from_be_bytes([b[0], b[1], b[2], b[3]])
        })
    };
    let read_tag_u32 = |entry_off: usize| -> Option<u32> {
        let field_type = read_u16(entry_off + 2)?;
        let count = read_u32(entry_off + 4)?;
        if count == 0 {
            return None;
        }
        match field_type {
            3 => Some(u32::from(read_u16(entry_off + 8)?)), // SHORT
            4 => read_u32(entry_off + 8),                   // LONG
            _ => None,
        }
    };

    let mut ifd_off = read_u32(4)? as usize;
    let mut width = None;
    let mut height = None;
    let mut orientation = 1u8;
    let mut ifd_count = 0usize;
    let mut visited = Vec::new();

    while ifd_off != 0 && ifd_off + 2 <= tiff.len() && ifd_count < MAX_TIFF_IFDS {
        if visited.contains(&ifd_off) {
            break;
        }
        visited.push(ifd_off);
        let entries = read_u16(ifd_off)? as usize;
        let entries_end = ifd_off
            .checked_add(2)?
            .checked_add(entries.checked_mul(12)?)?;
        if entries_end > tiff.len() {
            break;
        }
        if ifd_count == 0 {
            for i in 0..entries {
                let e = ifd_off + 2 + i * 12;
                let tag = read_u16(e)?;
                match tag {
                    0x0100 => width = read_tag_u32(e),
                    0x0101 => height = read_tag_u32(e),
                    0x0112 => {
                        if let Some(v) = read_tag_u32(e) {
                            if (1..=8).contains(&v) {
                                orientation = v as u8;
                            }
                        }
                    }
                    _ => {}
                }
            }
        }
        ifd_count += 1;
        if entries_end + 4 > tiff.len() {
            break;
        }
        ifd_off = read_u32(entries_end)? as usize;
    }

    if ifd_count == 0 {
        return None;
    }
    Some((width, height, orientation, ifd_count))
}

fn inspect_jpeg(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    if bytes.len() < 4 || !bytes.starts_with(b"\xFF\xD8") {
        return Err(ImageOpError::InvalidFormat("bad JPEG SOI".to_owned()));
    }
    let mut pos = 2usize;
    let mut width = 0u32;
    let mut height = 0u32;
    let mut orientation = 1u8;

    while pos < bytes.len() {
        if bytes[pos] != 0xFF {
            pos += 1;
            continue;
        }
        while pos < bytes.len() && bytes[pos] == 0xFF {
            pos += 1;
        }
        if pos >= bytes.len() {
            break;
        }
        let marker = bytes[pos];
        pos += 1;
        if marker == 0x00 || marker == 0x01 || (0xD0..=0xD8).contains(&marker) {
            continue;
        }
        if marker == 0xD9 || marker == 0xDA {
            break;
        }
        if pos + 2 > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated JPEG segment".to_owned(),
            ));
        }
        let seg_len = u16::from_be_bytes([bytes[pos], bytes[pos + 1]]) as usize;
        if seg_len < 2 || pos + seg_len > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "invalid JPEG segment length".to_owned(),
            ));
        }
        let payload = &bytes[pos + 2..pos + seg_len];
        if marker == 0xE1 && payload.starts_with(b"Exif\0\0") && orientation == 1 {
            if let Some((_, _, orient, _)) = parse_tiff_metadata(payload) {
                orientation = orient;
            }
        } else if matches!(
            marker,
            0xC0..=0xC3 | 0xC5..=0xC7 | 0xC9..=0xCB | 0xCD..=0xCF
        ) && payload.len() >= 5
        {
            height = u16::from_be_bytes([payload[1], payload[2]]) as u32;
            width = u16::from_be_bytes([payload[3], payload[4]]) as u32;
        }
        pos += seg_len;
    }

    if width == 0 || height == 0 {
        return Err(ImageOpError::InvalidFormat("missing JPEG SOF".to_owned()));
    }
    Ok(ImageInfo {
        format: ImageFormat::Jpeg,
        width,
        height,
        frame_count: 1,
        exif_orientation: orientation,
    })
}

fn inspect_png(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    if bytes.len() < 33 || !bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
        return Err(ImageOpError::InvalidFormat("truncated PNG".to_owned()));
    }
    let mut pos = 8usize;
    let mut width = 0u32;
    let mut height = 0u32;
    let mut frame_count = 1usize;
    let mut orientation = 1u8;
    let mut saw_ihdr = false;

    while pos + 12 <= bytes.len() {
        let len = u32::from_be_bytes([bytes[pos], bytes[pos + 1], bytes[pos + 2], bytes[pos + 3]])
            as usize;
        let ctype = &bytes[pos + 4..pos + 8];
        let payload_start = pos + 8;
        let chunk_end = payload_start
            .checked_add(len)
            .and_then(|v| v.checked_add(4))
            .ok_or_else(|| ImageOpError::InvalidFormat("PNG chunk length overflow".to_owned()))?;
        if chunk_end > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated PNG chunk".to_owned(),
            ));
        }
        let payload = &bytes[payload_start..payload_start + len];
        match ctype {
            b"IHDR" => {
                if payload.len() < 8 {
                    return Err(ImageOpError::InvalidFormat("invalid PNG IHDR".to_owned()));
                }
                width = u32::from_be_bytes([payload[0], payload[1], payload[2], payload[3]]);
                height = u32::from_be_bytes([payload[4], payload[5], payload[6], payload[7]]);
                saw_ihdr = true;
            }
            b"acTL" if payload.len() >= 4 => {
                let frames = u32::from_be_bytes([payload[0], payload[1], payload[2], payload[3]]);
                frame_count = (frames as usize).max(1);
            }
            b"eXIf" if orientation == 1 => {
                if let Some((_, _, orient, _)) = parse_tiff_metadata(payload) {
                    orientation = orient;
                }
            }
            b"IEND" => break,
            _ => {}
        }
        pos = chunk_end;
    }

    if !saw_ihdr || width == 0 || height == 0 {
        return Err(ImageOpError::InvalidFormat("missing PNG IHDR".to_owned()));
    }
    Ok(ImageInfo {
        format: ImageFormat::Png,
        width,
        height,
        frame_count,
        exif_orientation: orientation,
    })
}

fn skip_gif_subblocks(bytes: &[u8], mut pos: usize) -> Result<usize, ImageOpError> {
    loop {
        let &block_len = bytes
            .get(pos)
            .ok_or_else(|| ImageOpError::InvalidFormat("truncated GIF sub-block".to_owned()))?;
        pos += 1;
        if block_len == 0 {
            return Ok(pos);
        }
        pos = pos
            .checked_add(usize::from(block_len))
            .ok_or_else(|| ImageOpError::InvalidFormat("GIF sub-block overflow".to_owned()))?;
        if pos > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated GIF sub-block payload".to_owned(),
            ));
        }
    }
}

fn inspect_gif(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    if bytes.len() < 13 || !(bytes.starts_with(b"GIF87a") || bytes.starts_with(b"GIF89a")) {
        return Err(ImageOpError::InvalidFormat(
            "truncated GIF header".to_owned(),
        ));
    }
    let width = u16::from_le_bytes([bytes[6], bytes[7]]) as u32;
    let height = u16::from_le_bytes([bytes[8], bytes[9]]) as u32;
    if width == 0 || height == 0 {
        return Err(ImageOpError::InvalidFormat(
            "zero GIF dimensions".to_owned(),
        ));
    }
    let packed = bytes[10];
    let mut pos = 13usize;
    if packed & 0x80 != 0 {
        let gct_entries = 1usize << ((packed & 0x07) + 1);
        pos += gct_entries * 3;
    }
    if pos > bytes.len() {
        return Err(ImageOpError::InvalidFormat("truncated GIF GCT".to_owned()));
    }

    let mut frames = 0usize;
    while pos < bytes.len() {
        match bytes[pos] {
            0x3B => break, // Trailer
            0x21 => {
                // Extension introducer: 0x21 <label> <sub-blocks...>
                if pos + 2 > bytes.len() {
                    break;
                }
                pos = skip_gif_subblocks(bytes, pos + 2)?;
            }
            0x2C => {
                // Image Descriptor: 10 bytes + optional Local Color Table + LZW min code size + sub-blocks
                if pos + 10 > bytes.len() {
                    return Err(ImageOpError::InvalidFormat(
                        "truncated GIF image descriptor".to_owned(),
                    ));
                }
                let local_packed = bytes[pos + 9];
                pos += 10;
                if local_packed & 0x80 != 0 {
                    let lct_entries = 1usize << ((local_packed & 0x07) + 1);
                    pos += lct_entries * 3;
                }
                if pos >= bytes.len() {
                    return Err(ImageOpError::InvalidFormat(
                        "truncated GIF LZW header".to_owned(),
                    ));
                }
                // Skip LZW minimum code size byte, then sub-blocks.
                pos = skip_gif_subblocks(bytes, pos + 1)?;
                frames += 1;
            }
            0x00 => {
                pos += 1;
            }
            _ => break,
        }
    }

    if frames == 0 {
        return Err(ImageOpError::InvalidFormat("GIF has no frames".to_owned()));
    }
    Ok(ImageInfo {
        format: ImageFormat::Gif,
        width,
        height,
        frame_count: frames,
        exif_orientation: 1,
    })
}

fn inspect_webp(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    if bytes.len() < 16 || &bytes[0..4] != b"RIFF" || &bytes[8..12] != b"WEBP" {
        return Err(ImageOpError::InvalidFormat(
            "invalid WebP header".to_owned(),
        ));
    }
    let riff_size = u32::from_le_bytes([bytes[4], bytes[5], bytes[6], bytes[7]]) as usize;
    let container_end = riff_size.saturating_add(8).min(bytes.len());
    let mut pos = 12usize;
    let mut width = 0u32;
    let mut height = 0u32;
    let mut anmf_count = 0usize;
    let mut orientation = 1u8;

    while pos + 8 <= container_end {
        let fourcc = &bytes[pos..pos + 4];
        let chunk_len = u32::from_le_bytes([
            bytes[pos + 4],
            bytes[pos + 5],
            bytes[pos + 6],
            bytes[pos + 7],
        ]) as usize;
        let payload_start = pos + 8;
        let payload_end = payload_start
            .checked_add(chunk_len)
            .ok_or_else(|| ImageOpError::InvalidFormat("WebP chunk overflow".to_owned()))?;
        if payload_end > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated WebP chunk".to_owned(),
            ));
        }
        let payload = &bytes[payload_start..payload_end];
        match fourcc {
            b"VP8X" if payload.len() >= 10 && width == 0 => {
                let w_minus_1 = u32::from(payload[4])
                    | (u32::from(payload[5]) << 8)
                    | (u32::from(payload[6]) << 16);
                let h_minus_1 = u32::from(payload[7])
                    | (u32::from(payload[8]) << 8)
                    | (u32::from(payload[9]) << 16);
                width = w_minus_1 + 1;
                height = h_minus_1 + 1;
            }
            b"VP8 " if payload.len() >= 10 && width == 0 => {
                if payload[3] == 0x9D && payload[4] == 0x01 && payload[5] == 0x2A {
                    width = u32::from(u16::from_le_bytes([payload[6], payload[7]]) & 0x3FFF);
                    height = u32::from(u16::from_le_bytes([payload[8], payload[9]]) & 0x3FFF);
                }
            }
            b"VP8L" if payload.len() >= 5 && width == 0 => {
                if payload[0] == 0x2F {
                    let bits = u32::from_le_bytes([payload[1], payload[2], payload[3], payload[4]]);
                    width = (bits & 0x3FFF) + 1;
                    height = ((bits >> 14) & 0x3FFF) + 1;
                }
            }
            b"ANMF" => {
                anmf_count += 1;
            }
            b"EXIF" if orientation == 1 => {
                if let Some((_, _, orient, _)) = parse_tiff_metadata(payload) {
                    orientation = orient;
                }
            }
            _ => {}
        }
        pos = payload_end + (chunk_len & 1);
    }

    if width == 0 || height == 0 {
        return Err(ImageOpError::InvalidFormat(
            "missing WebP dimensions".to_owned(),
        ));
    }
    Ok(ImageInfo {
        format: ImageFormat::Webp,
        width,
        height,
        frame_count: anmf_count.max(1),
        exif_orientation: orientation,
    })
}

fn inspect_bmp(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    if bytes.len() < 26 || !bytes.starts_with(b"BM") {
        return Err(ImageOpError::InvalidFormat(
            "truncated BMP header".to_owned(),
        ));
    }
    let dib_size = u32::from_le_bytes([bytes[14], bytes[15], bytes[16], bytes[17]]);
    let (width, height) = if dib_size == 12 {
        (
            u32::from(u16::from_le_bytes([bytes[18], bytes[19]])),
            u32::from(u16::from_le_bytes([bytes[20], bytes[21]])),
        )
    } else if dib_size >= 40 && bytes.len() >= 26 {
        let w = i32::from_le_bytes([bytes[18], bytes[19], bytes[20], bytes[21]]);
        let h = i32::from_le_bytes([bytes[22], bytes[23], bytes[24], bytes[25]]);
        if w <= 0 || h == 0 {
            return Err(ImageOpError::InvalidFormat(
                "invalid BMP dimensions".to_owned(),
            ));
        }
        (w as u32, h.unsigned_abs())
    } else {
        return Err(ImageOpError::InvalidFormat(
            "unsupported BMP DIB header".to_owned(),
        ));
    };

    if width == 0 || height == 0 {
        return Err(ImageOpError::InvalidFormat(
            "zero BMP dimensions".to_owned(),
        ));
    }
    Ok(ImageInfo {
        format: ImageFormat::Bmp,
        width,
        height,
        frame_count: 1,
        exif_orientation: 1,
    })
}

fn inspect_ico(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    if bytes.len() < 22 {
        return Err(ImageOpError::InvalidFormat(
            "truncated ICO header".to_owned(),
        ));
    }
    let count = u16::from_le_bytes([bytes[4], bytes[5]]) as usize;
    if count == 0 || 6 + count * 16 > bytes.len() {
        return Err(ImageOpError::InvalidFormat(
            "invalid ICO directory".to_owned(),
        ));
    }
    let mut best_w = 0u32;
    let mut best_h = 0u32;
    for i in 0..count {
        let entry = &bytes[6 + i * 16..6 + (i + 1) * 16];
        let mut w = if entry[0] == 0 {
            256
        } else {
            u32::from(entry[0])
        };
        let mut h = if entry[1] == 0 {
            256
        } else {
            u32::from(entry[1])
        };
        let size = u32::from_le_bytes([entry[8], entry[9], entry[10], entry[11]]) as usize;
        let offset = u32::from_le_bytes([entry[12], entry[13], entry[14], entry[15]]) as usize;
        if size == 0 || offset.checked_add(size).is_none_or(|end| end > bytes.len()) {
            return Err(ImageOpError::InvalidFormat(
                "ICO entry out of bounds".to_owned(),
            ));
        }
        let sub = &bytes[offset..offset + size];
        if sub.starts_with(b"\x89PNG\r\n\x1a\n") {
            if let Ok(png_info) = inspect_png(sub) {
                w = png_info.width;
                h = png_info.height;
            }
        }
        if w * h >= best_w * best_h {
            best_w = w;
            best_h = h;
        }
    }
    Ok(ImageInfo {
        format: ImageFormat::Ico,
        width: best_w,
        height: best_h,
        frame_count: count,
        exif_orientation: 1,
    })
}

fn inspect_tiff(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    let (w_opt, h_opt, orientation, ifd_count) = parse_tiff_metadata(bytes)
        .ok_or_else(|| ImageOpError::InvalidFormat("invalid TIFF/DNG IFD".to_owned()))?;
    let width = w_opt.unwrap_or(1).max(1);
    let height = h_opt.unwrap_or(1).max(1);
    Ok(ImageInfo {
        format: ImageFormat::Tiff,
        width,
        height,
        frame_count: ifd_count,
        exif_orientation: orientation,
    })
}

fn inspect_svg(bytes: &[u8]) -> Result<ImageInfo, ImageOpError> {
    let text = std::str::from_utf8(bytes)
        .map_err(|_| ImageOpError::InvalidFormat("invalid UTF-8 in SVG".to_owned()))?;
    let (w, h, _) = parse_svg_root_geometry(text)?;
    Ok(ImageInfo {
        format: ImageFormat::Svg,
        width: w.round().max(1.0) as u32,
        height: h.round().max(1.0) as u32,
        frame_count: 1,
        exif_orientation: 1,
    })
}

// ============================================================================
// 2. EXIF Pixel Orientation & Lossless Container Metadata Stripping
// ============================================================================

/// Applies EXIF 2.32 orientation `1..=8` to `canvas` and resets orientation to normal (`1`).
pub fn orient_canvas(canvas: &Canvas, orientation: u8) -> Canvas {
    let w = canvas.width;
    let h = canvas.height;
    if orientation <= 1 || orientation > 8 || w == 0 || h == 0 {
        return canvas.clone();
    }
    let (dst_w, dst_h) = if orientation >= 5 { (h, w) } else { (w, h) };
    let mut dst = Canvas::new(dst_w, dst_h, Rgba::TRANSPARENT);
    dst.has_alpha = canvas.has_alpha;
    dst.is_pseudo = canvas.is_pseudo;

    for dy in 0..dst_h {
        for dx in 0..dst_w {
            let (sx, sy) = match orientation {
                2 => (w - 1 - dx, dy),
                3 => (w - 1 - dx, h - 1 - dy),
                4 => (dx, h - 1 - dy),
                5 => (dy, dx),
                6 => (dy, h - 1 - dx),
                7 => (w - 1 - dy, h - 1 - dx),
                8 => (w - 1 - dy, dx),
                _ => (dx, dy),
            };
            *dst.get_mut(dx, dy) = canvas.get(sx, sy);
        }
    }
    dst
}

/// Strips EXIF/XMP/IPTC/textual metadata and auto-orients pixels when EXIF Orientation is `2..=8`.
///
/// * Returns `Ok(None)` when the file is already clean or `frame_count > frame_strip_max`.
/// * Returns `Ok(Some(bytes))` when bytes were modified.
/// * Never shells out to ImageMagick; handles progressive JPEGs, trailing Motion Photo bytes,
///   APNGs, animated GIFs, and animated WebPs losslessly in memory.
pub fn strip_and_auto_orient(
    bytes: &[u8],
    frame_strip_max: usize,
) -> Result<Option<Vec<u8>>, ImageOpError> {
    let info = inspect_image(bytes)?;
    if info.format == ImageFormat::Svg || info.frame_count > frame_strip_max {
        return Ok(None);
    }

    match info.format {
        ImageFormat::Jpeg => {
            if (2..=8).contains(&info.exif_orientation) {
                let decoded =
                    decode_image(bytes).map_err(|e| ImageOpError::InvalidFormat(e.to_string()))?;
                let oriented = orient_canvas(&decoded, info.exif_orientation);
                Ok(Some(encode_jpeg(&oriented, 90)?))
            } else {
                strip_jpeg_lossless(bytes)
            }
        }
        ImageFormat::Png => {
            if (2..=8).contains(&info.exif_orientation) && info.frame_count == 1 {
                let decoded =
                    decode_image(bytes).map_err(|e| ImageOpError::InvalidFormat(e.to_string()))?;
                let oriented = orient_canvas(&decoded, info.exif_orientation);
                let out = encode_png_preserving_alpha(&oriented)
                    .map_err(|e| ImageOpError::Encode(e.to_string()))?;
                Ok(Some(out))
            } else {
                strip_png_lossless(bytes)
            }
        }
        ImageFormat::Webp => {
            if (2..=8).contains(&info.exif_orientation) && info.frame_count == 1 {
                let decoded =
                    decode_image(bytes).map_err(|e| ImageOpError::InvalidFormat(e.to_string()))?;
                let oriented = orient_canvas(&decoded, info.exif_orientation);
                Ok(Some(encode_webp(&oriented)?))
            } else {
                strip_webp_lossless(bytes)
            }
        }
        ImageFormat::Gif => strip_gif_lossless(bytes),
        ImageFormat::Bmp | ImageFormat::Ico | ImageFormat::Tiff | ImageFormat::Svg => Ok(None),
    }
}

/// Losslessly strips `APP1..APP13` (`0xE1..0xED`), `APP15` (`0xEF`), and `COM` (`0xFE`) segments
/// from a baseline or progressive JPEG and truncates any trailing data after the first `EOI` (`0xFFD9`).
fn strip_jpeg_lossless(bytes: &[u8]) -> Result<Option<Vec<u8>>, ImageOpError> {
    if bytes.len() < 4 || !bytes.starts_with(b"\xFF\xD8") {
        return Err(ImageOpError::InvalidFormat("bad JPEG SOI".to_owned()));
    }
    let mut out = Vec::with_capacity(bytes.len());
    out.extend_from_slice(b"\xFF\xD8");
    let mut pos = 2usize;
    let mut modified = false;
    let mut saw_eoi = false;

    while pos < bytes.len() {
        if bytes[pos] != 0xFF {
            return Err(ImageOpError::InvalidFormat(
                "expected 0xFF marker prefix in JPEG".to_owned(),
            ));
        }
        let ff_start = pos;
        while pos < bytes.len() && bytes[pos] == 0xFF {
            pos += 1;
        }
        if pos >= bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated JPEG marker".to_owned(),
            ));
        }
        let marker = bytes[pos];
        pos += 1;

        if marker == 0xD9 {
            // EOI: write 0xFFD9 and truncate anything appended after EOI.
            out.extend_from_slice(b"\xFF\xD9");
            if pos < bytes.len() || pos - ff_start != 2 {
                modified = true;
            }
            saw_eoi = true;
            break;
        }

        if marker == 0x01 || (0xD0..=0xD8).contains(&marker) {
            out.push(0xFF);
            out.push(marker);
            continue;
        }

        if pos + 2 > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated JPEG segment length".to_owned(),
            ));
        }
        let seg_len = u16::from_be_bytes([bytes[pos], bytes[pos + 1]]) as usize;
        if seg_len < 2 || pos + seg_len > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "JPEG segment length out of bounds".to_owned(),
            ));
        }

        let is_metadata = (0xE1..=0xED).contains(&marker) || marker == 0xEF || marker == 0xFE;
        if is_metadata {
            modified = true;
            pos += seg_len;
            continue;
        }

        out.push(0xFF);
        out.push(marker);
        out.extend_from_slice(&bytes[pos..pos + seg_len]);
        pos += seg_len;

        if marker == 0xDA {
            // SOS: scan entropy-coded data up to the next non-stuffed, non-RST marker.
            let scan_start = pos;
            loop {
                let Some(rel_ff) = bytes[pos..].iter().position(|&b| b == 0xFF) else {
                    return Err(ImageOpError::InvalidFormat(
                        "unterminated JPEG SOS scan".to_owned(),
                    ));
                };
                let marker_ff_pos = pos + rel_ff;
                let mut probe = marker_ff_pos + 1;
                while probe < bytes.len() && bytes[probe] == 0xFF {
                    probe += 1;
                }
                if probe >= bytes.len() {
                    return Err(ImageOpError::InvalidFormat(
                        "truncated JPEG entropy stream".to_owned(),
                    ));
                }
                let next_byte = bytes[probe];
                if next_byte == 0x00 || (0xD0..=0xD7).contains(&next_byte) {
                    // Byte-stuffed 0xFF00 or restart marker RST0..RST7: part of scan stream.
                    pos = probe + 1;
                    continue;
                }
                // Real JPEG marker (`EOI`, next `SOS`, `DHT`, `DQT`, `APPn`, `COM`, ...).
                out.extend_from_slice(&bytes[scan_start..marker_ff_pos]);
                pos = marker_ff_pos;
                break;
            }
        }
    }

    if !saw_eoi {
        return Err(ImageOpError::InvalidFormat("missing JPEG EOI".to_owned()));
    }
    if modified {
        Ok(Some(out))
    } else {
        Ok(None)
    }
}

/// Losslessly strips `tEXt`, `zTXt`, `iTXt`, `tIME`, and `eXIf` chunks from a PNG or APNG
/// and truncates any bytes appended after `IEND`.
fn strip_png_lossless(bytes: &[u8]) -> Result<Option<Vec<u8>>, ImageOpError> {
    if bytes.len() < 33 || !bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
        return Err(ImageOpError::InvalidFormat("bad PNG signature".to_owned()));
    }
    let mut out = Vec::with_capacity(bytes.len());
    out.extend_from_slice(&bytes[0..8]);
    let mut pos = 8usize;
    let mut modified = false;
    let mut saw_iend = false;

    while pos + 12 <= bytes.len() {
        let len = u32::from_be_bytes([bytes[pos], bytes[pos + 1], bytes[pos + 2], bytes[pos + 3]])
            as usize;
        let total = 12usize
            .checked_add(len)
            .ok_or_else(|| ImageOpError::InvalidFormat("PNG chunk overflow".to_owned()))?;
        if pos + total > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated PNG chunk".to_owned(),
            ));
        }
        let ctype = &bytes[pos + 4..pos + 8];
        if matches!(ctype, b"tEXt" | b"zTXt" | b"iTXt" | b"tIME" | b"eXIf") {
            modified = true;
        } else {
            out.extend_from_slice(&bytes[pos..pos + total]);
        }
        pos += total;
        if ctype == b"IEND" {
            saw_iend = true;
            if pos < bytes.len() {
                modified = true;
            }
            break;
        }
    }

    if !saw_iend {
        return Err(ImageOpError::InvalidFormat("missing PNG IEND".to_owned()));
    }
    if modified {
        Ok(Some(out))
    } else {
        Ok(None)
    }
}

/// Losslessly strips `EXIF` and `XMP ` RIFF chunks from still or animated WebP files, clears
/// the EXIF (`0x08`) and XMP (`0x04`) flags in `VP8X`, and updates the RIFF container size.
fn strip_webp_lossless(bytes: &[u8]) -> Result<Option<Vec<u8>>, ImageOpError> {
    if bytes.len() < 16 || &bytes[0..4] != b"RIFF" || &bytes[8..12] != b"WEBP" {
        return Err(ImageOpError::InvalidFormat("bad WebP header".to_owned()));
    }
    let riff_size = u32::from_le_bytes([bytes[4], bytes[5], bytes[6], bytes[7]]) as usize;
    let container_end = riff_size.saturating_add(8).min(bytes.len());
    let mut out = Vec::with_capacity(bytes.len());
    out.extend_from_slice(&bytes[0..12]);

    let mut pos = 12usize;
    let mut modified = container_end < bytes.len();

    while pos + 8 <= container_end {
        let fourcc = &bytes[pos..pos + 4];
        let chunk_len = u32::from_le_bytes([
            bytes[pos + 4],
            bytes[pos + 5],
            bytes[pos + 6],
            bytes[pos + 7],
        ]) as usize;
        let padded = chunk_len + (chunk_len & 1);
        let chunk_end = pos
            .checked_add(8)
            .and_then(|v| v.checked_add(chunk_len))
            .ok_or_else(|| ImageOpError::InvalidFormat("WebP chunk overflow".to_owned()))?;
        if chunk_end > bytes.len() {
            return Err(ImageOpError::InvalidFormat(
                "truncated WebP chunk".to_owned(),
            ));
        }

        if matches!(fourcc, b"EXIF" | b"XMP ") {
            modified = true;
        } else if fourcc == b"VP8X" && chunk_len >= 10 && (bytes[pos + 8] & 0x0C) != 0 {
            modified = true;
            let copy_end = (pos + 8 + padded).min(bytes.len());
            let vp8x_start = out.len();
            out.extend_from_slice(&bytes[pos..copy_end]);
            out[vp8x_start + 8] &= !0x0C;
        } else {
            let copy_end = (pos + 8 + padded).min(bytes.len());
            out.extend_from_slice(&bytes[pos..copy_end]);
            if copy_end < pos + 8 + padded {
                out.push(0);
            }
        }
        pos = (pos + 8 + padded).min(container_end);
    }

    if !modified {
        return Ok(None);
    }
    let new_riff_size = (out.len() - 8) as u32;
    out[4..8].copy_from_slice(&new_riff_size.to_le_bytes());
    Ok(Some(out))
}

/// Losslessly strips Comment (`0x21 0xFE`) and XMP Application (`0x21 0xFF` `"XMP DataXMP"`)
/// extensions from a GIF while preserving animation loops (`NETSCAPE2.0`), GCEs, and LZW frames.
fn strip_gif_lossless(bytes: &[u8]) -> Result<Option<Vec<u8>>, ImageOpError> {
    if bytes.len() < 13 || !(bytes.starts_with(b"GIF87a") || bytes.starts_with(b"GIF89a")) {
        return Err(ImageOpError::InvalidFormat("bad GIF header".to_owned()));
    }
    let packed = bytes[10];
    let mut header_end = 13usize;
    if packed & 0x80 != 0 {
        header_end += (1usize << ((packed & 0x07) + 1)) * 3;
    }
    if header_end > bytes.len() {
        return Err(ImageOpError::InvalidFormat("truncated GIF GCT".to_owned()));
    }

    let mut out = Vec::with_capacity(bytes.len());
    out.extend_from_slice(&bytes[..header_end]);
    let mut pos = header_end;
    let mut modified = false;

    while pos < bytes.len() {
        match bytes[pos] {
            0x3B => {
                out.push(0x3B);
                pos += 1;
                if pos < bytes.len() {
                    modified = true;
                }
                break;
            }
            0x21 => {
                if pos + 2 > bytes.len() {
                    return Err(ImageOpError::InvalidFormat(
                        "truncated GIF extension".to_owned(),
                    ));
                }
                let label = bytes[pos + 1];
                let ext_end = skip_gif_subblocks(bytes, pos + 2)?;
                let is_comment = label == 0xFE;
                let is_xmp = label == 0xFF
                    && pos + 14 <= ext_end
                    && bytes[pos + 2] == 11
                    && &bytes[pos + 3..pos + 14] == b"XMP DataXMP";
                if is_comment || is_xmp {
                    modified = true;
                } else {
                    out.extend_from_slice(&bytes[pos..ext_end]);
                }
                pos = ext_end;
            }
            0x2C => {
                let frame_start = pos;
                if pos + 10 > bytes.len() {
                    return Err(ImageOpError::InvalidFormat(
                        "truncated GIF image descriptor".to_owned(),
                    ));
                }
                let local_packed = bytes[pos + 9];
                pos += 10;
                if local_packed & 0x80 != 0 {
                    pos += (1usize << ((local_packed & 0x07) + 1)) * 3;
                }
                if pos >= bytes.len() {
                    return Err(ImageOpError::InvalidFormat("truncated GIF LZW".to_owned()));
                }
                pos = skip_gif_subblocks(bytes, pos + 1)?;
                out.extend_from_slice(&bytes[frame_start..pos]);
            }
            0x00 => {
                pos += 1;
                modified = true;
            }
            other => {
                return Err(ImageOpError::InvalidFormat(format!(
                    "unexpected GIF block introducer 0x{other:02x}"
                )));
            }
        }
    }

    if modified {
        Ok(Some(out))
    } else {
        Ok(None)
    }
}

// ============================================================================
// 3. Pure-Rust Baseline JPEG, WebP, GIF, BMP & ICO Codecs
// ============================================================================

/// Zigzag index `0..64` -> natural `row * 8 + col` index.
const ZZ_TO_NATURAL: [usize; 64] = [
    0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20,
    13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59,
    52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63,
];

/// ITU-T T.81 Annex K.1 luminance quantization matrix in natural row-major order.
const STD_LUM_QUANT_NATURAL: [u8; 64] = [
    16, 11, 10, 16, 24, 40, 51, 61, 12, 12, 14, 19, 26, 58, 60, 55, 14, 13, 16, 24, 40, 57, 69, 56,
    14, 17, 22, 29, 51, 87, 80, 62, 18, 22, 37, 56, 68, 109, 103, 77, 24, 35, 55, 64, 81, 104, 113,
    92, 49, 64, 78, 87, 103, 121, 120, 101, 72, 92, 95, 98, 112, 100, 103, 99,
];

/// ITU-T T.81 Annex K.2 chrominance quantization matrix in natural row-major order.
const STD_CHROM_QUANT_NATURAL: [u8; 64] = [
    17, 18, 24, 47, 99, 99, 99, 99, 18, 21, 26, 66, 99, 99, 99, 99, 24, 26, 56, 99, 99, 99, 99, 99,
    47, 66, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
];

const BITS_DC_LUM: [u8; 16] = [0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0];
const VAL_DC_LUM: [u8; 12] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

const BITS_DC_CHROM: [u8; 16] = [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0];
const VAL_DC_CHROM: [u8; 12] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

const BITS_AC_LUM: [u8; 16] = [0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d];
const VAL_AC_LUM: [u8; 162] = [
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
    0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08, 0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
    0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
    0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
    0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
    0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
    0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
    0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
    0xf9, 0xfa,
];

const BITS_AC_CHROM: [u8; 16] = [0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77];
const VAL_AC_CHROM: [u8; 162] = [
    0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21, 0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
    0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91, 0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
    0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34, 0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
    0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
    0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
    0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
    0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
    0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
    0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
    0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
    0xf9, 0xfa,
];

fn build_huffman_lut(bits: &[u8; 16], vals: &[u8]) -> [(u16, u8); 256] {
    let mut lut = [(0u16, 0u8); 256];
    let mut code = 0u16;
    let mut idx = 0usize;
    for (len_minus_1, &count) in bits.iter().enumerate() {
        let bit_len = (len_minus_1 + 1) as u8;
        for _ in 0..count {
            let sym = vals[idx] as usize;
            lut[sym] = (code, bit_len);
            code += 1;
            idx += 1;
        }
        code <<= 1;
    }
    lut
}

fn scale_quant_zigzag(natural_table: &[u8; 64], quality: u8) -> [u8; 64] {
    let q = quality.clamp(1, 100) as u32;
    let scale = if q < 50 { 5000 / q } else { 200 - q * 2 };
    let mut zz = [1u8; 64];
    for (z, &nat_idx) in ZZ_TO_NATURAL.iter().enumerate() {
        let base = u32::from(natural_table[nat_idx]);
        let v = ((base * scale + 50) / 100).clamp(1, 255);
        zz[z] = v as u8;
    }
    zz
}

struct JpegBitWriter {
    out: Vec<u8>,
    bit_buf: u32,
    bit_count: u8,
}

impl JpegBitWriter {
    fn with_capacity(cap: usize) -> Self {
        Self {
            out: Vec::with_capacity(cap),
            bit_buf: 0,
            bit_count: 0,
        }
    }

    #[inline]
    fn write_bits(&mut self, bits: u16, len: u8) {
        if len == 0 {
            return;
        }
        let mask = (1u32 << len) - 1;
        self.bit_buf = (self.bit_buf << len) | (u32::from(bits) & mask);
        self.bit_count += len;
        while self.bit_count >= 8 {
            self.bit_count -= 8;
            let byte = ((self.bit_buf >> self.bit_count) & 0xFF) as u8;
            self.out.push(byte);
            if byte == 0xFF {
                self.out.push(0x00);
            }
        }
    }

    fn flush_padding(&mut self) {
        if self.bit_count > 0 {
            let pad_len = 8 - self.bit_count;
            let pad_ones = (1u16 << pad_len) - 1;
            self.write_bits(pad_ones, pad_len);
        }
    }
}

#[inline]
fn huff_magnitude(val: i32) -> (u8, u16) {
    if val == 0 {
        return (0, 0);
    }
    let abs_v = val.unsigned_abs();
    let size = (32 - abs_v.leading_zeros()) as u8;
    let bits = if val > 0 {
        abs_v as u16
    } else {
        ((1u32 << size) - 1 - abs_v) as u16
    };
    (size, bits)
}

fn fdct_8x8(block: &[f32; 64], cos_table: &[[f32; 8]; 8]) -> [f32; 64] {
    let mut tmp = [0.0f32; 64];
    let inv_sqrt2 = std::f32::consts::FRAC_1_SQRT_2;

    // 1D DCT along rows.
    for y in 0..8 {
        let row = &block[y * 8..y * 8 + 8];
        for u in 0..8 {
            let mut sum = 0.0f32;
            for x in 0..8 {
                sum += row[x] * cos_table[u][x];
            }
            let cu = if u == 0 { inv_sqrt2 } else { 1.0 };
            tmp[y * 8 + u] = 0.5 * cu * sum;
        }
    }

    // 1D DCT along columns.
    let mut out = [0.0f32; 64];
    for u in 0..8 {
        for v in 0..8 {
            let mut sum = 0.0f32;
            for y in 0..8 {
                sum += tmp[y * 8 + u] * cos_table[v][y];
            }
            let cv = if v == 0 { inv_sqrt2 } else { 1.0 };
            out[v * 8 + u] = 0.5 * cv * sum;
        }
    }
    out
}

fn encode_du(
    writer: &mut JpegBitWriter,
    dct_natural: &[f32; 64],
    quant_zz: &[u8; 64],
    prev_dc: i32,
    dc_lut: &[(u16, u8); 256],
    ac_lut: &[(u16, u8); 256],
) -> i32 {
    let mut q = [0i32; 64];
    for z in 0..64 {
        let coeff = dct_natural[ZZ_TO_NATURAL[z]];
        let qv = f32::from(quant_zz[z]);
        q[z] = (coeff / qv).round() as i32;
    }

    // Differential DC coefficient.
    let diff = q[0] - prev_dc;
    let (dc_size, dc_bits) = huff_magnitude(diff);
    let (hcode, hlen) = dc_lut[dc_size as usize];
    writer.write_bits(hcode, hlen);
    writer.write_bits(dc_bits, dc_size);

    // Run-length AC coefficients.
    let mut zero_run = 0usize;
    for &ac in &q[1..64] {
        if ac == 0 {
            zero_run += 1;
        } else {
            while zero_run >= 16 {
                let (zcode, zlen) = ac_lut[0xF0];
                writer.write_bits(zcode, zlen);
                zero_run -= 16;
            }
            let (ac_size, ac_bits) = huff_magnitude(ac);
            let sym = ((zero_run as u8) << 4) | ac_size;
            let (ac_hcode, ac_hlen) = ac_lut[sym as usize];
            writer.write_bits(ac_hcode, ac_hlen);
            writer.write_bits(ac_bits, ac_size);
            zero_run = 0;
        }
    }
    if zero_run > 0 {
        let (eob_code, eob_len) = ac_lut[0x00];
        writer.write_bits(eob_code, eob_len);
    }

    q[0]
}

/// Encodes `canvas` as a baseline 4:4:4 SOF0 JFIF JPEG at `quality` (`1..=100`, e.g. `90`)
/// with zero EXIF metadata. Transparent pixels composite cleanly over white.
pub fn encode_jpeg(canvas: &Canvas, quality: u8) -> Result<Vec<u8>, ImageOpError> {
    if canvas.width == 0 || canvas.height == 0 || canvas.width > 65535 || canvas.height > 65535 {
        return Err(ImageOpError::Encode(format!(
            "invalid JPEG dimensions {}x{}",
            canvas.width, canvas.height
        )));
    }
    let w = canvas.width;
    let h = canvas.height;
    let lum_q = scale_quant_zigzag(&STD_LUM_QUANT_NATURAL, quality);
    let chrom_q = scale_quant_zigzag(&STD_CHROM_QUANT_NATURAL, quality);

    let dc_lum_lut = build_huffman_lut(&BITS_DC_LUM, &VAL_DC_LUM);
    let dc_chrom_lut = build_huffman_lut(&BITS_DC_CHROM, &VAL_DC_CHROM);
    let ac_lum_lut = build_huffman_lut(&BITS_AC_LUM, &VAL_AC_LUM);
    let ac_chrom_lut = build_huffman_lut(&BITS_AC_CHROM, &VAL_AC_CHROM);

    let mut cos_table = [[0.0f32; 8]; 8];
    for (u, row) in cos_table.iter_mut().enumerate() {
        for (x, cell) in row.iter_mut().enumerate() {
            *cell = (((2 * x + 1) * u) as f32 * std::f32::consts::PI / 16.0).cos();
        }
    }

    let mut bw = JpegBitWriter::with_capacity(w * h / 2 + 1024);

    // SOI + APP0 (JFIF 1.01)
    bw.out.extend_from_slice(&[
        0xFF, 0xD8, // SOI
        0xFF, 0xE0, 0x00, 0x10, b'J', b'F', b'I', b'F', 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00,
        0x01, 0x00, 0x00,
    ]);

    // DQT (tables 0 and 1 in a single segment: len = 2 + 65 + 65 = 132 = 0x0084)
    bw.out.extend_from_slice(&[0xFF, 0xDB, 0x00, 0x84, 0x00]);
    bw.out.extend_from_slice(&lum_q);
    bw.out.push(0x01);
    bw.out.extend_from_slice(&chrom_q);

    // SOF0 (Baseline DCT, 4:4:4 YCbCr, len = 17 = 0x0011)
    bw.out.extend_from_slice(&[0xFF, 0xC0, 0x00, 0x11, 0x08]);
    bw.out.extend_from_slice(&(h as u16).to_be_bytes());
    bw.out.extend_from_slice(&(w as u16).to_be_bytes());
    bw.out.extend_from_slice(&[
        0x03, // 3 components
        0x01, 0x11, 0x00, // Y:  1x1, quant 0
        0x02, 0x11, 0x01, // Cb: 1x1, quant 1
        0x03, 0x11, 0x01, // Cr: 1x1, quant 1
    ]);

    // DHT (all 4 standard tables in a single segment: len = 2 + (17+12)*2 + (17+162)*2 = 418 = 0x01A2)
    bw.out.extend_from_slice(&[0xFF, 0xC4, 0x01, 0xA2]);
    for (tc_th, bits, vals) in [
        (0x00u8, &BITS_DC_LUM, &VAL_DC_LUM[..]),
        (0x10u8, &BITS_AC_LUM, &VAL_AC_LUM[..]),
        (0x01u8, &BITS_DC_CHROM, &VAL_DC_CHROM[..]),
        (0x11u8, &BITS_AC_CHROM, &VAL_AC_CHROM[..]),
    ] {
        bw.out.push(tc_th);
        bw.out.extend_from_slice(bits);
        bw.out.extend_from_slice(vals);
    }

    // SOS (len = 12 = 0x000C)
    bw.out.extend_from_slice(&[
        0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00,
    ]);

    let mut prev_dc_y = 0i32;
    let mut prev_dc_cb = 0i32;
    let mut prev_dc_cr = 0i32;
    let mut y_block = [0.0f32; 64];
    let mut cb_block = [0.0f32; 64];
    let mut cr_block = [0.0f32; 64];

    for by in (0..h).step_by(8) {
        for bx in (0..w).step_by(8) {
            for py in 0..8 {
                let sy = (by + py).min(h - 1);
                for px in 0..8 {
                    let sx = (bx + px).min(w - 1);
                    let p = canvas.get(sx, sy);
                    let (r, g, b) = if canvas.has_alpha && p.a < 1.0 {
                        let a = p.a.clamp(0.0, 1.0);
                        (
                            (p.r * a + (1.0 - a)) * 255.0,
                            (p.g * a + (1.0 - a)) * 255.0,
                            (p.b * a + (1.0 - a)) * 255.0,
                        )
                    } else {
                        (p.r * 255.0, p.g * 255.0, p.b * 255.0)
                    };
                    let idx = py * 8 + px;
                    y_block[idx] = 0.299 * r + 0.587 * g + 0.114 * b - 128.0;
                    cb_block[idx] = -0.168_736 * r - 0.331_264 * g + 0.5 * b;
                    cr_block[idx] = 0.5 * r - 0.418_688 * g - 0.081_312 * b;
                }
            }
            let dct_y = fdct_8x8(&y_block, &cos_table);
            let dct_cb = fdct_8x8(&cb_block, &cos_table);
            let dct_cr = fdct_8x8(&cr_block, &cos_table);
            prev_dc_y = encode_du(&mut bw, &dct_y, &lum_q, prev_dc_y, &dc_lum_lut, &ac_lum_lut);
            prev_dc_cb = encode_du(
                &mut bw,
                &dct_cb,
                &chrom_q,
                prev_dc_cb,
                &dc_chrom_lut,
                &ac_chrom_lut,
            );
            prev_dc_cr = encode_du(
                &mut bw,
                &dct_cr,
                &chrom_q,
                prev_dc_cr,
                &dc_chrom_lut,
                &ac_chrom_lut,
            );
        }
    }

    bw.flush_padding();
    bw.out.extend_from_slice(&[0xFF, 0xD9]); // EOI
    Ok(bw.out)
}

/// Encodes `canvas` as a lossless WebP (preserving alpha when `canvas.has_alpha` is true).
pub fn encode_webp(canvas: &Canvas) -> Result<Vec<u8>, ImageOpError> {
    let mut out = Vec::new();
    let encoder = image_webp::WebPEncoder::new(&mut out);
    if canvas.has_alpha {
        let rgba = canvas.to_rgba8();
        encoder
            .encode(
                &rgba,
                canvas.width as u32,
                canvas.height as u32,
                image_webp::ColorType::Rgba8,
            )
            .map_err(|e| ImageOpError::Encode(e.to_string()))?;
    } else {
        let rgb = canvas.to_rgb8();
        encoder
            .encode(
                &rgb,
                canvas.width as u32,
                canvas.height as u32,
                image_webp::ColorType::Rgb8,
            )
            .map_err(|e| ImageOpError::Encode(e.to_string()))?;
    }
    Ok(out)
}

/// Encodes `canvas` as a GIF89a image (with optional 1-bit transparency at palette slot 255).
pub fn encode_gif(canvas: &Canvas) -> Result<Vec<u8>, ImageOpError> {
    if canvas.width == 0 || canvas.height == 0 || canvas.width > 65535 || canvas.height > 65535 {
        return Err(ImageOpError::Encode("invalid GIF dimensions".to_owned()));
    }
    // Build a 256-entry palette: 6x6x6 RGB cube (0..216), 39-step grayscale ramp (216..255),
    // and transparent slot 255.
    let mut palette = [0u8; 256 * 3];
    for r in 0..6usize {
        for g in 0..6usize {
            for b in 0..6usize {
                let idx = (r * 36 + g * 6 + b) * 3;
                palette[idx] = (r * 51) as u8;
                palette[idx + 1] = (g * 51) as u8;
                palette[idx + 2] = (b * 51) as u8;
            }
        }
    }
    for i in 0..39usize {
        let v = ((i * 255 + 19) / 38) as u8;
        let idx = (216 + i) * 3;
        palette[idx] = v;
        palette[idx + 1] = v;
        palette[idx + 2] = v;
    }

    let mut indices = Vec::with_capacity(canvas.width * canvas.height);
    let mut has_transparent = false;
    for p in &canvas.pixels {
        if canvas.has_alpha && p.a < 0.5 {
            indices.push(255u8);
            has_transparent = true;
            continue;
        }
        let r = quantize8(p.r);
        let g = quantize8(p.g);
        let b = quantize8(p.b);
        if r == g && g == b {
            let gi = ((usize::from(r) * 38 + 127) / 255).min(38);
            indices.push((216 + gi) as u8);
        } else {
            let ri = (usize::from(r) + 25) / 51;
            let gi = (usize::from(g) + 25) / 51;
            let bi = (usize::from(b) + 25) / 51;
            indices.push((ri * 36 + gi * 6 + bi) as u8);
        }
    }

    let mut out = Vec::new();
    {
        let mut enc = gif::Encoder::new(
            &mut out,
            canvas.width as u16,
            canvas.height as u16,
            &palette,
        )
        .map_err(|e| ImageOpError::Encode(e.to_string()))?;
        let mut frame = gif::Frame {
            width: canvas.width as u16,
            height: canvas.height as u16,
            transparent: if has_transparent { Some(255) } else { None },
            buffer: Cow::Borrowed(&indices),
            ..gif::Frame::default()
        };
        if has_transparent {
            frame.dispose = gif::DisposalMethod::Background;
        }
        enc.write_frame(&frame)
            .map_err(|e| ImageOpError::Encode(e.to_string()))?;
    }
    Ok(out)
}

fn decode_bmp(bytes: &[u8]) -> Result<Canvas, ImageOpError> {
    let info = inspect_bmp(bytes)?;
    if info.width > MAX_PIXEL_DIMENSION || info.height > MAX_PIXEL_DIMENSION {
        return Err(ImageOpError::DimensionsExceeded {
            width: info.width,
            height: info.height,
        });
    }
    let pixel_offset = u32::from_le_bytes([bytes[10], bytes[11], bytes[12], bytes[13]]) as usize;
    let dib_size = u32::from_le_bytes([bytes[14], bytes[15], bytes[16], bytes[17]]) as usize;
    if dib_size < 40 || bytes.len() < 34 || pixel_offset > bytes.len() {
        return Err(ImageOpError::InvalidFormat(
            "unsupported BMP layout".to_owned(),
        ));
    }
    let raw_h = i32::from_le_bytes([bytes[22], bytes[23], bytes[24], bytes[25]]);
    let top_down = raw_h < 0;
    let bpp = u16::from_le_bytes([bytes[28], bytes[29]]);
    let compression = u32::from_le_bytes([bytes[30], bytes[31], bytes[32], bytes[33]]);
    if compression != 0 {
        return Err(ImageOpError::InvalidFormat(
            "compressed BMP unsupported".to_owned(),
        ));
    }
    let w = info.width as usize;
    let h = info.height as usize;
    let stride = (w * usize::from(bpp)).div_ceil(32) * 4;
    if pixel_offset
        .checked_add(stride.saturating_mul(h))
        .is_none_or(|end| end > bytes.len())
    {
        return Err(ImageOpError::InvalidFormat(
            "truncated BMP pixel data".to_owned(),
        ));
    }

    let mut canvas = Canvas::new(w, h, Rgba::WHITE);
    let mut any_alpha = false;
    let palette_off = 14 + dib_size;

    for row_idx in 0..h {
        let dst_y = if top_down { row_idx } else { h - 1 - row_idx };
        let row = &bytes[pixel_offset + row_idx * stride..pixel_offset + (row_idx + 1) * stride];
        match bpp {
            24 => {
                for x in 0..w {
                    let b = f32::from(row[x * 3]) / 255.0;
                    let g = f32::from(row[x * 3 + 1]) / 255.0;
                    let r = f32::from(row[x * 3 + 2]) / 255.0;
                    *canvas.get_mut(x, dst_y) = Rgba::new(r, g, b, 1.0);
                }
            }
            32 => {
                for x in 0..w {
                    let b = f32::from(row[x * 4]) / 255.0;
                    let g = f32::from(row[x * 4 + 1]) / 255.0;
                    let r = f32::from(row[x * 4 + 2]) / 255.0;
                    let a = f32::from(row[x * 4 + 3]) / 255.0;
                    if a < 1.0 {
                        any_alpha = true;
                    }
                    *canvas.get_mut(x, dst_y) = Rgba::new(r, g, b, a);
                }
            }
            8 => {
                for (x, &idx_b) in row.iter().take(w).enumerate() {
                    let pal_i = palette_off + usize::from(idx_b) * 4;
                    if pal_i + 3 >= bytes.len() {
                        return Err(ImageOpError::InvalidFormat(
                            "truncated BMP palette".to_owned(),
                        ));
                    }
                    let b = f32::from(bytes[pal_i]) / 255.0;
                    let g = f32::from(bytes[pal_i + 1]) / 255.0;
                    let r = f32::from(bytes[pal_i + 2]) / 255.0;
                    *canvas.get_mut(x, dst_y) = Rgba::new(r, g, b, 1.0);
                }
            }
            _ => {
                return Err(ImageOpError::InvalidFormat(format!(
                    "unsupported BMP bit depth {bpp}"
                )));
            }
        }
    }
    canvas.has_alpha = any_alpha;
    Ok(canvas)
}

pub fn encode_bmp(canvas: &Canvas) -> Result<Vec<u8>, ImageOpError> {
    let w = canvas.width;
    let h = canvas.height;
    if w == 0 || h == 0 {
        return Err(ImageOpError::Encode("zero BMP dimensions".to_owned()));
    }
    let bpp: u16 = if canvas.has_alpha { 32 } else { 24 };
    let bytes_per_px = usize::from(bpp / 8);
    let row_stride = (w * bytes_per_px).div_ceil(4) * 4;
    let pixel_bytes = row_stride * h;
    let file_size = 54 + pixel_bytes;

    let mut out = Vec::with_capacity(file_size);
    out.extend_from_slice(b"BM");
    out.extend_from_slice(&(file_size as u32).to_le_bytes());
    out.extend_from_slice(&0u32.to_le_bytes());
    out.extend_from_slice(&54u32.to_le_bytes());
    // BITMAPINFOHEADER (40 bytes)
    out.extend_from_slice(&40u32.to_le_bytes());
    out.extend_from_slice(&(w as i32).to_le_bytes());
    out.extend_from_slice(&(h as i32).to_le_bytes());
    out.extend_from_slice(&1u16.to_le_bytes());
    out.extend_from_slice(&bpp.to_le_bytes());
    out.extend_from_slice(&0u32.to_le_bytes());
    out.extend_from_slice(&(pixel_bytes as u32).to_le_bytes());
    out.extend_from_slice(&2835i32.to_le_bytes());
    out.extend_from_slice(&2835i32.to_le_bytes());
    out.extend_from_slice(&0u32.to_le_bytes());
    out.extend_from_slice(&0u32.to_le_bytes());

    let pad = row_stride - w * bytes_per_px;
    for row_idx in 0..h {
        let y = h - 1 - row_idx;
        for x in 0..w {
            let p = canvas.get(x, y);
            out.push(quantize8(p.b));
            out.push(quantize8(p.g));
            out.push(quantize8(p.r));
            if canvas.has_alpha {
                out.push(quantize8(p.a));
            }
        }
        if pad > 0 {
            out.resize(out.len() + pad, 0);
        }
    }
    Ok(out)
}

fn decode_ico(bytes: &[u8]) -> Result<Canvas, ImageOpError> {
    let info = inspect_ico(bytes)?;
    if info.width > MAX_PIXEL_DIMENSION || info.height > MAX_PIXEL_DIMENSION {
        return Err(ImageOpError::DimensionsExceeded {
            width: info.width,
            height: info.height,
        });
    }
    let count = info.frame_count;
    let mut best_idx = 0usize;
    let mut best_area = 0u32;
    for i in 0..count {
        let e = &bytes[6 + i * 16..6 + (i + 1) * 16];
        let w = if e[0] == 0 { 256 } else { u32::from(e[0]) };
        let h = if e[1] == 0 { 256 } else { u32::from(e[1]) };
        if w * h >= best_area {
            best_area = w * h;
            best_idx = i;
        }
    }
    let e = &bytes[6 + best_idx * 16..6 + (best_idx + 1) * 16];
    let size = u32::from_le_bytes([e[8], e[9], e[10], e[11]]) as usize;
    let offset = u32::from_le_bytes([e[12], e[13], e[14], e[15]]) as usize;
    let sub = &bytes[offset..offset + size];
    if sub.starts_with(b"\x89PNG\r\n\x1a\n") {
        return decode_image(sub).map_err(|err| ImageOpError::InvalidFormat(err.to_string()));
    }
    // Uncompressed DIB inside ICO (height in DIB header is 2x icon height for XOR + AND masks).
    if sub.len() < 40 {
        return Err(ImageOpError::InvalidFormat("truncated ICO DIB".to_owned()));
    }
    let dib_size = u32::from_le_bytes([sub[0], sub[1], sub[2], sub[3]]) as usize;
    let w = i32::from_le_bytes([sub[4], sub[5], sub[6], sub[7]]) as usize;
    let h_total = i32::from_le_bytes([sub[8], sub[9], sub[10], sub[11]]).unsigned_abs() as usize;
    let h = h_total / 2;
    let bpp = u16::from_le_bytes([sub[14], sub[15]]);
    if w == 0 || h == 0 || w > MAX_PIXEL_DIMENSION as usize || h > MAX_PIXEL_DIMENSION as usize {
        return Err(ImageOpError::InvalidFormat(
            "invalid ICO DIB dimensions".to_owned(),
        ));
    }
    let xor_stride = (w * usize::from(bpp)).div_ceil(32) * 4;
    let and_stride = w.div_ceil(32) * 4;
    let pal_bytes = if bpp <= 8 { (1usize << bpp) * 4 } else { 0 };
    let xor_off = dib_size + pal_bytes;
    let and_off = xor_off + xor_stride * h;
    if xor_off + xor_stride * h > sub.len() {
        return Err(ImageOpError::InvalidFormat(
            "truncated ICO XOR mask".to_owned(),
        ));
    }
    let mut canvas = Canvas::new(w, h, Rgba::TRANSPARENT);
    canvas.has_alpha = true;
    for row in 0..h {
        let dst_y = h - 1 - row;
        let xor_row = &sub[xor_off + row * xor_stride..xor_off + (row + 1) * xor_stride];
        for x in 0..w {
            let mask_transparent = if and_off + (row + 1) * and_stride <= sub.len() {
                let and_byte = sub[and_off + row * and_stride + (x / 8)];
                ((and_byte >> (7 - (x & 7))) & 1) != 0
            } else {
                false
            };
            match bpp {
                32 => {
                    let b = f32::from(xor_row[x * 4]) / 255.0;
                    let g = f32::from(xor_row[x * 4 + 1]) / 255.0;
                    let r = f32::from(xor_row[x * 4 + 2]) / 255.0;
                    let a = f32::from(xor_row[x * 4 + 3]) / 255.0;
                    *canvas.get_mut(x, dst_y) = Rgba::new(r, g, b, a);
                }
                24 => {
                    let b = f32::from(xor_row[x * 3]) / 255.0;
                    let g = f32::from(xor_row[x * 3 + 1]) / 255.0;
                    let r = f32::from(xor_row[x * 3 + 2]) / 255.0;
                    let a = if mask_transparent { 0.0 } else { 1.0 };
                    *canvas.get_mut(x, dst_y) = Rgba::new(r, g, b, a);
                }
                8 => {
                    let pi = dib_size + usize::from(xor_row[x]) * 4;
                    if pi + 3 >= sub.len() {
                        return Err(ImageOpError::InvalidFormat(
                            "truncated ICO palette".to_owned(),
                        ));
                    }
                    let b = f32::from(sub[pi]) / 255.0;
                    let g = f32::from(sub[pi + 1]) / 255.0;
                    let r = f32::from(sub[pi + 2]) / 255.0;
                    let a = if mask_transparent { 0.0 } else { 1.0 };
                    *canvas.get_mut(x, dst_y) = Rgba::new(r, g, b, a);
                }
                _ => {
                    return Err(ImageOpError::InvalidFormat(format!(
                        "unsupported ICO bit depth {bpp}"
                    )));
                }
            }
        }
    }
    Ok(canvas)
}

pub fn encode_ico(canvas: &Canvas) -> Result<Vec<u8>, ImageOpError> {
    let png_bytes =
        encode_png_preserving_alpha(canvas).map_err(|e| ImageOpError::Encode(e.to_string()))?;
    let mut out = Vec::with_capacity(22 + png_bytes.len());
    out.extend_from_slice(&[0x00, 0x00, 0x01, 0x00, 0x01, 0x00]); // ICONDIR (1 icon)
    out.push(if canvas.width >= 256 {
        0
    } else {
        canvas.width as u8
    });
    out.push(if canvas.height >= 256 {
        0
    } else {
        canvas.height as u8
    });
    out.push(0); // palette count
    out.push(0); // reserved
    out.extend_from_slice(&1u16.to_le_bytes()); // color planes
    out.extend_from_slice(&32u16.to_le_bytes()); // bpp
    out.extend_from_slice(&(png_bytes.len() as u32).to_le_bytes());
    out.extend_from_slice(&22u32.to_le_bytes()); // offset
    out.extend_from_slice(&png_bytes);
    Ok(out)
}

// ============================================================================
// 4. Lightweight Pure-Rust SVG Rasterizer (`LogoSvgUploader#convert_to_png`)
// ============================================================================

#[derive(Clone, Copy)]
struct Affine2D {
    a: f64,
    b: f64,
    c: f64,
    d: f64,
    e: f64,
    f: f64,
}

impl Affine2D {
    const IDENTITY: Self = Self {
        a: 1.0,
        b: 0.0,
        c: 0.0,
        d: 1.0,
        e: 0.0,
        f: 0.0,
    };

    fn then(self, rhs: Self) -> Self {
        Self {
            a: self.a * rhs.a + self.c * rhs.b,
            b: self.b * rhs.a + self.d * rhs.b,
            c: self.a * rhs.c + self.c * rhs.d,
            d: self.b * rhs.c + self.d * rhs.d,
            e: self.a * rhs.e + self.c * rhs.f + self.e,
            f: self.b * rhs.e + self.d * rhs.f + self.f,
        }
    }

    fn apply(self, p: Point) -> Point {
        Point::new(
            self.a * p.x + self.c * p.y + self.e,
            self.b * p.x + self.d * p.y + self.f,
        )
    }

    fn scale_factor(self) -> f64 {
        let sx = self.a.hypot(self.b);
        let sy = self.c.hypot(self.d);
        0.5 * (sx + sy)
    }
}

#[derive(Clone)]
struct SvgStyle {
    fill: Option<Rgba>,
    stroke: Option<Rgba>,
    stroke_width: f64,
    fill_opacity: f32,
    stroke_opacity: f32,
    opacity: f32,
    fill_rule: FillRule,
    line_cap: LineCap,
    line_join: LineJoin,
    transform: Affine2D,
}

impl Default for SvgStyle {
    fn default() -> Self {
        Self {
            fill: Some(Rgba::BLACK),
            stroke: None,
            stroke_width: 1.0,
            fill_opacity: 1.0,
            stroke_opacity: 1.0,
            opacity: 1.0,
            fill_rule: FillRule::NonZero,
            line_cap: LineCap::Butt,
            line_join: LineJoin::Miter,
            transform: Affine2D::IDENTITY,
        }
    }
}

fn parse_svg_length(raw: &str, reference: f64) -> Option<f64> {
    let s = raw.trim();
    if let Some(pct) = s.strip_suffix('%') {
        return pct.trim().parse::<f64>().ok().map(|v| v * 0.01 * reference);
    }
    let num_str = s
        .trim_end_matches("px")
        .trim_end_matches("pt")
        .trim_end_matches("em")
        .trim();
    let v = num_str.parse::<f64>().ok()?;
    if s.ends_with("pt") {
        Some(v * (96.0 / 72.0))
    } else {
        Some(v)
    }
}

fn parse_svg_color(raw: &str, gradients: &HashMap<String, Rgba>) -> Option<Option<Rgba>> {
    let s = raw.trim();
    if s.eq_ignore_ascii_case("none") || s.eq_ignore_ascii_case("transparent") {
        return Some(None);
    }
    if let Some(rest) = s.strip_prefix("url(") {
        let id = rest
            .trim_end_matches(')')
            .trim()
            .trim_matches(['"', '\''])
            .strip_prefix('#')?;
        return Some(gradients.get(id).copied());
    }
    if let Some(rgb_inner) = s.strip_prefix("rgb(").and_then(|v| v.strip_suffix(')')) {
        let parts: Vec<&str> = rgb_inner
            .split([',', ' '])
            .filter(|t| !t.is_empty())
            .collect();
        if parts.len() == 3 {
            let chan = |t: &str| -> Option<f32> {
                if let Some(p) = t.strip_suffix('%') {
                    Some((p.parse::<f32>().ok()? / 100.0).clamp(0.0, 1.0))
                } else {
                    Some((t.parse::<f32>().ok()? / 255.0).clamp(0.0, 1.0))
                }
            };
            return Some(Some(Rgba::new(
                chan(parts[0])?,
                chan(parts[1])?,
                chan(parts[2])?,
                1.0,
            )));
        }
    }
    if let Some(c) = Rgba::parse(s) {
        return Some(Some(c));
    }
    let named = match s.to_ascii_lowercase().as_str() {
        "red" => Rgba::new(1.0, 0.0, 0.0, 1.0),
        "green" => Rgba::new(0.0, 128.0 / 255.0, 0.0, 1.0),
        "blue" => Rgba::new(0.0, 0.0, 1.0, 1.0),
        "gray" | "grey" => Rgba::new(128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0),
        "silver" => Rgba::new(192.0 / 255.0, 192.0 / 255.0, 192.0 / 255.0, 1.0),
        "yellow" => Rgba::new(1.0, 1.0, 0.0, 1.0),
        "orange" => Rgba::new(1.0, 165.0 / 255.0, 0.0, 1.0),
        "purple" => Rgba::new(128.0 / 255.0, 0.0, 128.0 / 255.0, 1.0),
        "cyan" | "aqua" => Rgba::new(0.0, 1.0, 1.0, 1.0),
        "magenta" | "fuchsia" => Rgba::new(1.0, 0.0, 1.0, 1.0),
        "currentcolor" => Rgba::BLACK,
        _ => return None,
    };
    Some(Some(named))
}

fn parse_svg_transform(raw: &str) -> Affine2D {
    let mut out = Affine2D::IDENTITY;
    let mut rest = raw.trim();
    while let Some(open) = rest.find('(') {
        let name = rest[..open].trim();
        let Some(close) = rest[open + 1..].find(')') else {
            break;
        };
        let args_str = &rest[open + 1..open + 1 + close];
        let nums: Vec<f64> = args_str
            .split(|c: char| c == ',' || c.is_ascii_whitespace())
            .filter(|t| !t.is_empty())
            .filter_map(|t| t.parse::<f64>().ok())
            .collect();
        let next = match name {
            "translate" if !nums.is_empty() => Affine2D {
                e: nums[0],
                f: nums.get(1).copied().unwrap_or(0.0),
                ..Affine2D::IDENTITY
            },
            "scale" if !nums.is_empty() => {
                let sx = nums[0];
                let sy = nums.get(1).copied().unwrap_or(sx);
                Affine2D {
                    a: sx,
                    d: sy,
                    ..Affine2D::IDENTITY
                }
            }
            "rotate" if !nums.is_empty() => {
                let rad = nums[0].to_radians();
                let (s, c) = rad.sin_cos();
                let rot = Affine2D {
                    a: c,
                    b: s,
                    c: -s,
                    d: c,
                    e: 0.0,
                    f: 0.0,
                };
                if nums.len() >= 3 {
                    let (cx, cy) = (nums[1], nums[2]);
                    Affine2D {
                        e: cx,
                        f: cy,
                        ..Affine2D::IDENTITY
                    }
                    .then(rot)
                    .then(Affine2D {
                        e: -cx,
                        f: -cy,
                        ..Affine2D::IDENTITY
                    })
                } else {
                    rot
                }
            }
            "matrix" if nums.len() >= 6 => Affine2D {
                a: nums[0],
                b: nums[1],
                c: nums[2],
                d: nums[3],
                e: nums[4],
                f: nums[5],
            },
            _ => Affine2D::IDENTITY,
        };
        out = out.then(next);
        rest = rest[open + 1 + close + 1..].trim_start_matches([',', ' ']);
    }
    out
}

fn parse_xml_attrs(attr_str: &str) -> Vec<(&str, &str)> {
    let mut out = Vec::new();
    let bytes = attr_str.as_bytes();
    let mut i = 0usize;
    while i < bytes.len() {
        while i < bytes.len() && (bytes[i].is_ascii_whitespace() || bytes[i] == b'/') {
            i += 1;
        }
        if i >= bytes.len() {
            break;
        }
        let name_start = i;
        while i < bytes.len()
            && !bytes[i].is_ascii_whitespace()
            && bytes[i] != b'='
            && bytes[i] != b'/'
        {
            i += 1;
        }
        let name = &attr_str[name_start..i];
        while i < bytes.len() && bytes[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= bytes.len() || bytes[i] != b'=' {
            continue;
        }
        i += 1;
        while i < bytes.len() && bytes[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= bytes.len() {
            break;
        }
        let quote = bytes[i];
        if quote == b'"' || quote == b'\'' {
            i += 1;
            let val_start = i;
            while i < bytes.len() && bytes[i] != quote {
                i += 1;
            }
            if !name.is_empty() {
                out.push((name, &attr_str[val_start..i]));
            }
            if i < bytes.len() {
                i += 1;
            }
        } else {
            let val_start = i;
            while i < bytes.len() && !bytes[i].is_ascii_whitespace() && bytes[i] != b'/' {
                i += 1;
            }
            if !name.is_empty() {
                out.push((name, &attr_str[val_start..i]));
            }
        }
    }
    out
}

fn parse_svg_root_geometry(svg: &str) -> Result<(f64, f64, Affine2D), ImageOpError> {
    let Some(svg_idx) = svg.find("<svg") else {
        return Err(ImageOpError::InvalidFormat("missing <svg> tag".to_owned()));
    };
    let after = &svg[svg_idx + 4..];
    let Some(end_idx) = after.find('>') else {
        return Err(ImageOpError::InvalidFormat("unclosed <svg> tag".to_owned()));
    };
    let attrs = parse_xml_attrs(&after[..end_idx]);
    let mut w_attr = None;
    let mut h_attr = None;
    let mut view_box: Option<[f64; 4]> = None;

    for (k, v) in &attrs {
        match *k {
            "width" => w_attr = parse_svg_length(v, 300.0),
            "height" => h_attr = parse_svg_length(v, 150.0),
            "viewBox" => {
                let nums: Vec<f64> = v
                    .split(|c: char| c == ',' || c.is_ascii_whitespace())
                    .filter(|t| !t.is_empty())
                    .filter_map(|t| t.parse::<f64>().ok())
                    .collect();
                if nums.len() == 4 && nums[2] > 0.0 && nums[3] > 0.0 {
                    view_box = Some([nums[0], nums[1], nums[2], nums[3]]);
                }
            }
            _ => {}
        }
    }

    let (w, h) = match (w_attr, h_attr, view_box) {
        (Some(w), Some(h), _) => (w, h),
        (Some(w), None, Some(vb)) => (w, w * (vb[3] / vb[2])),
        (None, Some(h), Some(vb)) => (h * (vb[2] / vb[3]), h),
        (None, None, Some(vb)) => (vb[2], vb[3]),
        (Some(w), None, None) => (w, 150.0),
        (None, Some(h), None) => (300.0, h),
        (None, None, None) => (300.0, 150.0),
    };

    if w <= 0.0 || h <= 0.0 {
        return Err(ImageOpError::InvalidFormat(
            "non-positive SVG dimensions".to_owned(),
        ));
    }

    let root_xform = if let Some([min_x, min_y, vb_w, vb_h]) = view_box {
        let sx = w / vb_w;
        let sy = h / vb_h;
        let scale = sx.min(sy);
        let tx = (w - vb_w * scale) * 0.5 - min_x * scale;
        let ty = (h - vb_h * scale) * 0.5 - min_y * scale;
        Affine2D {
            a: scale,
            b: 0.0,
            c: 0.0,
            d: scale,
            e: tx,
            f: ty,
        }
    } else {
        Affine2D::IDENTITY
    };

    Ok((w, h, root_xform))
}

fn collect_svg_gradients(svg: &str) -> HashMap<String, Rgba> {
    let mut map = HashMap::new();
    let mut cur_id: Option<String> = None;
    let mut stops: Vec<Rgba> = Vec::new();
    let mut pos = 0usize;

    while let Some(rel) = svg[pos..].find('<') {
        let tag_start = pos + rel;
        let rest = &svg[tag_start + 1..];
        if rest.starts_with("!--") {
            if let Some(end) = rest.find("-->") {
                pos = tag_start + 1 + end + 3;
                continue;
            }
            break;
        }
        let Some(end) = rest.find('>') else {
            break;
        };
        let tag_body = &rest[..end];
        pos = tag_start + 1 + end + 1;

        if let Some(close_name) = tag_body.strip_prefix('/') {
            let name = close_name.trim();
            if (name.eq_ignore_ascii_case("linearGradient")
                || name.eq_ignore_ascii_case("radialGradient"))
                && !stops.is_empty()
            {
                if let Some(id) = cur_id.take() {
                    let n = stops.len() as f32;
                    let r = stops.iter().map(|c| c.r).sum::<f32>() / n;
                    let g = stops.iter().map(|c| c.g).sum::<f32>() / n;
                    let b = stops.iter().map(|c| c.b).sum::<f32>() / n;
                    let a = stops.iter().map(|c| c.a).sum::<f32>() / n;
                    map.insert(id, Rgba::new(r, g, b, a));
                }
                stops.clear();
            }
            continue;
        }

        let name_end = tag_body
            .find(|c: char| c.is_ascii_whitespace() || c == '/')
            .unwrap_or(tag_body.len());
        let name = &tag_body[..name_end];
        let attrs = parse_xml_attrs(&tag_body[name_end..]);
        if name.eq_ignore_ascii_case("linearGradient")
            || name.eq_ignore_ascii_case("radialGradient")
        {
            cur_id = attrs
                .iter()
                .find(|(k, _)| *k == "id")
                .map(|(_, v)| (*v).to_owned());
            stops.clear();
        } else if name.eq_ignore_ascii_case("stop") && cur_id.is_some() {
            let mut color = Rgba::BLACK;
            let mut stop_opacity = 1.0f32;
            for (k, v) in &attrs {
                if *k == "stop-color" {
                    if let Some(Some(c)) = parse_svg_color(v, &map) {
                        color = c;
                    }
                } else if *k == "stop-opacity" {
                    if let Ok(op) = v.trim().parse::<f32>() {
                        stop_opacity = op.clamp(0.0, 1.0);
                    }
                } else if *k == "style" {
                    for decl in v.split(';') {
                        if let Some((sk, sv)) = decl.split_once(':') {
                            match sk.trim() {
                                "stop-color" => {
                                    if let Some(Some(c)) = parse_svg_color(sv, &map) {
                                        color = c;
                                    }
                                }
                                "stop-opacity" => {
                                    if let Ok(op) = sv.trim().parse::<f32>() {
                                        stop_opacity = op.clamp(0.0, 1.0);
                                    }
                                }
                                _ => {}
                            }
                        }
                    }
                }
            }
            stops.push(color.with_alpha(color.a * stop_opacity));
        }
    }
    map
}

fn apply_svg_attr(style: &mut SvgStyle, key: &str, val: &str, gradients: &HashMap<String, Rgba>) {
    match key {
        "fill" => {
            if let Some(parsed) = parse_svg_color(val, gradients) {
                style.fill = parsed;
            }
        }
        "stroke" => {
            if let Some(parsed) = parse_svg_color(val, gradients) {
                style.stroke = parsed;
            }
        }
        "stroke-width" => {
            if let Some(w) = parse_svg_length(val, 100.0) {
                style.stroke_width = w.max(0.0);
            }
        }
        "opacity" => {
            if let Ok(v) = val.trim().parse::<f32>() {
                style.opacity *= v.clamp(0.0, 1.0);
            }
        }
        "fill-opacity" => {
            if let Ok(v) = val.trim().parse::<f32>() {
                style.fill_opacity = v.clamp(0.0, 1.0);
            }
        }
        "stroke-opacity" => {
            if let Ok(v) = val.trim().parse::<f32>() {
                style.stroke_opacity = v.clamp(0.0, 1.0);
            }
        }
        "fill-rule" => {
            style.fill_rule = if val.trim().eq_ignore_ascii_case("evenodd") {
                FillRule::EvenOdd
            } else {
                FillRule::NonZero
            };
        }
        "stroke-linecap" => {
            style.line_cap = if val.trim().eq_ignore_ascii_case("round") {
                LineCap::Round
            } else {
                LineCap::Butt
            };
        }
        "stroke-linejoin" => {
            style.line_join = if val.trim().eq_ignore_ascii_case("round") {
                LineJoin::Round
            } else {
                LineJoin::Miter
            };
        }
        "transform" => {
            style.transform = style.transform.then(parse_svg_transform(val));
        }
        "style" => {
            for decl in val.split(';') {
                if let Some((sk, sv)) = decl.split_once(':') {
                    apply_svg_attr(style, sk.trim(), sv.trim(), gradients);
                }
            }
        }
        _ => {}
    }
}

fn parse_points_list(raw: &str) -> Vec<Point> {
    let nums: Vec<f64> = raw
        .split(|c: char| c == ',' || c.is_ascii_whitespace())
        .filter(|t| !t.is_empty())
        .filter_map(|t| t.parse::<f64>().ok())
        .collect();
    let mut pts = Vec::with_capacity(nums.len() / 2);
    let mut i = 0usize;
    while i + 1 < nums.len() {
        pts.push(Point::new(nums[i], nums[i + 1]));
        i += 2;
    }
    pts
}

fn transform_subpaths(subpaths: &[Subpath], xform: Affine2D) -> Vec<Subpath> {
    subpaths
        .iter()
        .map(|s| Subpath {
            points: s.points.iter().map(|&p| xform.apply(p)).collect(),
            closed: s.closed,
        })
        .collect()
}

fn unescape_basic_xml(text: &str) -> String {
    text.replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&apos;", "'")
}

/// Rasterizes an SVG document onto a transparent [`Canvas`] (`-background none`).
pub fn decode_svg(bytes: &[u8], font: Option<&Font>) -> Result<Canvas, ImageOpError> {
    let svg = std::str::from_utf8(bytes)
        .map_err(|_| ImageOpError::InvalidFormat("invalid UTF-8 in SVG".to_owned()))?;
    let (raw_w, raw_h, root_xform) = parse_svg_root_geometry(svg)?;
    let w = raw_w.round().max(1.0) as u32;
    let h = raw_h.round().max(1.0) as u32;
    if w > MAX_PIXEL_DIMENSION || h > MAX_PIXEL_DIMENSION {
        return Err(ImageOpError::DimensionsExceeded {
            width: w,
            height: h,
        });
    }

    let gradients = collect_svg_gradients(svg);
    let mut canvas = Canvas::new(w as usize, h as usize, Rgba::TRANSPARENT);
    let mut style_stack: Vec<SvgStyle> = vec![SvgStyle {
        transform: root_xform,
        ..SvgStyle::default()
    }];
    let mut skip_depth = 0usize;
    let mut pos = 0usize;

    while let Some(rel) = svg[pos..].find('<') {
        let tag_start = pos + rel;
        let rest = &svg[tag_start + 1..];
        if rest.starts_with("!--") {
            if let Some(end) = rest.find("-->") {
                pos = tag_start + 1 + end + 3;
                continue;
            }
            break;
        }
        if rest.starts_with('?') || rest.starts_with('!') {
            if let Some(end) = rest.find('>') {
                pos = tag_start + 1 + end + 1;
                continue;
            }
            break;
        }
        let Some(end) = rest.find('>') else {
            break;
        };
        let tag_body = &rest[..end];
        pos = tag_start + 1 + end + 1;

        if let Some(close_raw) = tag_body.strip_prefix('/') {
            let close_name = close_raw.trim();
            if skip_depth > 0 {
                if matches!(
                    close_name,
                    "defs" | "clipPath" | "mask" | "style" | "title" | "desc" | "metadata"
                ) {
                    skip_depth -= 1;
                }
            } else if matches!(close_name, "g" | "svg" | "a") && style_stack.len() > 1 {
                style_stack.pop();
            }
            continue;
        }

        let self_closing = tag_body.trim_end().ends_with('/');
        let name_end = tag_body
            .find(|c: char| c.is_ascii_whitespace() || c == '/')
            .unwrap_or(tag_body.len());
        let name = &tag_body[..name_end];
        if matches!(
            name,
            "defs" | "clipPath" | "mask" | "style" | "title" | "desc" | "metadata"
        ) {
            if !self_closing {
                skip_depth += 1;
            }
            continue;
        }
        if skip_depth > 0 {
            continue;
        }

        let attrs = parse_xml_attrs(&tag_body[name_end..]);
        let mut cur_style = style_stack.last().cloned().unwrap_or_default();
        for &(k, v) in &attrs {
            apply_svg_attr(&mut cur_style, k, v, &gradients);
        }

        if matches!(name, "svg" | "g" | "a") {
            if !self_closing {
                style_stack.push(cur_style);
            }
            continue;
        }

        let eff_fill = cur_style.fill.map(|c| {
            c.with_alpha((c.a * cur_style.fill_opacity * cur_style.opacity).clamp(0.0, 1.0))
        });
        let eff_stroke = cur_style.stroke.map(|c| {
            c.with_alpha((c.a * cur_style.stroke_opacity * cur_style.opacity).clamp(0.0, 1.0))
        });
        let scale = cur_style.transform.scale_factor();
        let stroke_style = StrokeStyle::new(
            cur_style.stroke_width * scale,
            cur_style.line_cap,
            cur_style.line_join,
        );

        let get_len = |attr_name: &str, ref_dim: f64| -> f64 {
            attrs
                .iter()
                .find(|(k, _)| *k == attr_name)
                .and_then(|(_, v)| parse_svg_length(v, ref_dim))
                .unwrap_or(0.0)
        };

        match name {
            "path" => {
                if let Some((_, d)) = attrs.iter().find(|(k, _)| *k == "d") {
                    let subs = transform_subpaths(&parse_svg_path(d), cur_style.transform);
                    draw_subpaths_styled(
                        &mut canvas,
                        &subs,
                        eff_fill,
                        eff_stroke,
                        stroke_style,
                        cur_style.fill_rule,
                    );
                }
            }
            "rect" => {
                let x = get_len("x", raw_w);
                let y = get_len("y", raw_h);
                let rw = get_len("width", raw_w);
                let rh = get_len("height", raw_h);
                if rw > 0.0 && rh > 0.0 {
                    let rx = get_len("rx", rw);
                    let ry = attrs
                        .iter()
                        .find(|(k, _)| *k == "ry")
                        .and_then(|(_, v)| parse_svg_length(v, rh))
                        .unwrap_or(rx);
                    let sub = if rx > 0.0 || ry > 0.0 {
                        round_rectangle(
                            Point::new(x, y),
                            Point::new(x + rw, y + rh),
                            Point::new(rx, ry),
                        )
                    } else {
                        rectangle(Point::new(x, y), Point::new(x + rw, y + rh))
                    };
                    let subs = transform_subpaths(&[sub], cur_style.transform);
                    draw_subpaths_styled(
                        &mut canvas,
                        &subs,
                        eff_fill,
                        eff_stroke,
                        stroke_style,
                        cur_style.fill_rule,
                    );
                }
            }
            "circle" => {
                let cx = get_len("cx", raw_w);
                let cy = get_len("cy", raw_h);
                let r = get_len("r", raw_w.min(raw_h));
                if r > 0.0 {
                    let sub = circle(Point::new(cx, cy), Point::new(cx + r, cy));
                    let subs = transform_subpaths(&[sub], cur_style.transform);
                    draw_subpaths_styled(
                        &mut canvas,
                        &subs,
                        eff_fill,
                        eff_stroke,
                        stroke_style,
                        cur_style.fill_rule,
                    );
                }
            }
            "ellipse" => {
                let cx = get_len("cx", raw_w);
                let cy = get_len("cy", raw_h);
                let rx = get_len("rx", raw_w);
                let ry = get_len("ry", raw_h);
                if rx > 0.0 && ry > 0.0 {
                    let sub = ellipse(Point::new(cx, cy), Point::new(rx, ry));
                    let subs = transform_subpaths(&[sub], cur_style.transform);
                    draw_subpaths_styled(
                        &mut canvas,
                        &subs,
                        eff_fill,
                        eff_stroke,
                        stroke_style,
                        cur_style.fill_rule,
                    );
                }
            }
            "line" => {
                let x1 = get_len("x1", raw_w);
                let y1 = get_len("y1", raw_h);
                let x2 = get_len("x2", raw_w);
                let y2 = get_len("y2", raw_h);
                let sub = line(Point::new(x1, y1), Point::new(x2, y2));
                let subs = transform_subpaths(&[sub], cur_style.transform);
                draw_subpaths_styled(
                    &mut canvas,
                    &subs,
                    None,
                    eff_stroke,
                    stroke_style,
                    cur_style.fill_rule,
                );
            }
            "polygon" => {
                if let Some((_, pts_raw)) = attrs.iter().find(|(k, _)| *k == "points") {
                    let sub = polygon(&parse_points_list(pts_raw));
                    let subs = transform_subpaths(&[sub], cur_style.transform);
                    draw_subpaths_styled(
                        &mut canvas,
                        &subs,
                        eff_fill,
                        eff_stroke,
                        stroke_style,
                        cur_style.fill_rule,
                    );
                }
            }
            "polyline" => {
                if let Some((_, pts_raw)) = attrs.iter().find(|(k, _)| *k == "points") {
                    let sub = polyline(&parse_points_list(pts_raw));
                    let subs = transform_subpaths(&[sub], cur_style.transform);
                    draw_subpaths_styled(
                        &mut canvas,
                        &subs,
                        eff_fill,
                        eff_stroke,
                        stroke_style,
                        cur_style.fill_rule,
                    );
                }
            }
            "text" if !self_closing => {
                if let Some(close_rel) = svg[pos..].find("</text>") {
                    let inner = unescape_basic_xml(svg[pos..pos + close_rel].trim());
                    pos += close_rel + "</text>".len();
                    if let (Some(f), Some(fill_c)) = (font, eff_fill) {
                        if !inner.is_empty() {
                            let font_size = attrs
                                .iter()
                                .find(|(k, _)| *k == "font-size")
                                .and_then(|(_, v)| parse_svg_length(v, raw_h))
                                .unwrap_or(16.0)
                                * scale;
                            let anchor = attrs
                                .iter()
                                .find(|(k, _)| *k == "text-anchor")
                                .map(|(_, v)| v.trim())
                                .unwrap_or("start");
                            let pt = cur_style
                                .transform
                                .apply(Point::new(get_len("x", raw_w), get_len("y", raw_h)));
                            let rendered = render_label(f, &inner, font_size.max(4.0), fill_c);
                            let dx = match anchor {
                                "middle" => pt.x.round() as i64 - (rendered.width as i64) / 2,
                                "end" => pt.x.round() as i64 - rendered.width as i64,
                                _ => pt.x.round() as i64,
                            };
                            let dy = pt.y.round() as i64 - (rendered.height as i64) / 2;
                            canvas.composite_over(&rendered, dx, dy);
                        }
                    }
                }
            }
            _ => {}
        }
    }

    Ok(canvas)
}

// ============================================================================
// 5. Unified Decode/Encode, CarrierWave Resizing & Subforem Compositing
// ============================================================================

/// Decodes any supported image format (PNG, JPEG, GIF first frame, WebP, BMP, ICO, or SVG)
/// into an auto-oriented [`Canvas`] along with its detected [`ImageFormat`].
pub fn decode_any_oriented(
    bytes: &[u8],
    font: Option<&Font>,
) -> Result<(Canvas, ImageFormat), ImageOpError> {
    let info = inspect_image(bytes)?;
    if info.width > MAX_PIXEL_DIMENSION || info.height > MAX_PIXEL_DIMENSION {
        return Err(ImageOpError::DimensionsExceeded {
            width: info.width,
            height: info.height,
        });
    }
    let raw_canvas = match info.format {
        ImageFormat::Png | ImageFormat::Jpeg | ImageFormat::Gif | ImageFormat::Webp => {
            decode_image(bytes).map_err(|e| ImageOpError::InvalidFormat(e.to_string()))?
        }
        ImageFormat::Bmp => decode_bmp(bytes)?,
        ImageFormat::Ico => decode_ico(bytes)?,
        ImageFormat::Svg => decode_svg(bytes, font)?,
        ImageFormat::Tiff => {
            return Err(ImageOpError::InvalidFormat(
                "TIFF/DNG pixel rasterization unsupported".to_owned(),
            ));
        }
    };
    let oriented = orient_canvas(&raw_canvas, info.exif_orientation);
    Ok((oriented, info.format))
}

fn encode_in_format(
    canvas: &Canvas,
    format: ImageFormat,
) -> Result<(Vec<u8>, ImageFormat), ImageOpError> {
    match format {
        ImageFormat::Jpeg => Ok((encode_jpeg(canvas, 90)?, ImageFormat::Jpeg)),
        ImageFormat::Png | ImageFormat::Svg | ImageFormat::Tiff => {
            let out = encode_png_preserving_alpha(canvas)
                .map_err(|e| ImageOpError::Encode(e.to_string()))?;
            Ok((out, ImageFormat::Png))
        }
        ImageFormat::Webp => Ok((encode_webp(canvas)?, ImageFormat::Webp)),
        ImageFormat::Gif => Ok((encode_gif(canvas)?, ImageFormat::Gif)),
        ImageFormat::Bmp => Ok((encode_bmp(canvas)?, ImageFormat::Bmp)),
        ImageFormat::Ico => Ok((encode_ico(canvas)?, ImageFormat::Ico)),
    }
}

/// Resizes and crops `canvas` to fill `(target_w, target_h)` (`-resize {w}x{h}^ -gravity {g} -extent {w}x{h}`).
pub fn resize_to_fill_canvas(
    canvas: &Canvas,
    target_w: usize,
    target_h: usize,
    gravity: &str,
) -> Canvas {
    if canvas.width == 0 || canvas.height == 0 || target_w == 0 || target_h == 0 {
        return Canvas::new(target_w, target_h, Rgba::TRANSPARENT);
    }
    if canvas.width == target_w && canvas.height == target_h {
        return canvas.clone();
    }
    let scale = (target_w as f64 / canvas.width as f64).max(target_h as f64 / canvas.height as f64);
    let scaled_w = (canvas.width as f64 * scale).round().max(target_w as f64) as usize;
    let scaled_h = (canvas.height as f64 * scale).round().max(target_h as f64) as usize;
    let scaled = resize(canvas, scaled_w, scaled_h, ResizeFilter::Auto);

    if scaled_w == target_w && scaled_h == target_h {
        return scaled;
    }

    let g = gravity.trim().to_ascii_lowercase();
    let off_x = if g.contains("west") {
        0
    } else if g.contains("east") {
        scaled_w - target_w
    } else {
        (scaled_w - target_w) / 2
    };
    let off_y = if g.contains("north") {
        0
    } else if g.contains("south") {
        scaled_h - target_h
    } else {
        (scaled_h - target_h) / 2
    };

    let mut out = Canvas::new(target_w, target_h, Rgba::TRANSPARENT);
    out.has_alpha = scaled.has_alpha;
    out.is_pseudo = scaled.is_pseudo;
    for y in 0..target_h {
        let src_row = &scaled.pixels
            [(off_y + y) * scaled_w + off_x..(off_y + y) * scaled_w + off_x + target_w];
        out.pixels[y * target_w..(y + 1) * target_w].copy_from_slice(src_row);
    }
    out
}

/// Downscales `canvas` to fit within `(max_w, max_h)` without upscaling (`-resize {max_w}x{max_h}>`).
pub fn resize_to_limit_canvas(
    canvas: &Canvas,
    max_w: Option<usize>,
    max_h: Option<usize>,
) -> Canvas {
    if canvas.width == 0 || canvas.height == 0 {
        return canvas.clone();
    }
    let sx = match max_w {
        Some(w) if w > 0 => w as f64 / canvas.width as f64,
        _ => f64::INFINITY,
    };
    let sy = match max_h {
        Some(h) if h > 0 => h as f64 / canvas.height as f64,
        _ => f64::INFINITY,
    };
    let scale = sx.min(sy);
    if !scale.is_finite() || scale >= 1.0 {
        return canvas.clone();
    }
    let mut new_w = (canvas.width as f64 * scale + 0.5).floor().max(1.0) as usize;
    let mut new_h = (canvas.height as f64 * scale + 0.5).floor().max(1.0) as usize;
    if let Some(mw) = max_w {
        if mw > 0 {
            new_w = new_w.min(mw);
        }
    }
    if let Some(mh) = max_h {
        if mh > 0 {
            new_h = new_h.min(mh);
        }
    }
    resize(canvas, new_w, new_h, ResizeFilter::Auto)
}

/// CarrierWave `resize_to_fill` replacement: decodes, EXIF-orients, center-cover resizes, and
/// re-encodes in the image's format.
pub fn resize_to_fill_bytes(
    bytes: &[u8],
    width: usize,
    height: usize,
    gravity: &str,
    font: Option<&Font>,
) -> Result<(Vec<u8>, ImageFormat), ImageOpError> {
    if width == 0
        || height == 0
        || width > MAX_PIXEL_DIMENSION as usize
        || height > MAX_PIXEL_DIMENSION as usize
    {
        return Err(ImageOpError::DimensionsExceeded {
            width: width as u32,
            height: height as u32,
        });
    }
    let (canvas, fmt) = decode_any_oriented(bytes, font)?;
    let resized = resize_to_fill_canvas(&canvas, width, height, gravity);
    encode_in_format(&resized, fmt)
}

/// CarrierWave `resize_to_limit` replacement: decodes, EXIF-orients, downscales if larger than
/// `(max_width, max_height)`, and re-encodes in the image's format.
pub fn resize_to_limit_bytes(
    bytes: &[u8],
    max_width: Option<usize>,
    max_height: Option<usize>,
    font: Option<&Font>,
) -> Result<(Vec<u8>, ImageFormat), ImageOpError> {
    let (canvas, fmt) = decode_any_oriented(bytes, font)?;
    let resized = resize_to_limit_canvas(&canvas, max_width, max_height);
    encode_in_format(&resized, fmt)
}

/// `LogoSvgUploader#convert_to_png` replacement: converts an SVG (with transparent background)
/// or raster image into an alpha-preserving PNG.
pub fn convert_to_png_bytes(bytes: &[u8], font: Option<&Font>) -> Result<Vec<u8>, ImageOpError> {
    let (canvas, _) = decode_any_oriented(bytes, font)?;
    encode_png_preserving_alpha(&canvas).map_err(|e| ImageOpError::Encode(e.to_string()))
}

/// `Images::GenerateSubforemImages#resize_image` replacement: decodes `bytes`, EXIF-orients,
/// resizes proportionally via `resize_fit(width, height)`, and encodes an alpha-preserving PNG.
pub fn subforem_resize_png(
    bytes: &[u8],
    width: usize,
    height: usize,
    font: Option<&Font>,
) -> Result<Vec<u8>, ImageOpError> {
    if width == 0 || height == 0 {
        return Err(ImageOpError::Encode(
            "zero subforem resize target".to_owned(),
        ));
    }
    let (canvas, _) = decode_any_oriented(bytes, font)?;
    let resized = resize_fit(&canvas, width, height);
    encode_png_preserving_alpha(&resized).map_err(|e| ImageOpError::Encode(e.to_string()))
}

/// `Images::GenerateSubforemImages#create_social_image` replacement:
/// * When `custom_background` is true, resizes and center-crops `background_bytes` to `1000x500`
///   (`-resize 1000x500^ -gravity Center -extent 1000x500`).
/// * Resizes `logo_bytes` with `300x300` fit and composites it with `Over` at `+350+100`.
pub fn subforem_social_image_png(
    logo_bytes: &[u8],
    background_bytes: &[u8],
    custom_background: bool,
    font: Option<&Font>,
) -> Result<Vec<u8>, ImageOpError> {
    let (bg_raw, _) = decode_any_oriented(background_bytes, font)?;
    let mut bg = if custom_background {
        resize_to_fill_canvas(&bg_raw, 1000, 500, "Center")
    } else {
        bg_raw
    };
    let (logo_raw, _) = decode_any_oriented(logo_bytes, font)?;
    let logo_resized = resize_fit(&logo_raw, 300, 300);
    bg.composite_over(&logo_resized, 350, 100);
    encode_png_preserving_alpha(&bg).map_err(|e| ImageOpError::Encode(e.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn build_exif_app1_orientation(orientation: u16) -> Vec<u8> {
        let mut payload = Vec::new();
        payload.extend_from_slice(b"Exif\0\0");
        // Little-endian TIFF header + IFD0 at offset 8 with 1 entry (0x0112 SHORT 1 <orientation>)
        payload.extend_from_slice(b"II*\x00\x08\x00\x00\x00");
        payload.extend_from_slice(&1u16.to_le_bytes()); // 1 tag
        payload.extend_from_slice(&0x0112u16.to_le_bytes()); // Orientation
        payload.extend_from_slice(&3u16.to_le_bytes()); // SHORT
        payload.extend_from_slice(&1u32.to_le_bytes()); // count = 1
        payload.extend_from_slice(&orientation.to_le_bytes());
        payload.extend_from_slice(&0u16.to_le_bytes()); // pad
        payload.extend_from_slice(&0u32.to_le_bytes()); // next IFD = 0
        payload
    }

    fn inject_jpeg_app1(jpeg: &[u8], app1_payload: &[u8]) -> Vec<u8> {
        let mut out = Vec::with_capacity(jpeg.len() + app1_payload.len() + 4);
        out.extend_from_slice(&jpeg[0..2]); // SOI
        out.extend_from_slice(&[0xFF, 0xE1]);
        out.extend_from_slice(&((app1_payload.len() + 2) as u16).to_be_bytes());
        out.extend_from_slice(app1_payload);
        out.extend_from_slice(&jpeg[2..]);
        out
    }

    #[test]
    fn jpeg_roundtrip_strip_trailing_bytes_and_all_8_exif_orientations() {
        let mut src = Canvas::new(24, 12, Rgba::parse("#2563eb").unwrap());
        *src.get_mut(0, 0) = Rgba::new(1.0, 0.0, 0.0, 1.0);
        let clean_jpeg = encode_jpeg(&src, 92).unwrap();
        let info = inspect_image(&clean_jpeg).unwrap();
        assert_eq!(info.format, ImageFormat::Jpeg);
        assert_eq!((info.width, info.height, info.frame_count), (24, 12, 1));
        assert_eq!(strip_and_auto_orient(&clean_jpeg, 150).unwrap(), None);

        // Inject APP1 EXIF orientation=1 + COM + trailing Motion Photo payload after EOI.
        let mut dirty = inject_jpeg_app1(&clean_jpeg, &build_exif_app1_orientation(1));
        dirty.extend_from_slice(b"TrailingMotionPhotoMetadataPayload");
        let stripped = strip_and_auto_orient(&dirty, 150).unwrap().unwrap();
        assert!(stripped.ends_with(b"\xFF\xD9"));
        assert!(!stripped.windows(4).any(|w| w == b"Exif"));
        assert!(!stripped.windows(8).any(|w| w == b"Trailing"));

        // frame_strip_max = 0 leaves metadata intact.
        assert_eq!(strip_and_auto_orient(&dirty, 0).unwrap(), None);

        // Orientations 2..=8 rotate/mirror pixels and strip EXIF.
        for orient in 2u16..=8 {
            let rotated_src = inject_jpeg_app1(&clean_jpeg, &build_exif_app1_orientation(orient));
            let out = strip_and_auto_orient(&rotated_src, 150).unwrap().unwrap();
            let out_info = inspect_image(&out).unwrap();
            assert_eq!(out_info.exif_orientation, 1);
            if orient >= 5 {
                assert_eq!((out_info.width, out_info.height), (12, 24));
            } else {
                assert_eq!((out_info.width, out_info.height), (24, 12));
            }
        }
    }

    #[test]
    fn animated_webp_strips_exif_and_xmp_losslessly_without_corrupting_frames() {
        // Synthesize an extended animated WebP container: VP8X (ANIM|EXIF|XMP) + ANIM + 2x ANMF + EXIF + XMP.
        let mut webp = Vec::new();
        webp.extend_from_slice(b"RIFF\x00\x00\x00\x00WEBP");
        // VP8X chunk (flags: ANIM 0x02 | EXIF 0x08 | XMP 0x04 = 0x0E; 15x9 -> 16x10)
        webp.extend_from_slice(b"VP8X");
        webp.extend_from_slice(&10u32.to_le_bytes());
        webp.extend_from_slice(&[0x0E, 0, 0, 0, 15, 0, 0, 9, 0, 0]);
        // ANIM chunk (6 bytes)
        webp.extend_from_slice(b"ANIM");
        webp.extend_from_slice(&6u32.to_le_bytes());
        webp.extend_from_slice(&[0, 0, 0, 0, 0, 0]);
        // Two ANMF chunks (16 bytes each)
        for _ in 0..2 {
            webp.extend_from_slice(b"ANMF");
            webp.extend_from_slice(&16u32.to_le_bytes());
            webp.extend_from_slice(&[0u8; 16]);
        }
        // EXIF chunk (odd length 7 bytes + 1 pad byte)
        webp.extend_from_slice(b"EXIF");
        webp.extend_from_slice(&7u32.to_le_bytes());
        webp.extend_from_slice(b"GPSDATA\x00");
        // XMP chunk (8 bytes)
        webp.extend_from_slice(b"XMP ");
        webp.extend_from_slice(&8u32.to_le_bytes());
        webp.extend_from_slice(b"<xmpmeta");
        let riff_len = (webp.len() - 8) as u32;
        webp[4..8].copy_from_slice(&riff_len.to_le_bytes());

        let info = inspect_image(&webp).unwrap();
        assert_eq!(info.format, ImageFormat::Webp);
        assert_eq!((info.width, info.height, info.frame_count), (16, 10, 2));

        let stripped = strip_and_auto_orient(&webp, 150).unwrap().unwrap();
        assert!(!stripped.windows(7).any(|w| w == b"GPSDATA"));
        assert!(!stripped.windows(8).any(|w| w == b"<xmpmeta"));
        // VP8X flags have EXIF (0x08) and XMP (0x04) cleared, keeping ANIM (0x02).
        assert_eq!(stripped[20], 0x02);
        let stripped_info = inspect_image(&stripped).unwrap();
        assert_eq!(stripped_info.frame_count, 2);
        assert_eq!((stripped_info.width, stripped_info.height), (16, 10));
    }

    #[test]
    fn preserves_alpha_on_png_resize_and_rasterizes_svgs() {
        let mut src = Canvas::new(200, 100, Rgba::TRANSPARENT);
        *src.get_mut(100, 50) = Rgba::new(0.2, 0.4, 0.8, 1.0);
        let png_bytes = encode_png_preserving_alpha(&src).unwrap();

        let (limited, fmt) = resize_to_limit_bytes(&png_bytes, None, Some(80), None).unwrap();
        assert_eq!(fmt, ImageFormat::Png);
        let dec = decode_image(&limited).unwrap();
        assert_eq!((dec.width, dec.height), (160, 80));
        assert!(dec.has_alpha);
        assert_eq!(dec.get(0, 0).a, 0.0);

        let svg = br##"<svg width="64" height="32" viewBox="0 0 64 32" xmlns="http://www.w3.org/2000/svg">
            <defs><linearGradient id="g"><stop stop-color="#ff0000"/><stop offset="1" stop-color="#0000ff"/></linearGradient></defs>
            <rect x="4" y="4" width="56" height="24" rx="6" fill="url(#g)"/>
        </svg>"##;
        let svg_png = convert_to_png_bytes(svg, None).unwrap();
        let svg_dec = decode_image(&svg_png).unwrap();
        assert_eq!((svg_dec.width, svg_dec.height), (64, 32));
        assert!(svg_dec.has_alpha);
        assert_eq!(svg_dec.get(0, 0).a, 0.0);
        assert_eq!(svg_dec.get(32, 16).a, 1.0);
    }

    #[test]
    fn guards_against_cyclic_tiff_ifd_chains() {
        // IFD0 at offset 8 whose next-IFD pointer points back to offset 8!
        let mut cyclic = Vec::new();
        cyclic.extend_from_slice(b"II*\x00\x08\x00\x00\x00");
        cyclic.extend_from_slice(&1u16.to_le_bytes()); // 1 entry
        cyclic.extend_from_slice(&0x0100u16.to_le_bytes()); // ImageWidth
        cyclic.extend_from_slice(&4u16.to_le_bytes()); // LONG
        cyclic.extend_from_slice(&1u32.to_le_bytes());
        cyclic.extend_from_slice(&320u32.to_le_bytes());
        cyclic.extend_from_slice(&8u32.to_le_bytes()); // cycle back to 8!

        let info = inspect_image(&cyclic).unwrap();
        assert_eq!(info.format, ImageFormat::Tiff);
        assert_eq!(info.width, 320);
        assert_eq!(info.frame_count, 1);
    }

    #[test]
    fn processes_real_forem_fixtures_end_to_end() {
        let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../../..");
        let fixtures = root.join("spec/fixtures/files");
        let assets = root.join("app/assets/images");
        let font_bytes = std::fs::read(root.join("app/assets/fonts/NotoSans-Bold.ttf")).unwrap();
        let font = crate::social_image::Font::from_bytes(&font_bytes).unwrap();

        // 1. Multi-frame GIF (`high_frame_count.gif`, > 20 frames as used in uploader specs)
        let gif_bytes = std::fs::read(fixtures.join("high_frame_count.gif")).unwrap();
        let gif_info = inspect_image(&gif_bytes).unwrap();
        assert_eq!(gif_info.format, ImageFormat::Gif);
        assert!(gif_info.frame_count > 20);
        assert_eq!(strip_and_auto_orient(&gif_bytes, 20).unwrap(), None);

        // 2. Real GPS JPEG (`image_gps_data.jpg`) — stripped losslessly
        let gps_jpg = std::fs::read(fixtures.join("image_gps_data.jpg")).unwrap();
        let stripped_jpg = strip_and_auto_orient(&gps_jpg, 150).unwrap().unwrap();
        assert!(stripped_jpg.len() < gps_jpg.len());
        assert!(!stripped_jpg.windows(6).any(|w| w == b"Exif\x00\x00"));

        // 3. Real WebP (`800x600.webp`) — resize_to_fill & resize_to_limit
        let webp_bytes = std::fs::read(fixtures.join("800x600.webp")).unwrap();
        let (filled_webp, fmt) =
            resize_to_fill_bytes(&webp_bytes, 250, 250, "Center", None).unwrap();
        assert_eq!(fmt, ImageFormat::Webp);
        let fw_info = inspect_image(&filled_webp).unwrap();
        assert_eq!((fw_info.width, fw_info.height), (250, 250));

        // 4. Real SVGs (`300x100.svg` with `<text>`, `unicorn.svg` with trailing `<defs>`,
        //    `logo-forem-app.svg`, `forem-icon.svg`)
        for svg_path in [
            fixtures.join("300x100.svg"),
            fixtures.join("unicorn.svg"),
            assets.join("logo-forem-app.svg"),
            assets.join("forem-icon.svg"),
        ] {
            let svg_bytes = std::fs::read(&svg_path).unwrap();
            let expected = inspect_image(&svg_bytes).unwrap();
            let png = convert_to_png_bytes(&svg_bytes, Some(&font)).unwrap();
            let p_info = inspect_image(&png).unwrap();
            assert_eq!(p_info.format, ImageFormat::Png);
            assert_eq!(
                (p_info.width, p_info.height),
                (expected.width, expected.height)
            );
        }

        // 5. Subforem social image generation (`subforem_social_image_png`)
        let logo_png =
            convert_to_png_bytes(&std::fs::read(assets.join("forem-icon.svg")).unwrap(), None)
                .unwrap();
        let bg_png = std::fs::read(assets.join("social_template.png")).unwrap();
        let bg_info = inspect_image(&bg_png).unwrap();
        let social = subforem_social_image_png(&logo_png, &bg_png, false, Some(&font)).unwrap();
        let s_info = inspect_image(&social).unwrap();
        assert_eq!(s_info.format, ImageFormat::Png);
        assert_eq!(
            (s_info.width, s_info.height),
            (bg_info.width, bg_info.height)
        );
        let custom_social =
            subforem_social_image_png(&logo_png, &webp_bytes, true, Some(&font)).unwrap();
        let cs_info = inspect_image(&custom_social).unwrap();
        assert_eq!((cs_info.width, cs_info.height), (1000, 500));
    }

    #[test]
    fn roundtrips_bmp_and_ico_and_strips_gif_comments_and_png_exif() {
        // BMP roundtrip + resize
        let mut c = Canvas::new(20, 12, Rgba::new(0.25, 0.5, 0.75, 1.0));
        *c.get_mut(0, 0) = Rgba::new(1.0, 0.0, 0.0, 1.0);
        let bmp = encode_bmp(&c).unwrap();
        assert_eq!(inspect_image(&bmp).unwrap().format, ImageFormat::Bmp);
        let (resized_bmp, fmt) = resize_to_fill_bytes(&bmp, 10, 10, "Center", None).unwrap();
        assert_eq!(fmt, ImageFormat::Bmp);
        assert_eq!(
            (
                inspect_image(&resized_bmp).unwrap().width,
                inspect_image(&resized_bmp).unwrap().height
            ),
            (10, 10)
        );

        // ICO roundtrip + resize
        let ico = encode_ico(&c).unwrap();
        assert_eq!(inspect_image(&ico).unwrap().format, ImageFormat::Ico);
        let (resized_ico, fmt_ico) = resize_to_limit_bytes(&ico, Some(8), Some(8), None).unwrap();
        assert_eq!(fmt_ico, ImageFormat::Ico);
        let ico_info = inspect_image(&resized_ico).unwrap();
        assert_eq!((ico_info.width, ico_info.height), (8, 5));

        // GIF comment extension stripping
        let base_gif = encode_gif(&c).unwrap();
        let mut gif_with_comment = base_gif[..base_gif.len() - 1].to_vec();
        gif_with_comment.extend_from_slice(b"\x21\xFE\x06SECRET\x00\x3B");
        let stripped_gif = strip_and_auto_orient(&gif_with_comment, 150)
            .unwrap()
            .unwrap();
        assert!(!stripped_gif.windows(6).any(|w| w == b"SECRET"));
        assert_eq!(inspect_image(&stripped_gif).unwrap().frame_count, 1);

        // PNG with `eXIf` orientation 6 -> rotated 90 CW and `eXIf` removed!
        let png_base = encode_png_preserving_alpha(&c).unwrap();
        let mut png_exif = Vec::new();
        png_exif.extend_from_slice(&png_base[..33]); // signature (8) + IHDR chunk (25)
        let exif_payload = &build_exif_app1_orientation(6)[6..];
        png_exif.extend_from_slice(&(exif_payload.len() as u32).to_be_bytes());
        png_exif.extend_from_slice(b"eXIf");
        png_exif.extend_from_slice(exif_payload);
        png_exif.extend_from_slice(&0u32.to_be_bytes()); // CRC ignored by header scanner
        png_exif.extend_from_slice(&png_base[33..]);
        let oriented_png = strip_and_auto_orient(&png_exif, 150).unwrap().unwrap();
        let op_info = inspect_image(&oriented_png).unwrap();
        assert_eq!((op_info.width, op_info.height), (12, 20));
        assert_eq!(op_info.exif_orientation, 1);
    }
}
