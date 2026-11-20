//! Separable Gaussian blur (`-blur 0x48`) and image resampling (`-resize`) ported from
//! ImageMagick 6 (`magick/gem.c`, `magick/effect.c`, `magick/resize.c`, and
//! `magick/geometry.c`).

use super::canvas::{quantize16, Canvas, Rgba};

const MAGICK_EPSILON: f64 = 1.0e-12;
const QUANTUM_SCALE: f64 = 1.0 / 65535.0;
const KERNEL_RANK: isize = 3;

#[inline]
fn perceptible_reciprocal(x: f64) -> f64 {
    let sign = if x < 0.0 { -1.0 } else { 1.0 };
    if sign * x >= MAGICK_EPSILON {
        1.0 / x
    } else {
        sign / MAGICK_EPSILON
    }
}

/// `GetOptimalKernelWidth1D(0.0, sigma)` from ImageMagick 6 `magick/gem.c`.
pub fn optimal_kernel_width_1d(sigma: f64) -> usize {
    if sigma.abs() < MAGICK_EPSILON {
        return 3;
    }
    let s3 = KERNEL_RANK as f64 * sigma;
    let alpha = perceptible_reciprocal(2.0 * s3 * s3);
    let beta = perceptible_reciprocal((2.0 * std::f64::consts::PI).sqrt() * s3);
    let mut width: isize = 5;
    loop {
        let u = (width - 1) / 2;
        let mut normalize = 0.0;
        for v in -u..=u {
            for k in -1..=1 {
                let x = (KERNEL_RANK * v + k) as f64;
                normalize += (-x * x * alpha).exp() * beta;
            }
        }
        let mut value = 0.0;
        for k in -1..=1 {
            let x = (KERNEL_RANK * u + k) as f64;
            value += (-x * x * alpha).exp() * beta;
        }
        if value / normalize < QUANTUM_SCALE {
            break;
        }
        width += 2;
    }
    (width - 2).max(3) as usize
}

/// Builds the normalized 1D Gaussian blur kernel of `BlurImage` (`magick/effect.c`).
fn gaussian_blur_kernel_1d(sigma: f64) -> Vec<f64> {
    let width = optimal_kernel_width_1d(sigma);
    let half = (width as isize - 1) / 2;
    let s3 = KERNEL_RANK as f64 * sigma;
    let alpha = perceptible_reciprocal(2.0 * s3 * s3);
    let beta = perceptible_reciprocal((2.0 * std::f64::consts::PI).sqrt() * s3);
    let mut kernel = Vec::with_capacity(width);
    let mut normalize = 0.0;
    for i in -half..=half {
        let mut tap = 0.0;
        for k in -1..=1 {
            let x = (KERNEL_RANK * i + k) as f64;
            tap += (-x * x * alpha).exp() * beta;
        }
        kernel.push(tap);
        normalize += tap;
    }
    let inv = perceptible_reciprocal(normalize);
    for tap in &mut kernel {
        *tap *= inv;
    }
    kernel
}

/// `-blur 0x{sigma}`: separable 1D horizontal + vertical Gaussian convolution with
/// ImageMagick's default `EdgeVirtualPixelMethod` boundary clamping.
pub fn blur_gaussian(canvas: &Canvas, sigma: f64) -> Canvas {
    if canvas.width == 0 || canvas.height == 0 || sigma <= 0.0 {
        return canvas.clone();
    }
    let kernel = gaussian_blur_kernel_1d(sigma);
    let half = (kernel.len() as isize - 1) / 2;
    let w = canvas.width;
    let h = canvas.height;

    // Pass 1: horizontal convolution.
    let mut temp = vec![Rgba::WHITE; w * h];
    for y in 0..h {
        let row = &canvas.pixels[y * w..(y + 1) * w];
        let out_row = &mut temp[y * w..(y + 1) * w];
        for (x, dst) in out_row.iter_mut().enumerate() {
            let mut r = 0.0f64;
            let mut g = 0.0f64;
            let mut b = 0.0f64;
            for (k_idx, &weight) in kernel.iter().enumerate() {
                let offset = k_idx as isize - half;
                let sx = (x as isize + offset).clamp(0, w as isize - 1) as usize;
                let p = row[sx];
                r += weight * f64::from(p.r);
                g += weight * f64::from(p.g);
                b += weight * f64::from(p.b);
            }
            *dst = Rgba::new(quantize16(r), quantize16(g), quantize16(b), 1.0);
        }
    }

    // Pass 2: vertical convolution (iterate taps outside `x` for contiguous row SIMD access
    // while accumulating in the exact same `k_idx = 0..kernel.len()` floating-point order).
    let mut out = Canvas::new(w, h, Rgba::WHITE);
    let mut acc_r = vec![0.0f64; w];
    let mut acc_g = vec![0.0f64; w];
    let mut acc_b = vec![0.0f64; w];
    for y in 0..h {
        acc_r.fill(0.0);
        acc_g.fill(0.0);
        acc_b.fill(0.0);
        for (k_idx, &weight) in kernel.iter().enumerate() {
            let offset = k_idx as isize - half;
            let sy = (y as isize + offset).clamp(0, h as isize - 1) as usize;
            let src_row = &temp[sy * w..(sy + 1) * w];
            for x in 0..w {
                let p = src_row[x];
                acc_r[x] += weight * f64::from(p.r);
                acc_g[x] += weight * f64::from(p.g);
                acc_b[x] += weight * f64::from(p.b);
            }
        }
        let dst_row = &mut out.pixels[y * w..(y + 1) * w];
        for x in 0..w {
            dst_row[x] = Rgba::new(
                quantize16(acc_r[x]),
                quantize16(acc_g[x]),
                quantize16(acc_b[x]),
                1.0,
            );
        }
    }
    out
}

/// Resampling filters used by `ResizeImage` in ImageMagick 6 (`magick/resize.c`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ResizeFilter {
    /// ImageMagick's default (`UndefinedFilter`): selects `Mitchell` when the image has
    /// an alpha channel (`matte`), is paletted (`PseudoClass`), or is being upscaled
    /// (`x_factor * y_factor > 1.0`), and `Lanczos` when downscaling an opaque `DirectClass` image.
    Auto,
    /// `-filter Gaussian` (`support = 2.0`, `sigma = 0.5`).
    Gaussian,
    /// `MitchellFilter` (`B = 1/3, C = 1/3`, `support = 2.0`).
    Mitchell,
    /// `LanczosFilter` (`SincFast(x) * SincFast(x / 3)`, `support = 3.0`).
    Lanczos,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum ConcreteFilter {
    Gaussian,
    Mitchell,
    Lanczos,
}

impl ConcreteFilter {
    #[inline]
    fn support(self) -> f64 {
        match self {
            ConcreteFilter::Gaussian | ConcreteFilter::Mitchell => 2.0,
            ConcreteFilter::Lanczos => 3.0,
        }
    }

    #[inline]
    fn weight(self, x: f64) -> f64 {
        let x = x.abs();
        match self {
            ConcreteFilter::Gaussian => {
                // In IM6 `Gaussian(x)`: `exp(-2.0 * x * x) * sqrt(2.0 / PI)`.
                (-2.0 * x * x).exp() * (2.0 / std::f64::consts::PI).sqrt()
            }
            ConcreteFilter::Mitchell => {
                // B = 1/3, C = 1/3
                if x < 1.0 {
                    (7.0 * x * x * x - 12.0 * x * x + 16.0 / 3.0) / 6.0
                } else if x < 2.0 {
                    (-7.0 / 3.0 * x * x * x + 12.0 * x * x - 20.0 * x + 32.0 / 3.0) / 6.0
                } else {
                    0.0
                }
            }
            ConcreteFilter::Lanczos => {
                if x >= 3.0 {
                    0.0
                } else {
                    sinc_fast(x) * sinc_fast(x / 3.0)
                }
            }
        }
    }
}

/// Rational Chebyshev approximations from ImageMagick's `SincFast` (`magick/resize.c`).
#[inline]
#[allow(clippy::excessive_precision)]
fn sinc_fast(x: f64) -> f64 {
    let x = x.abs();
    if x > 4.0 {
        let alpha = std::f64::consts::PI * x;
        return alpha.sin() / alpha;
    }
    let xx = x * x;
    if x <= 1.0 {
        const C0: f64 = 0.173610016489197553621906385078711564924e2;
        const C1: f64 = -0.384186115075660162081071290162149315834e2;
        const C2: f64 = 0.393684603287860108352720146121813443561e2;
        const C3: f64 = -0.248947211682259168059030370205389323899e2;
        const C4: f64 = 0.107791837839662283066379987646635416692e2;
        const C5: f64 = -0.324874073895735800961260474028013982211e1;
        const C6: f64 = 0.628159869274628507262520265855729855607e0;
        const C7: f64 = -0.587232570556869618423121592833647021095e-1;
        const D0: f64 = 0.173610016489197553621906385078711564924e2;
        const D1: f64 = 0.713576535207228056544692498907909248894e1;
        const D2: f64 = 0.126992329897154614872335982765319215703e1;
        const D3: f64 = 0.119091337044903805706181621188735883235e0;
        let num =
            ((((((C7 * xx + C6) * xx + C5) * xx + C4) * xx + C3) * xx + C2) * xx + C1) * xx + C0;
        let den = (((xx * 0.487771512922031214262201476479837957363e-2 + D3) * xx + D2) * xx + D1)
            * xx
            + D0;
        num / den
    } else {
        let alpha = std::f64::consts::PI * x;
        alpha.sin() / alpha
    }
}

/// Precomputed tap list `(src_index, normalized_weight)` for each output coordinate.
fn build_contributions(
    src_len: usize,
    dst_len: usize,
    factor: f64,
    filter: ConcreteFilter,
) -> Vec<Vec<(usize, f64)>> {
    let mut scale = (1.0 / factor).max(1.0);
    let mut support = scale * filter.support();
    let is_point = support <= 0.5;
    if is_point {
        support = 0.5;
        scale = 1.0;
    }
    let inv_scale = 1.0 / scale;
    let mut out = Vec::with_capacity(dst_len);
    for dst_i in 0..dst_len {
        let bisect = (dst_i as f64 + 0.5) / factor + MAGICK_EPSILON;
        let start = (bisect - support + 0.5).max(0.0) as usize;
        let stop = (bisect + support + 0.5).min(src_len as f64) as usize;
        let mut taps = Vec::with_capacity(stop.saturating_sub(start).max(1));
        let mut density = 0.0;
        for src_i in start..stop {
            let w = if is_point {
                1.0
            } else {
                filter.weight(inv_scale * (src_i as f64 - bisect + 0.5))
            };
            taps.push((src_i, w));
            density += w;
        }
        if taps.is_empty() && src_len > 0 {
            let clamped = (bisect as usize).min(src_len - 1);
            taps.push((clamped, 1.0));
        } else if density != 0.0 && (density - 1.0).abs() > f64::EPSILON {
            let norm = perceptible_reciprocal(density);
            for (_, w) in &mut taps {
                *w *= norm;
            }
        }
        out.push(taps);
    }
    out
}

fn horizontal_filter(src: &Canvas, new_w: usize, factor: f64, filter: ConcreteFilter) -> Canvas {
    let h = src.height;
    let mut dst = Canvas::new(new_w, h, Rgba::TRANSPARENT);
    dst.has_alpha = src.has_alpha;
    dst.is_pseudo = src.is_pseudo;
    let contribs = build_contributions(src.width, new_w, factor, filter);
    for (x, taps) in contribs.iter().enumerate() {
        if !src.has_alpha {
            for y in 0..h {
                let row = &src.pixels[y * src.width..(y + 1) * src.width];
                let mut r = 0.0f64;
                let mut g = 0.0f64;
                let mut b = 0.0f64;
                for &(sx, w) in taps {
                    let p = row[sx];
                    r += w * f64::from(p.r);
                    g += w * f64::from(p.g);
                    b += w * f64::from(p.b);
                }
                *dst.get_mut(x, y) = Rgba::new(quantize16(r), quantize16(g), quantize16(b), 1.0);
            }
        } else {
            for y in 0..h {
                let row = &src.pixels[y * src.width..(y + 1) * src.width];
                let mut r = 0.0f64;
                let mut g = 0.0f64;
                let mut b = 0.0f64;
                let mut a = 0.0f64;
                let mut gamma = 0.0f64;
                for &(sx, w) in taps {
                    let p = row[sx];
                    let alpha = w * f64::from(p.a);
                    r += alpha * f64::from(p.r);
                    g += alpha * f64::from(p.g);
                    b += alpha * f64::from(p.b);
                    a += w * f64::from(p.a);
                    gamma += alpha;
                }
                gamma = perceptible_reciprocal(gamma);
                *dst.get_mut(x, y) = Rgba::new(
                    quantize16(gamma * r),
                    quantize16(gamma * g),
                    quantize16(gamma * b),
                    quantize16(a),
                );
            }
        }
    }
    dst
}

fn vertical_filter(src: &Canvas, new_h: usize, factor: f64, filter: ConcreteFilter) -> Canvas {
    let w = src.width;
    let mut dst = Canvas::new(w, new_h, Rgba::TRANSPARENT);
    dst.has_alpha = src.has_alpha;
    dst.is_pseudo = src.is_pseudo;
    let contribs = build_contributions(src.height, new_h, factor, filter);
    for (y, taps) in contribs.iter().enumerate() {
        if !src.has_alpha {
            for x in 0..w {
                let mut r = 0.0f64;
                let mut g = 0.0f64;
                let mut b = 0.0f64;
                for &(sy, weight) in taps {
                    let p = src.pixels[sy * w + x];
                    r += weight * f64::from(p.r);
                    g += weight * f64::from(p.g);
                    b += weight * f64::from(p.b);
                }
                *dst.get_mut(x, y) = Rgba::new(quantize16(r), quantize16(g), quantize16(b), 1.0);
            }
        } else {
            for x in 0..w {
                let mut r = 0.0f64;
                let mut g = 0.0f64;
                let mut b = 0.0f64;
                let mut a = 0.0f64;
                let mut gamma = 0.0f64;
                for &(sy, weight) in taps {
                    let p = src.pixels[sy * w + x];
                    let alpha = weight * f64::from(p.a);
                    r += alpha * f64::from(p.r);
                    g += alpha * f64::from(p.g);
                    b += alpha * f64::from(p.b);
                    a += weight * f64::from(p.a);
                    gamma += alpha;
                }
                gamma = perceptible_reciprocal(gamma);
                *dst.get_mut(x, y) = Rgba::new(
                    quantize16(gamma * r),
                    quantize16(gamma * g),
                    quantize16(gamma * b),
                    quantize16(a),
                );
            }
        }
    }
    dst
}

/// `ResizeImage` (`-resize {new_w}x{new_h}!`): resizes `canvas` to exact dimensions `(new_w, new_h)`.
pub fn resize(canvas: &Canvas, new_w: usize, new_h: usize, filter: ResizeFilter) -> Canvas {
    if canvas.width == 0 || canvas.height == 0 || new_w == 0 || new_h == 0 {
        return Canvas::new(new_w, new_h, Rgba::TRANSPARENT);
    }
    if canvas.width == new_w && canvas.height == new_h {
        return canvas.clone();
    }
    let x_factor = new_w as f64 / canvas.width as f64;
    let y_factor = new_h as f64 / canvas.height as f64;
    let concrete = match filter {
        ResizeFilter::Gaussian => ConcreteFilter::Gaussian,
        ResizeFilter::Mitchell => ConcreteFilter::Mitchell,
        ResizeFilter::Lanczos => ConcreteFilter::Lanczos,
        ResizeFilter::Auto => {
            if canvas.is_pseudo || canvas.has_alpha || (x_factor * y_factor) > 1.0 {
                ConcreteFilter::Mitchell
            } else {
                ConcreteFilter::Lanczos
            }
        }
    };
    if x_factor > y_factor {
        let mid = horizontal_filter(canvas, new_w, x_factor, concrete);
        vertical_filter(&mid, new_h, y_factor, concrete)
    } else {
        let mid = vertical_filter(canvas, new_h, y_factor, concrete);
        horizontal_filter(&mid, new_w, x_factor, concrete)
    }
}

/// `-resize x{target_h}` (`ParseMetaGeometry` with height-only geometry): preserves aspect ratio.
pub fn resize_to_height(canvas: &Canvas, target_h: usize) -> Canvas {
    if canvas.width == 0 || canvas.height == 0 || target_h == 0 {
        return Canvas::new(0, target_h, Rgba::TRANSPARENT);
    }
    let scale = target_h as f64 / canvas.height as f64;
    let new_w = (scale * canvas.width as f64 + 0.5).floor().max(1.0) as usize;
    resize(canvas, new_w, target_h, ResizeFilter::Auto)
}

/// `-resize {max_w}x{max_h}` (without `!`, `ParseMetaGeometry` aspect-preserving fit).
pub fn resize_fit(canvas: &Canvas, max_w: usize, max_h: usize) -> Canvas {
    if canvas.width == 0 || canvas.height == 0 || max_w == 0 || max_h == 0 {
        return Canvas::new(max_w, max_h, Rgba::TRANSPARENT);
    }
    let sx = max_w as f64 / canvas.width as f64;
    let sy = max_h as f64 / canvas.height as f64;
    let scale = sx.min(sy);
    let new_w = (scale * canvas.width as f64 + 0.5).floor().max(1.0) as usize;
    let new_h = (scale * canvas.height as f64 + 0.5).floor().max(1.0) as usize;
    resize(canvas, new_w, new_h, ResizeFilter::Auto)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::social_image::canvas::quantize8;

    #[test]
    fn optimal_kernel_width_matches_im6_for_sigma_48() {
        assert_eq!(optimal_kernel_width_1d(48.0), 341);
    }

    #[test]
    fn blur_and_resize_preserve_uniform_color() {
        let color = Rgba::parse("#3b49df").unwrap();
        let src = Canvas::new(40, 20, color);
        let blurred = blur_gaussian(&src, 8.0);
        let resized = resize(&blurred, 120, 60, ResizeFilter::Gaussian);
        assert_eq!(resized.width, 120);
        assert_eq!(resized.height, 60);
        let p = resized.get(60, 30);
        assert_eq!(quantize8(p.r), 0x3b);
        assert_eq!(quantize8(p.g), 0x49);
        assert_eq!(quantize8(p.b), 0xdf);
    }

    #[test]
    fn resize_to_height_scales_width_proportionally() {
        let src = Canvas::new(200, 100, Rgba::WHITE);
        let out = resize_to_height(&src, 30);
        assert_eq!(out.width, 60);
        assert_eq!(out.height, 30);
    }
}
