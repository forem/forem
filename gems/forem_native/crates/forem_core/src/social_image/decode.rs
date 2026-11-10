//! Pure-Rust image decoding (PNG, JPEG, GIF first frame, and WebP) for logos, author
//! avatars, and the rounded mask.
//!
//! Animated GIFs decode only the first frame (`[0]`), matching `@author_image.collapse!`
//! without allocating or resizing subsequent animation frames.

use std::io::Cursor;

use super::canvas::{Canvas, Rgba};
use super::SocialImageError;

const MAX_DIMENSION: u32 = 16_384;

/// Decodes a PNG, JPEG, GIF (first frame), or WebP byte slice into a straight-alpha [`Canvas`].
pub fn decode_image(bytes: &[u8]) -> Result<Canvas, SocialImageError> {
    if bytes.len() < 4 {
        return Err(SocialImageError::InvalidImage(
            "empty or truncated image".to_owned(),
        ));
    }
    if bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
        decode_png(bytes)
    } else if bytes.starts_with(b"\xFF\xD8\xFF") {
        decode_jpeg(bytes)
    } else if bytes.starts_with(b"GIF87a") || bytes.starts_with(b"GIF89a") {
        decode_gif_first_frame(bytes)
    } else if bytes.len() >= 12 && &bytes[0..4] == b"RIFF" && &bytes[8..12] == b"WEBP" {
        decode_webp(bytes)
    } else {
        Err(SocialImageError::InvalidImage(
            "unsupported or corrupt image header".to_owned(),
        ))
    }
}

fn validate_dimensions(width: u32, height: u32) -> Result<(usize, usize), SocialImageError> {
    if width == 0 || height == 0 || width > MAX_DIMENSION || height > MAX_DIMENSION {
        return Err(SocialImageError::InvalidImage(format!(
            "invalid image dimensions {width}x{height}"
        )));
    }
    Ok((width as usize, height as usize))
}

fn decode_png(bytes: &[u8]) -> Result<Canvas, SocialImageError> {
    let mut decoder = png::Decoder::new(Cursor::new(bytes));
    // Expand palette/sub-byte depths to 8-bit and strip 16-bit down to 8-bit channels.
    decoder.set_transformations(png::Transformations::EXPAND | png::Transformations::STRIP_16);
    let mut reader = decoder
        .read_info()
        .map_err(|e| SocialImageError::InvalidImage(format!("PNG header error: {e}")))?;

    let (raw_color_type, raw_has_trns) = {
        let info = reader.info();
        (info.color_type, info.trns.is_some())
    };
    let is_pseudo = matches!(
        raw_color_type,
        png::ColorType::Indexed | png::ColorType::Grayscale
    );
    let has_alpha = matches!(
        raw_color_type,
        png::ColorType::Rgba | png::ColorType::GrayscaleAlpha
    ) || raw_has_trns;

    let (w, h) = validate_dimensions(reader.info().width, reader.info().height)?;
    let buf_size = reader
        .output_buffer_size()
        .ok_or_else(|| SocialImageError::InvalidImage("PNG buffer overflow".to_owned()))?;
    let mut buf = vec![0u8; buf_size];
    let out_info = reader
        .next_frame(&mut buf)
        .map_err(|e| SocialImageError::InvalidImage(format!("PNG decode error: {e}")))?;
    let data = &buf[..out_info.buffer_size()];

    let mut pixels = Vec::with_capacity(w * h);
    match out_info.color_type {
        png::ColorType::Rgb => {
            for chunk in data.chunks_exact(3) {
                pixels.push(Rgba::new(
                    f32::from(chunk[0]) / 255.0,
                    f32::from(chunk[1]) / 255.0,
                    f32::from(chunk[2]) / 255.0,
                    1.0,
                ));
            }
        }
        png::ColorType::Rgba => {
            for chunk in data.chunks_exact(4) {
                pixels.push(Rgba::new(
                    f32::from(chunk[0]) / 255.0,
                    f32::from(chunk[1]) / 255.0,
                    f32::from(chunk[2]) / 255.0,
                    f32::from(chunk[3]) / 255.0,
                ));
            }
        }
        png::ColorType::Grayscale => {
            for &g in data.iter().take(w * h) {
                let v = f32::from(g) / 255.0;
                pixels.push(Rgba::new(v, v, v, 1.0));
            }
        }
        png::ColorType::GrayscaleAlpha => {
            for chunk in data.chunks_exact(2) {
                let v = f32::from(chunk[0]) / 255.0;
                let a = f32::from(chunk[1]) / 255.0;
                pixels.push(Rgba::new(v, v, v, a));
            }
        }
        other => {
            return Err(SocialImageError::InvalidImage(format!(
                "unexpected expanded PNG color type: {other:?}"
            )));
        }
    }
    if pixels.len() != w * h {
        return Err(SocialImageError::InvalidImage(
            "truncated PNG pixel data".to_owned(),
        ));
    }
    Ok(Canvas {
        width: w,
        height: h,
        pixels,
        has_alpha,
        is_pseudo,
    })
}

fn decode_jpeg(bytes: &[u8]) -> Result<Canvas, SocialImageError> {
    let mut decoder = zune_jpeg::JpegDecoder::new(Cursor::new(bytes));
    decoder
        .decode_headers()
        .map_err(|e| SocialImageError::InvalidImage(format!("JPEG header error: {e}")))?;
    let (width, height) = decoder
        .dimensions()
        .ok_or_else(|| SocialImageError::InvalidImage("missing JPEG dimensions".to_owned()))?;
    let (w, h) = validate_dimensions(width as u32, height as u32)?;
    let data = decoder
        .decode()
        .map_err(|e| SocialImageError::InvalidImage(format!("JPEG decode error: {e}")))?;

    let mut pixels = Vec::with_capacity(w * h);
    let mut is_pseudo = false;
    if data.len() == w * h * 3 {
        for chunk in data.chunks_exact(3) {
            pixels.push(Rgba::new(
                f32::from(chunk[0]) / 255.0,
                f32::from(chunk[1]) / 255.0,
                f32::from(chunk[2]) / 255.0,
                1.0,
            ));
        }
    } else if data.len() == w * h {
        is_pseudo = true;
        for &g in &data {
            let v = f32::from(g) / 255.0;
            pixels.push(Rgba::new(v, v, v, 1.0));
        }
    } else if data.len() == w * h * 4 {
        for chunk in data.chunks_exact(4) {
            pixels.push(Rgba::new(
                f32::from(chunk[0]) / 255.0,
                f32::from(chunk[1]) / 255.0,
                f32::from(chunk[2]) / 255.0,
                f32::from(chunk[3]) / 255.0,
            ));
        }
    } else {
        return Err(SocialImageError::InvalidImage(
            "unexpected JPEG channel layout".to_owned(),
        ));
    }
    Ok(Canvas {
        width: w,
        height: h,
        pixels,
        has_alpha: false,
        is_pseudo,
    })
}

fn decode_gif_first_frame(bytes: &[u8]) -> Result<Canvas, SocialImageError> {
    let mut options = gif::DecodeOptions::new();
    options.set_color_output(gif::ColorOutput::RGBA);
    let mut decoder = options
        .read_info(Cursor::new(bytes))
        .map_err(|e| SocialImageError::InvalidImage(format!("GIF header error: {e}")))?;
    let (w, h) = validate_dimensions(u32::from(decoder.width()), u32::from(decoder.height()))?;
    let frame = decoder
        .read_next_frame()
        .map_err(|e| SocialImageError::InvalidImage(format!("GIF frame error: {e}")))?
        .ok_or_else(|| SocialImageError::InvalidImage("GIF contains no frames".to_owned()))?;

    let mut canvas = Canvas::new(w, h, Rgba::TRANSPARENT);
    canvas.is_pseudo = true;
    let fw = usize::from(frame.width);
    let fh = usize::from(frame.height);
    let left = usize::from(frame.left);
    let top = usize::from(frame.top);
    let mut any_transparent = fw != w || fh != h || left != 0 || top != 0;

    for fy in 0..fh {
        let dy = top + fy;
        if dy >= h {
            break;
        }
        for fx in 0..fw {
            let dx = left + fx;
            if dx >= w {
                break;
            }
            let idx = (fy * fw + fx) * 4;
            if idx + 3 >= frame.buffer.len() {
                return Err(SocialImageError::InvalidImage(
                    "truncated GIF frame".to_owned(),
                ));
            }
            let r = f32::from(frame.buffer[idx]) / 255.0;
            let g = f32::from(frame.buffer[idx + 1]) / 255.0;
            let b = f32::from(frame.buffer[idx + 2]) / 255.0;
            let a = f32::from(frame.buffer[idx + 3]) / 255.0;
            if a < 1.0 {
                any_transparent = true;
            }
            *canvas.get_mut(dx, dy) = Rgba::new(r, g, b, a);
        }
    }
    canvas.has_alpha = any_transparent;
    Ok(canvas)
}

fn decode_webp(bytes: &[u8]) -> Result<Canvas, SocialImageError> {
    let mut decoder = image_webp::WebPDecoder::new(Cursor::new(bytes))
        .map_err(|e| SocialImageError::InvalidImage(format!("WebP header error: {e}")))?;
    let (width, height) = decoder.dimensions();
    let (w, h) = validate_dimensions(width, height)?;
    let has_alpha = decoder.has_alpha();
    let buf_size = decoder
        .output_buffer_size()
        .ok_or_else(|| SocialImageError::InvalidImage("WebP buffer overflow".to_owned()))?;
    let mut buf = vec![0u8; buf_size];
    decoder
        .read_image(&mut buf)
        .map_err(|e| SocialImageError::InvalidImage(format!("WebP decode error: {e}")))?;

    let mut pixels = Vec::with_capacity(w * h);
    if has_alpha {
        for chunk in buf.chunks_exact(4).take(w * h) {
            pixels.push(Rgba::new(
                f32::from(chunk[0]) / 255.0,
                f32::from(chunk[1]) / 255.0,
                f32::from(chunk[2]) / 255.0,
                f32::from(chunk[3]) / 255.0,
            ));
        }
    } else {
        for chunk in buf.chunks_exact(3).take(w * h) {
            pixels.push(Rgba::new(
                f32::from(chunk[0]) / 255.0,
                f32::from(chunk[1]) / 255.0,
                f32::from(chunk[2]) / 255.0,
                1.0,
            ));
        }
    }
    if pixels.len() != w * h {
        return Err(SocialImageError::InvalidImage(
            "truncated WebP pixel data".to_owned(),
        ));
    }
    Ok(Canvas {
        width: w,
        height: h,
        pixels,
        has_alpha,
        is_pseudo: false,
    })
}

/// Checks whether `mogrify -format png` in ImageMagick 6 would write `canvas` as a
/// palette/grayscale `PseudoClass` PNG (`<= 256` unique colors or all grayscale), which
/// causes subsequent `resize` calls with `ResizeFilter::Auto` to select `Mitchell` instead
/// of `Lanczos`.
pub fn would_encode_as_pseudo_png(canvas: &Canvas) -> bool {
    if canvas.is_pseudo {
        return true;
    }
    let mut all_gray = true;
    // Simple open-addressed table of up to 256 unique packed RGB/RGBA colors.
    let mut seen = [u32::MAX; 512];
    let mut unique = 0usize;
    for p in &canvas.pixels {
        let r = (p.r * 255.0 + 0.5) as u8;
        let g = (p.g * 255.0 + 0.5) as u8;
        let b = (p.b * 255.0 + 0.5) as u8;
        let a = (p.a * 255.0 + 0.5) as u8;
        if r != g || g != b {
            all_gray = false;
        }
        if unique <= 256 {
            let key = u32::from_le_bytes([r, g, b, a]);
            let mut slot = ((key.wrapping_mul(0x9E37_79B9)) >> 23) as usize;
            loop {
                if seen[slot] == key {
                    break;
                }
                if seen[slot] == u32::MAX {
                    seen[slot] = key;
                    unique += 1;
                    break;
                }
                slot = (slot + 1) & 511;
            }
        }
        if !all_gray && unique > 256 {
            return false;
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::social_image::encode_png;

    #[test]
    fn roundtrips_encoded_png() {
        let mut src = Canvas::new(8, 6, Rgba::parse("#3b49df").unwrap());
        *src.get_mut(2, 3) = Rgba::WHITE;
        let bytes = encode_png(&src).unwrap();
        let decoded = decode_image(&bytes).unwrap();
        assert_eq!(decoded.width, 8);
        assert_eq!(decoded.height, 6);
        assert!(!decoded.has_alpha);
        assert_eq!(decoded.get(2, 3), Rgba::WHITE);
    }

    #[test]
    fn rejects_corrupt_or_empty_bytes() {
        assert!(decode_image(b"").is_err());
        assert!(decode_image(b"not an image").is_err());
        assert!(decode_image(b"\x89PNG\r\n\x1a\ntrailing garbage").is_err());
    }
}
