//! Straight-alpha RGBA canvas mirroring ImageMagick's `PixelPacket` math.
//!
//! ImageMagick 6 (Q16, non-HDRI) stores straight (non-premultiplied) channels and
//! composites with `MagickCompositeOver`. Channels here are `f32` in `0.0..=1.0`, which is
//! finer than Q16's 1/65535 steps, so intermediate rounding differences stay far below one
//! 8-bit output level.

/// An RGBA color with straight alpha, each channel in `0.0..=1.0`.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Rgba {
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
}

impl Rgba {
    pub const TRANSPARENT: Rgba = Rgba::new(0.0, 0.0, 0.0, 0.0);
    pub const WHITE: Rgba = Rgba::new(1.0, 1.0, 1.0, 1.0);
    pub const BLACK: Rgba = Rgba::new(0.0, 0.0, 0.0, 1.0);

    pub const fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        Rgba { r, g, b, a }
    }

    /// Parses the color strings the social card uses: `#rgb`, `#rrggbb`, `white`,
    /// `black`, and `none` (transparent, like ImageMagick's `none`).
    pub fn parse(value: &str) -> Option<Rgba> {
        let value = value.trim();
        match value.to_ascii_lowercase().as_str() {
            "white" => return Some(Rgba::WHITE),
            "black" => return Some(Rgba::BLACK),
            "none" | "transparent" => return Some(Rgba::TRANSPARENT),
            _ => {}
        }
        let hex = value.strip_prefix('#')?;
        if !hex.bytes().all(|b| b.is_ascii_hexdigit()) {
            return None;
        }
        let channel = |s: &str| u8::from_str_radix(s, 16).ok().map(|v| f32::from(v) / 255.0);
        match hex.len() {
            3 => {
                let expand = |i: usize| {
                    let c = &hex[i..=i];
                    channel(&format!("{c}{c}"))
                };
                Some(Rgba::new(expand(0)?, expand(1)?, expand(2)?, 1.0))
            }
            6 => Some(Rgba::new(
                channel(&hex[0..2])?,
                channel(&hex[2..4])?,
                channel(&hex[4..6])?,
                1.0,
            )),
            _ => None,
        }
    }

    pub fn with_alpha(self, a: f32) -> Self {
        Rgba { a, ..self }
    }
}

/// A `width x height` grid of straight-alpha pixels in row-major order.
#[derive(Clone, Debug)]
pub struct Canvas {
    pub width: usize,
    pub height: usize,
    pub pixels: Vec<Rgba>,
    /// Mirrors ImageMagick's `image->matte` flag (whether an alpha channel is active).
    pub has_alpha: bool,
    /// Mirrors ImageMagick's `image->storage_class == PseudoClass` (palette/grayscale-8).
    pub is_pseudo: bool,
}

impl Canvas {
    pub fn new(width: usize, height: usize, fill: Rgba) -> Self {
        Canvas {
            width,
            height,
            pixels: vec![fill; width * height],
            has_alpha: fill.a < 1.0,
            is_pseudo: false,
        }
    }

    #[inline]
    pub fn get(&self, x: usize, y: usize) -> Rgba {
        self.pixels[y * self.width + x]
    }

    #[inline]
    pub fn get_mut(&mut self, x: usize, y: usize) -> &mut Rgba {
        &mut self.pixels[y * self.width + x]
    }

    /// `MagickCompositeOver`: composites `color` scaled by `coverage` over pixel `(x, y)`.
    #[inline]
    pub fn blend(&mut self, x: usize, y: usize, color: Rgba, coverage: f32) {
        let sa = color.a * coverage;
        if sa <= 0.0 {
            return;
        }
        let dst = self.get_mut(x, y);
        *dst = over(color, sa, *dst);
    }

    /// `composite -compose Over -geometry +x+y`: places `src` with its top-left corner at
    /// `(x, y)`, clipping to the canvas.
    pub fn composite_over(&mut self, src: &Canvas, x: i64, y: i64) {
        for sy in 0..src.height {
            let dy = y + sy as i64;
            if dy < 0 || dy >= self.height as i64 {
                continue;
            }
            for sx in 0..src.width {
                let dx = x + sx as i64;
                if dx < 0 || dx >= self.width as i64 {
                    continue;
                }
                let s = src.get(sx, sy);
                if s.a <= 0.0 {
                    continue;
                }
                let d = self.get_mut(dx as usize, dy as usize);
                *d = over(s, s.a, *d);
            }
        }
    }

    /// `composite -alpha Set -compose DstOut mask self`: keeps this image where the
    /// same-sized `mask` is transparent (`Da' = Da * (1 - Sa)`), leaving colors untouched.
    pub fn dst_out(&mut self, mask: &Canvas) {
        self.has_alpha = true;
        let w = self.width.min(mask.width);
        let h = self.height.min(mask.height);
        for y in 0..h {
            for x in 0..w {
                let sa = mask.get(x, y).a;
                let d = self.get_mut(x, y);
                d.a *= 1.0 - sa;
            }
        }
    }

    /// `-alpha off -depth 8`: drops alpha and quantizes to 8-bit RGB.
    pub fn to_rgb8(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(self.width * self.height * 3);
        for p in &self.pixels {
            out.push(quantize8(p.r));
            out.push(quantize8(p.g));
            out.push(quantize8(p.b));
        }
        out
    }

    /// Quantizes to 8-bit straight RGBA (`width * height * 4` bytes).
    pub fn to_rgba8(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(self.width * self.height * 4);
        for p in &self.pixels {
            out.push(quantize8(p.r));
            out.push(quantize8(p.g));
            out.push(quantize8(p.b));
            out.push(quantize8(p.a));
        }
        out
    }
}

/// Straight-alpha source-over, matching ImageMagick's `MagickCompositeOver` /
/// `CompositeOver`: `gamma = Sa + Da - Sa*Da`, `C = (Sa*Sc + Da*(1-Sa)*Dc) / gamma`.
#[inline]
pub fn over(src: Rgba, sa: f32, dst: Rgba) -> Rgba {
    let da = dst.a;
    let gamma = sa + da - sa * da;
    if gamma <= f32::EPSILON {
        return Rgba::TRANSPARENT;
    }
    let inv = 1.0 / gamma;
    let dw = da * (1.0 - sa);
    Rgba {
        r: clamp01((sa * src.r + dw * dst.r) * inv),
        g: clamp01((sa * src.g + dw * dst.g) * inv),
        b: clamp01((sa * src.b + dw * dst.b) * inv),
        a: clamp01(gamma),
    }
}

#[inline]
pub fn clamp01(v: f32) -> f32 {
    v.clamp(0.0, 1.0)
}

/// `ScaleQuantumToChar`: rounds a `0.0..=1.0` channel to the nearest 8-bit level.
#[inline]
pub fn quantize8(v: f32) -> u8 {
    (clamp01(v) * 255.0 + 0.5) as u8
}

/// `ClampToQuantum` in Q16: rounds a `0.0..=1.0` channel to the nearest 16-bit quantum (`1/65535`).
#[inline]
pub fn quantize16(v: f64) -> f32 {
    let q = (v.clamp(0.0, 1.0) * 65535.0 + 0.5).floor();
    (q / 65535.0) as f32
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_supported_color_forms() {
        assert_eq!(Rgba::parse("white"), Some(Rgba::WHITE));
        assert_eq!(Rgba::parse("none"), Some(Rgba::TRANSPARENT));
        assert_eq!(Rgba::parse("#fc0"), Rgba::parse("#ffcc00"));
        let c = Rgba::parse("#3b49df").unwrap();
        assert_eq!(quantize8(c.r), 0x3b);
        assert_eq!(quantize8(c.g), 0x49);
        assert_eq!(quantize8(c.b), 0xdf);
        assert_eq!(Rgba::parse("#12345"), None);
        assert_eq!(Rgba::parse("red"), None);
        assert_eq!(Rgba::parse("#gggggg"), None);
    }

    #[test]
    fn over_matches_straight_alpha_math() {
        let out = over(Rgba::BLACK, 0.5, Rgba::WHITE);
        assert!((out.r - 0.5).abs() < 1e-6);
        assert!((out.a - 1.0).abs() < 1e-6);
        // Over a transparent destination the source color is kept as-is.
        let out = over(Rgba::new(0.2, 0.4, 0.6, 1.0), 0.25, Rgba::TRANSPARENT);
        assert!((out.g - 0.4).abs() < 1e-6);
        assert!((out.a - 0.25).abs() < 1e-6);
    }

    #[test]
    fn dst_out_cuts_where_mask_is_opaque() {
        let mut img = Canvas::new(2, 1, Rgba::BLACK);
        let mut mask = Canvas::new(2, 1, Rgba::TRANSPARENT);
        *mask.get_mut(1, 0) = Rgba::WHITE;
        img.dst_out(&mask);
        assert_eq!(img.get(0, 0).a, 1.0);
        assert_eq!(img.get(1, 0).a, 0.0);
    }
}
