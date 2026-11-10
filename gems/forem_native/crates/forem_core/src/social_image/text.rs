//! TrueType font loading, hinting (`skrifa` bytecode interpreter with `SmoothMode::Light`),
//! analytic scanline rasterization (`ftgrays.c`), and text layout (`label:`, `caption:`,
//! and `-draw "text ..."`) ported from ImageMagick 6 (`magick/annotate.c`,
//! `coders/label.c`, and `coders/caption.c`).

use skrifa::instance::{LocationRef, Size};
use skrifa::outline::pen::OutlinePen;
use skrifa::outline::{DrawSettings, Engine, HintingInstance, HintingOptions, SmoothMode, Target};
use skrifa::raw::TableProvider;
use skrifa::{FontRef, GlyphId, MetadataProvider};

use super::canvas::{Canvas, Rgba};
use super::SocialImageError;

/// Parsed TrueType font bytes (`NotoSans-Bold.ttf` or `NotoSans-Medium.ttf`).
#[derive(Clone)]
pub struct Font<'a> {
    bytes: &'a [u8],
    units_per_em: u16,
    ascender: i16,
    descender: i16,
}

impl<'a> Font<'a> {
    pub fn from_bytes(bytes: &'a [u8]) -> Result<Self, SocialImageError> {
        let font = FontRef::new(bytes).map_err(|e| SocialImageError::InvalidFont(e.to_string()))?;
        let head = font
            .head()
            .map_err(|e| SocialImageError::InvalidFont(e.to_string()))?;
        let hhea = font
            .hhea()
            .map_err(|e| SocialImageError::InvalidFont(e.to_string()))?;
        Ok(Font {
            bytes,
            units_per_em: head.units_per_em(),
            ascender: hhea.ascender().to_i16(),
            descender: hhea.descender().to_i16(),
        })
    }

    fn font_ref(&self) -> FontRef<'a> {
        FontRef::new(self.bytes).expect("validated in Font::from_bytes")
    }
}

/// FreeType's `FT_MulFix(a, b)` in 16.16 fixed-point arithmetic.
#[inline]
fn ft_mul_fix(a: i64, b: i64) -> i64 {
    let sign = if (a ^ b) < 0 { -1 } else { 1 };
    let ua = a.unsigned_abs() as u128;
    let ub = b.unsigned_abs() as u128;
    let res = ((ua * ub) + 0x8000) >> 16;
    sign * (res as i64)
}

/// FreeType's `FT_DivFix(a, b)` in 16.16 fixed-point arithmetic.
#[inline]
fn ft_div_fix(a: i64, b: i64) -> i64 {
    if b == 0 {
        return 0;
    }
    let sign = if (a ^ b) < 0 { -1 } else { 1 };
    let ua = a.unsigned_abs() as u128;
    let ub = b.unsigned_abs() as u128;
    let q = ((ua << 16) + (ub >> 1)) / ub;
    sign * (q as i64)
}

/// Size-dependent font metrics matching FreeType's `face->size->metrics` at 72 DPI.
#[derive(Clone, Copy, Debug)]
struct SizeMetrics {
    y_scale: i64,
    ascent: f64,
    descent: f64,
    height: f64,
}

impl SizeMetrics {
    fn for_pointsize(font: &Font<'_>, pointsize: f64) -> Self {
        let char_height = (64.0 * pointsize) as i64;
        let y_scale = ft_div_fix(char_height, i64::from(font.units_per_em));
        let asc_26_6 = (ft_mul_fix(i64::from(font.ascender), y_scale) + 63) & !63;
        let desc_26_6 = ft_mul_fix(i64::from(font.descender), y_scale) & !63;
        let ascent = (asc_26_6 / 64) as f64;
        let descent = (desc_26_6 / 64) as f64;
        let height = (ascent - descent + 0.5).floor();
        SizeMetrics {
            y_scale,
            ascent,
            descent,
            height,
        }
    }
}

/// ImageMagick's `TypeMetric` (`magick/draw.h`) computed by `RenderFreetype` +
/// `AdjustTypeMetricBounds`.
#[derive(Clone, Copy, Debug)]
pub struct TypeMetrics {
    pub width: f64,
    pub height: f64,
    pub ascent: f64,
    pub descent: f64,
    pub bounds_x1: f64,
    pub bounds_y1: f64,
    pub bounds_x2: f64,
    pub bounds_y2: f64,
}

#[derive(Clone, Copy, Debug)]
enum PathVerb {
    MoveTo(f64, f64),
    LineTo(f64, f64),
    QuadTo(f64, f64, f64, f64),
    CurveTo(f64, f64, f64, f64, f64, f64),
    Close,
}

#[derive(Default)]
struct GlyphPen {
    verbs: Vec<PathVerb>,
}

impl OutlinePen for GlyphPen {
    fn move_to(&mut self, x: f32, y: f32) {
        self.verbs
            .push(PathVerb::MoveTo(f64::from(x), f64::from(y)));
    }

    fn line_to(&mut self, x: f32, y: f32) {
        self.verbs
            .push(PathVerb::LineTo(f64::from(x), f64::from(y)));
    }

    fn quad_to(&mut self, cx0: f32, cy0: f32, x: f32, y: f32) {
        self.verbs.push(PathVerb::QuadTo(
            f64::from(cx0),
            f64::from(cy0),
            f64::from(x),
            f64::from(y),
        ));
    }

    fn curve_to(&mut self, cx0: f32, cy0: f32, cx1: f32, cy1: f32, x: f32, y: f32) {
        self.verbs.push(PathVerb::CurveTo(
            f64::from(cx0),
            f64::from(cy0),
            f64::from(cx1),
            f64::from(cy1),
            f64::from(x),
            f64::from(y),
        ));
    }

    fn close(&mut self) {
        self.verbs.push(PathVerb::Close);
    }
}

struct ScaledGlyph {
    verbs: Vec<PathVerb>,
    /// Bounding box in 26.6 fixed point (`FT_Outline_Get_BBox`).
    bbox_26_6: Option<(i64, i64, i64, i64)>,
    /// Advance width in 26.6 fixed point (`glyph.image->advance.x >> 10`).
    advance_26_6: i64,
}

#[inline]
fn to_26_6(v: f64) -> i64 {
    (v * 64.0).round() as i64
}

fn quad_extremum(p0: f64, p1: f64, p2: f64) -> Option<f64> {
    let denom = p0 - 2.0 * p1 + p2;
    if denom.abs() < 1e-9 {
        return None;
    }
    let t = (p0 - p1) / denom;
    if (0.0..=1.0).contains(&t) {
        let u = 1.0 - t;
        Some(u * u * p0 + 2.0 * u * t * p1 + t * t * p2)
    } else {
        None
    }
}

/// Computes `FT_Outline_Get_BBox` in 26.6 fixed point for the glyph path.
fn compute_bbox_26_6(verbs: &[PathVerb]) -> Option<(i64, i64, i64, i64)> {
    if verbs.is_empty() {
        return None;
    }
    let mut min_x = f64::INFINITY;
    let mut min_y = f64::INFINITY;
    let mut max_x = f64::NEG_INFINITY;
    let mut max_y = f64::NEG_INFINITY;
    let mut cur = (0.0f64, 0.0f64);
    let mut any = false;
    let mut include = |x: f64, y: f64| {
        any = true;
        if x < min_x {
            min_x = x;
        }
        if x > max_x {
            max_x = x;
        }
        if y < min_y {
            min_y = y;
        }
        if y > max_y {
            max_y = y;
        }
    };

    for &verb in verbs {
        match verb {
            PathVerb::MoveTo(x, y) | PathVerb::LineTo(x, y) => {
                include(x, y);
                cur = (x, y);
            }
            PathVerb::QuadTo(cx, cy, x, y) => {
                include(x, y);
                if cx < cur.0.min(x) || cx > cur.0.max(x) {
                    if let Some(ex) = quad_extremum(cur.0, cx, x) {
                        include(ex, cur.1);
                    }
                }
                if cy < cur.1.min(y) || cy > cur.1.max(y) {
                    if let Some(ey) = quad_extremum(cur.1, cy, y) {
                        include(cur.0, ey);
                    }
                }
                cur = (x, y);
            }
            PathVerb::CurveTo(cx0, cy0, cx1, cy1, x, y) => {
                include(cx0, cy0);
                include(cx1, cy1);
                include(x, y);
                cur = (x, y);
            }
            PathVerb::Close => {}
        }
    }
    if !any {
        None
    } else {
        Some((
            to_26_6(min_x),
            to_26_6(min_y),
            to_26_6(max_x),
            to_26_6(max_y),
        ))
    }
}

fn load_scaled_glyph(
    font_ref: &FontRef<'_>,
    outlines: &skrifa::outline::OutlineGlyphCollection<'_>,
    hinting: &HintingInstance,
    size_metrics: SizeMetrics,
    gid: GlyphId,
) -> ScaledGlyph {
    let mut pen = GlyphPen::default();
    let mut advance_26_6 = None;
    if let Some(outline) = outlines.get(gid) {
        if let Ok(adj) = outline.draw(DrawSettings::hinted(hinting, false), &mut pen) {
            if let Some(adv) = adj.advance_width {
                advance_26_6 = Some(to_26_6(f64::from(adv)));
            }
        }
    }
    let advance_26_6 = advance_26_6.unwrap_or_else(|| {
        let unhinted = font_ref
            .hmtx()
            .ok()
            .and_then(|h| h.advance(gid))
            .unwrap_or(0);
        (ft_mul_fix(i64::from(unhinted), size_metrics.y_scale) + 32) & !63
    });
    let bbox_26_6 = compute_bbox_26_6(&pen.verbs);
    ScaledGlyph {
        verbs: pen.verbs,
        bbox_26_6,
        advance_26_6,
    }
}

struct PositionedGlyph {
    origin_x_26_6: i64,
    verbs: Vec<PathVerb>,
    bbox_26_6: Option<(i64, i64, i64, i64)>,
}

/// Runs `RenderFreetype` + `AdjustTypeMetricBounds` for a single line of text, returning
/// the `TypeMetrics` and (if `prepare_render` is true) the positioned glyph outlines.
fn layout_line(
    font: &Font<'_>,
    text: &str,
    pointsize: f64,
    prepare_render: bool,
) -> (TypeMetrics, Vec<PositionedGlyph>) {
    let font_ref = font.font_ref();
    let charmap = font_ref.charmap();
    let outlines = font_ref.outline_glyphs();
    let size = Size::new(pointsize as f32);
    let hinting_options = HintingOptions {
        engine: Engine::Interpreter,
        target: Target::Smooth {
            mode: SmoothMode::Light,
            symmetric_rendering: true,
            preserve_linear_metrics: false,
        },
    };
    let hinting = HintingInstance::new(&outlines, size, LocationRef::default(), hinting_options)
        .expect("HintingInstance creation succeeds for valid TrueType outlines");
    let sm = SizeMetrics::for_pointsize(font, pointsize);

    let mut bounds_x1_26_6: i64 = 0;
    let mut bounds_y1_26_6: i64 = (sm.descent * 64.0) as i64;
    let mut bounds_x2_26_6: i64 = ((sm.ascent + sm.descent) * 64.0) as i64;
    let mut bounds_y2_26_6: i64 = bounds_x2_26_6;

    let chars: Vec<char> = text.chars().collect();
    if !chars.is_empty() {
        // `RenderFreetype` (`magick/annotate.c`) initializes its local `bounds` to `{0, 0, 0, 0}`
        // and updates each coordinate on `i == 0` (or when extending min/max) whenever the glyph
        // bbox coordinate is non-zero.
        bounds_x1_26_6 = 0;
        bounds_y1_26_6 = 0;
        bounds_x2_26_6 = 0;
        bounds_y2_26_6 = 0;
    }
    let len = chars.len();
    let mut origin_x_26_6: i64 = 0;
    let mut positioned = Vec::with_capacity(if prepare_render { len } else { 0 });

    let space_gid = charmap.map(' ').unwrap_or(GlyphId::NOTDEF);

    for (i, &ch) in chars.iter().enumerate() {
        let mapped_gid = charmap.map(ch).unwrap_or(GlyphId::NOTDEF);
        // In IM6 `ComplexTextLayout` (without raqm), `x_advance` comes from `mapped_gid`
        // (even when `mapped_gid == 0`), while `RenderFreetype` substitutes `' '` if
        // `glyph.id == 0`.
        let render_gid = if mapped_gid == GlyphId::NOTDEF {
            space_gid
        } else {
            mapped_gid
        };
        let glyph = load_scaled_glyph(&font_ref, &outlines, &hinting, sm, render_gid);
        let x_advance_26_6 = if mapped_gid == render_gid {
            glyph.advance_26_6
        } else {
            load_scaled_glyph(&font_ref, &outlines, &hinting, sm, mapped_gid).advance_26_6
        };

        let glyph_origin_x = origin_x_26_6;
        let mut unshifted_xmax_26_6: i64 = 0;
        if let Some((xmin, ymin, xmax, ymax)) = glyph.bbox_26_6 {
            unshifted_xmax_26_6 = xmax;
            if (i == 0 || xmin < bounds_x1_26_6) && xmin != 0 {
                bounds_x1_26_6 = xmin;
            }
            if (i == 0 || ymin < bounds_y1_26_6) && ymin != 0 {
                bounds_y1_26_6 = ymin;
            }
            if (i == 0 || xmax > bounds_x2_26_6) && xmax != 0 {
                bounds_x2_26_6 = xmax;
            }
            if (i == 0 || ymax > bounds_y2_26_6) && ymax != 0 {
                bounds_y2_26_6 = ymax;
            }
        }

        if i + 1 == len {
            origin_x_26_6 += x_advance_26_6.max(unshifted_xmax_26_6);
        } else {
            origin_x_26_6 += x_advance_26_6;
        }

        if prepare_render {
            positioned.push(PositionedGlyph {
                origin_x_26_6: glyph_origin_x,
                verbs: glyph.verbs,
                bbox_26_6: glyph.bbox_26_6,
            });
        }
    }

    let mut bounds_x1 = bounds_x1_26_6 as f64 / 64.0;
    let bounds_y1 = bounds_y1_26_6 as f64 / 64.0;
    let bounds_x2 = bounds_x2_26_6 as f64 / 64.0;
    let bounds_y2 = bounds_y2_26_6 as f64 / 64.0;
    let mut width = origin_x_26_6 as f64 / 64.0;

    // `AdjustTypeMetricBounds` (`magick/annotate.c`):
    if bounds_x1 < 0.0 {
        let x1 = (-bounds_x1 + 0.5).ceil();
        width += 2.0 * x1;
        bounds_x1 = x1;
    } else {
        bounds_x1 = 0.0;
    }

    let metrics = TypeMetrics {
        width,
        height: sm.height,
        ascent: sm.ascent,
        descent: sm.descent,
        bounds_x1,
        bounds_y1,
        bounds_x2,
        bounds_y2,
    };
    (metrics, positioned)
}

/// Computes ImageMagick's `GetTypeMetrics` for `text` at `pointsize`.
pub fn get_type_metrics(font: &Font<'_>, text: &str, pointsize: f64) -> TypeMetrics {
    layout_line(font, text, pointsize, false).0
}

fn flatten_quad(p0: (f64, f64), p1: (f64, f64), p2: (f64, f64), out: &mut Vec<(f64, f64)>) {
    let dx = (p0.0 - 2.0 * p1.0 + p2.0).abs();
    let dy = (p0.1 - 2.0 * p1.1 + p2.1).abs();
    if dx <= 0.125 && dy <= 0.125 {
        out.push(p2);
        return;
    }
    let p01 = ((p0.0 + p1.0) * 0.5, (p0.1 + p1.1) * 0.5);
    let p12 = ((p1.0 + p2.0) * 0.5, (p1.1 + p2.1) * 0.5);
    let mid = ((p01.0 + p12.0) * 0.5, (p01.1 + p12.1) * 0.5);
    flatten_quad(p0, p01, mid, out);
    flatten_quad(mid, p12, p2, out);
}

fn flatten_cubic(
    p0: (f64, f64),
    p1: (f64, f64),
    p2: (f64, f64),
    p3: (f64, f64),
    out: &mut Vec<(f64, f64)>,
) {
    let dx = (p0.0 - 3.0 * p1.0 + 3.0 * p2.0 - p3.0).abs();
    let dy = (p0.1 - 3.0 * p1.1 + 3.0 * p2.1 - p3.1).abs();
    if dx <= 0.125 && dy <= 0.125 {
        out.push(p3);
        return;
    }
    let p01 = ((p0.0 + p1.0) * 0.5, (p0.1 + p1.1) * 0.5);
    let p12 = ((p1.0 + p2.0) * 0.5, (p1.1 + p2.1) * 0.5);
    let p23 = ((p2.0 + p3.0) * 0.5, (p2.1 + p3.1) * 0.5);
    let p012 = ((p01.0 + p12.0) * 0.5, (p01.1 + p12.1) * 0.5);
    let p123 = ((p12.0 + p23.0) * 0.5, (p12.1 + p23.1) * 0.5);
    let mid = ((p012.0 + p123.0) * 0.5, (p012.1 + p123.1) * 0.5);
    flatten_cubic(p0, p01, p012, mid, out);
    flatten_cubic(mid, p123, p23, p3, out);
}

/// Accumulates a segment `(x0, y0) -> (x1, y1)` that lies within a single scanline row `ry`
/// (`y0, y1 in [ry, ry + 1]`) into the scanline's `area` and `cover` buffers.
fn accumulate_scanline_segment(
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,
    width: usize,
    area: &mut [f64],
    cover: &mut [f64],
) {
    let dy = y1 - y0;
    if dy.abs() < 1e-12 {
        return;
    }
    let x0 = x0.clamp(0.0, width as f64);
    let x1 = x1.clamp(0.0, width as f64);
    let x_min = x0.min(x1);
    let x_max = x0.max(x1);
    let first_cut = x_min.floor() as isize + 1;
    let last_cut = x_max.ceil() as isize - 1;

    if first_cut > last_cut {
        let mid = (x0 + x1) * 0.5;
        let cell = (mid.floor() as isize).clamp(0, width as isize - 1) as usize;
        if cell < width {
            let xm = mid - cell as f64;
            area[cell] += dy * (1.0 - xm);
            cover[cell + 1] += dy;
        }
        return;
    }

    let dx = x1 - x0;
    let mut cur_x = x0;
    let mut cur_y = y0;
    let mut visit_cut = |next_x: f64| {
        let t = (next_x - x0) / dx;
        let next_y = y0 + t * dy;
        let sdy = next_y - cur_y;
        let mid = (cur_x + next_x) * 0.5;
        let cell = (mid.floor() as isize).clamp(0, width as isize - 1) as usize;
        if cell < width {
            let xm = mid - cell as f64;
            area[cell] += sdy * (1.0 - xm);
            cover[cell + 1] += sdy;
        }
        cur_x = next_x;
        cur_y = next_y;
    };

    if x1 >= x0 {
        for k in first_cut..=last_cut {
            visit_cut(k as f64);
        }
    } else {
        for k in (first_cut..=last_cut).rev() {
            visit_cut(k as f64);
        }
    }
    let sdy = y1 - cur_y;
    let mid = (cur_x + x1) * 0.5;
    let cell = (mid.floor() as isize).clamp(0, width as isize - 1) as usize;
    if cell < width {
        let xm = mid - cell as f64;
        area[cell] += sdy * (1.0 - xm);
        cover[cell + 1] += sdy;
    }
}

/// Rasterizes a positioned glyph using FreeType's analytic coverage algorithm (`ftgrays.c`)
/// and blends it onto `canvas` at baseline `offset` (`RenderFreetype` in `magick/annotate.c`).
fn rasterize_glyph_onto(
    canvas: &mut Canvas,
    glyph: &PositionedGlyph,
    offset_x: f64,
    offset_y: f64,
    color: Rgba,
) {
    let Some((xmin, ymin, xmax, ymax)) = glyph.bbox_26_6 else {
        return;
    };
    let shift_x = glyph.origin_x_26_6;
    let cbox_xmin = (xmin + shift_x) & !63;
    let cbox_ymin = ymin & !63;
    let cbox_xmax = (xmax + shift_x + 63) & !63;
    let cbox_ymax = (ymax + 63) & !63;

    let bmp_left = cbox_xmin >> 6;
    let bmp_top = cbox_ymax >> 6;
    let bmp_w = ((cbox_xmax - cbox_xmin) >> 6).max(0) as usize;
    let bmp_h = ((cbox_ymax - cbox_ymin) >> 6).max(0) as usize;
    if bmp_w == 0 || bmp_h == 0 {
        return;
    }

    // Flatten contours in bitmap local coordinates:
    // `bx = x_px - bmp_left`, `by = bmp_top - y_px`.
    let shift_px = shift_x as f64 / 64.0;
    let to_bmp = |x: f64, y: f64| (x + shift_px - bmp_left as f64, bmp_top as f64 - y);

    let mut area = vec![0.0f64; bmp_w * bmp_h];
    let mut cover = vec![0.0f64; (bmp_w + 1) * bmp_h];

    let mut add_edge = |p0: (f64, f64), p1: (f64, f64)| {
        let (mut x0, mut y0) = p0;
        let (mut x1, mut y1) = p1;
        if (y1 - y0).abs() < 1e-12 {
            return;
        }
        let dir = if y1 > y0 { 1.0 } else { -1.0 };
        if dir < 0.0 {
            std::mem::swap(&mut x0, &mut x1);
            std::mem::swap(&mut y0, &mut y1);
        }
        let y_start = y0.clamp(0.0, bmp_h as f64);
        let y_end = y1.clamp(0.0, bmp_h as f64);
        if y_end <= y_start {
            return;
        }
        let inv_dy = 1.0 / (y1 - y0);
        let dx = x1 - x0;
        let row_start = (y_start.floor() as usize).min(bmp_h - 1);
        let row_end = ((y_end.ceil() as usize).saturating_sub(1)).min(bmp_h - 1);
        for row in row_start..=row_end {
            let ry0 = y_start.max(row as f64);
            let ry1 = y_end.min((row + 1) as f64);
            if ry1 <= ry0 {
                continue;
            }
            let rx0 = x0 + (ry0 - y0) * inv_dy * dx;
            let rx1 = x0 + (ry1 - y0) * inv_dy * dx;
            let row_area = &mut area[row * bmp_w..(row + 1) * bmp_w];
            let row_cover = &mut cover[row * (bmp_w + 1)..(row + 1) * (bmp_w + 1)];
            if dir > 0.0 {
                accumulate_scanline_segment(rx0, ry0, rx1, ry1, bmp_w, row_area, row_cover);
            } else {
                accumulate_scanline_segment(rx1, ry1, rx0, ry0, bmp_w, row_area, row_cover);
            }
        }
    };

    let mut contour: Vec<(f64, f64)> = Vec::new();
    let mut flush_contour = |pts: &mut Vec<(f64, f64)>| {
        if pts.len() >= 2 {
            for i in 0..pts.len() {
                let a = pts[i];
                let b = pts[(i + 1) % pts.len()];
                add_edge(a, b);
            }
        }
        pts.clear();
    };

    for &verb in &glyph.verbs {
        match verb {
            PathVerb::MoveTo(x, y) => {
                flush_contour(&mut contour);
                contour.push(to_bmp(x, y));
            }
            PathVerb::LineTo(x, y) => {
                contour.push(to_bmp(x, y));
            }
            PathVerb::QuadTo(cx, cy, x, y) => {
                if let Some(&last) = contour.last() {
                    flatten_quad(last, to_bmp(cx, cy), to_bmp(x, y), &mut contour);
                }
            }
            PathVerb::CurveTo(cx0, cy0, cx1, cy1, x, y) => {
                if let Some(&last) = contour.last() {
                    flatten_cubic(
                        last,
                        to_bmp(cx0, cy0),
                        to_bmp(cx1, cy1),
                        to_bmp(x, y),
                        &mut contour,
                    );
                }
            }
            PathVerb::Close => {
                flush_contour(&mut contour);
            }
        }
    }
    flush_contour(&mut contour);

    let point_x = offset_x + bmp_left as f64;
    let point_y = offset_y - bmp_top as f64;

    for by in 0..bmp_h {
        let y_offset = (point_y + by as f64 - 0.5).ceil() as i64;
        if y_offset < 0 || y_offset >= canvas.height as i64 {
            continue;
        }
        let row_area = &area[by * bmp_w..(by + 1) * bmp_w];
        let row_cover = &cover[by * (bmp_w + 1)..(by + 1) * (bmp_w + 1)];
        let mut running = 0.0f64;
        for bx in 0..bmp_w {
            running += row_cover[bx];
            let val = (running + row_area[bx]).abs();
            // Match FreeType `ftgrays.c` 256-level integer coverage clamped to 255.
            let alpha_u8 = ((val * 256.0).floor() as i32).min(255);
            if alpha_u8 <= 0 {
                continue;
            }
            let x_offset = (point_x + bx as f64 - 0.5).ceil() as i64;
            if x_offset < 0 || x_offset >= canvas.width as i64 {
                continue;
            }
            let coverage = alpha_u8 as f32 / 255.0;
            canvas.blend(x_offset as usize, y_offset as usize, color, coverage);
        }
    }
}

fn normalize_label_or_caption_text(text: &str) -> &str {
    if text.trim().is_empty() {
        "\u{00A0}"
    } else {
        text
    }
}

/// Renders `label:{text}` (`coders/label.c` + `AnnotateImage` with `UndefinedGravity` on a
/// transparent background).
pub fn render_label(font: &Font<'_>, text: &str, pointsize: f64, color: Rgba) -> Canvas {
    let content = normalize_label_or_caption_text(text);
    let (metrics, glyphs) = layout_line(font, content, pointsize, true);
    // `coders/label.c`: `draw_info->stroke_width = 1.0`.
    let cols = (metrics.width + 1.0 + 0.5).floor().max(1.0) as usize;
    let rows = (metrics.height + 1.0 + 0.5).floor().max(1.0) as usize;
    let mut canvas = Canvas::new(cols, rows, Rgba::TRANSPARENT);
    let offset_x = metrics.bounds_x1;
    let offset_y = metrics.ascent.max(metrics.bounds_y2);
    for g in &glyphs {
        rasterize_glyph_onto(&mut canvas, g, offset_x, offset_y, color);
    }
    canvas
}

#[inline]
fn is_breakable_utf_space(ch: char) -> bool {
    // Matches `IsUTFSpace(code) && !IsNonBreakingUTFSpace(code)` in `magick/token.c`:
    // U+00A0, U+2007, U+202F, U+FEFF are non-breaking; standard whitespace is breakable.
    if matches!(ch, '\u{00A0}' | '\u{2007}' | '\u{202F}' | '\u{FEFF}') {
        return false;
    }
    ch.is_whitespace()
}

/// Word-wraps `text` into lines that fit within `max_width` pixels, matching
/// `FormatMagickCaption` (`magick/annotate.c` with `split = true`).
pub fn format_magick_caption(
    font: &Font<'_>,
    text: &str,
    pointsize: f64,
    max_width: usize,
) -> Vec<String> {
    let content = normalize_label_or_caption_text(text);
    let chars: Vec<char> = content.chars().collect();
    if chars.is_empty() {
        return vec![String::new()];
    }

    let font_ref = FontRef::from_index(font.bytes, 0).expect("Font bytes already validated");
    let charmap = font_ref.charmap();
    let outlines = font_ref.outline_glyphs();
    let size = Size::new(pointsize as f32);
    let hinting_options = HintingOptions {
        engine: Engine::Interpreter,
        target: Target::Smooth {
            mode: SmoothMode::Light,
            symmetric_rendering: true,
            preserve_linear_metrics: false,
        },
    };
    let hinting = HintingInstance::new(&outlines, size, LocationRef::default(), hinting_options)
        .expect("HintingInstance creation succeeds for valid TrueType outlines");
    let sm = SizeMetrics::for_pointsize(font, pointsize);
    let space_gid = charmap.map(' ').unwrap_or(GlyphId::NOTDEF);

    // Precompute `(x_advance_26_6, Option<xmin_26_6>, unshifted_xmax_26_6)` for each char in `chars`.
    let char_metrics: Vec<(i64, Option<i64>, i64)> = chars
        .iter()
        .map(|&ch| {
            let mapped_gid = charmap.map(ch).unwrap_or(GlyphId::NOTDEF);
            let render_gid = if mapped_gid == GlyphId::NOTDEF {
                space_gid
            } else {
                mapped_gid
            };
            let glyph = load_scaled_glyph(&font_ref, &outlines, &hinting, sm, render_gid);
            let x_advance_26_6 = if mapped_gid == render_gid {
                glyph.advance_26_6
            } else {
                load_scaled_glyph(&font_ref, &outlines, &hinting, sm, mapped_gid).advance_26_6
            };
            let (xmin, xmax) = match glyph.bbox_26_6 {
                Some((x1, _, x2, _)) => (Some(x1), x2),
                None => (None, 0),
            };
            (x_advance_26_6, xmin, xmax)
        })
        .collect();

    let mut lines: Vec<String> = Vec::new();
    let mut current_line = String::new();
    let mut line_char_len: usize = 0;
    let mut prefix_advance_26_6: i64 = 0;
    let mut line_bounds_x1_26_6: i64 = 0;
    // Index in `chars` of the most recent breakable space on the current line.
    let mut last_space_idx: Option<usize> = None;
    let mut i = 0usize;

    while i < chars.len() {
        let ch = chars[i];
        if is_breakable_utf_space(ch) {
            last_space_idx = Some(i);
        }
        if ch == '\n' {
            lines.push(std::mem::take(&mut current_line));
            line_char_len = 0;
            prefix_advance_26_6 = 0;
            line_bounds_x1_26_6 = 0;
            last_space_idx = None;
            i += 1;
            continue;
        }
        current_line.push(ch);
        let (adv, maybe_xmin, xmax) = char_metrics[i];
        let prev_bounds_x1_26_6 = line_bounds_x1_26_6;
        if let Some(xmin) = maybe_xmin {
            if (line_char_len == 0 || xmin < line_bounds_x1_26_6) && xmin != 0 {
                line_bounds_x1_26_6 = xmin;
            }
        }
        line_char_len += 1;
        let origin_x_26_6 = prefix_advance_26_6 + adv.max(xmax);
        let mut width = origin_x_26_6 as f64 / 64.0;
        let bounds_x1 = line_bounds_x1_26_6 as f64 / 64.0;
        if bounds_x1 < 0.0 {
            let x1 = (-bounds_x1 + 0.5).ceil();
            width += 2.0 * x1;
        }
        let w = (width + 1.0 + 0.5).floor() as usize;
        if w <= max_width {
            prefix_advance_26_6 += adv;
            i += 1;
            continue;
        }
        if let Some(space_i) = last_space_idx {
            // Break at `space_i`: keep everything on the current line before `space_i`,
            // and resume right after `space_i`!
            let drop_count = (i - space_i) + 1;
            let keep_count = line_char_len.saturating_sub(drop_count);
            let wrapped: String = current_line.chars().take(keep_count).collect();
            lines.push(wrapped);
            current_line.clear();
            line_char_len = 0;
            prefix_advance_26_6 = 0;
            line_bounds_x1_26_6 = 0;
            last_space_idx = None;
            i = space_i + 1;
        } else {
            // `split == true` in `caption.c` when `image->rows == 0`: split before `chars[i]`
            // (as long as the line already has at least one earlier character so we always make progress).
            let popped = current_line.pop();
            if current_line.is_empty() {
                if let Some(c) = popped {
                    current_line.push(c);
                }
                prefix_advance_26_6 += adv;
                i += 1;
            } else {
                let _ = prev_bounds_x1_26_6;
                lines.push(std::mem::take(&mut current_line));
                line_char_len = 0;
                prefix_advance_26_6 = 0;
                line_bounds_x1_26_6 = 0;
                last_space_idx = None;
                // Re-process `chars[i]` as the first character of the next line.
            }
        }
    }
    lines.push(current_line);
    lines
}

/// Renders `caption:{text}` (`coders/caption.c` + `AnnotateImage` with `WestGravity` and
/// `interline_spacing = -4.0` on a transparent background of width `width`).
pub fn render_caption(
    font: &Font<'_>,
    text: &str,
    pointsize: f64,
    color: Rgba,
    width: usize,
    interline_spacing: f64,
) -> Canvas {
    let lines = format_magick_caption(font, text, pointsize, width);
    let num_lines = lines.len().max(1);
    let sm = SizeMetrics::for_pointsize(font, pointsize);
    // `coders/caption.c`: `rows = (size_t) ((i + 1) * (metrics.ascent - metrics.descent +
    // draw_info->interline_spacing + draw_info->stroke_width) + 0.5)`.
    let line_box = sm.ascent - sm.descent + interline_spacing + 1.0;
    let rows = ((num_lines as f64) * line_box + 0.5).floor().max(1.0) as usize;
    let mut canvas = Canvas::new(width.max(1), rows, Rgba::TRANSPARENT);

    // `AnnotateImage` (`magick/annotate.c`) with `WestGravity`:
    // `height = (size_t) (metrics.ascent - metrics.descent + 0.5)` + `(ssize_t) floor(interline_spacing + 0.5)`.
    let base_height = (sm.ascent - sm.descent + 0.5).floor();
    let step_height = base_height + (interline_spacing + 0.5).floor();

    for (i, line) in lines.iter().enumerate() {
        if line.is_empty() {
            continue;
        }
        let (metrics, glyphs) = layout_line(font, line, pointsize, true);
        let offset_x = metrics.bounds_x1;
        let offset_y = (rows as f64) / 2.0
            + (i as f64) * step_height
            + (metrics.ascent + metrics.descent - ((num_lines - 1) as f64) * step_height) / 2.0;
        for g in &glyphs {
            rasterize_glyph_onto(&mut canvas, g, offset_x, offset_y, color);
        }
    }
    canvas
}

/// Steps `pointsize` down by `2.0` from `max_pointsize` to `min_pointsize` until `render_label`
/// fits within `max_width` (`render_text_to_fit` in `GenerateSocialImageMagickally`).
pub fn render_label_to_fit(
    font: &Font<'_>,
    text: &str,
    max_pointsize: f64,
    min_pointsize: f64,
    color: Rgba,
    max_width: usize,
) -> Canvas {
    let content = normalize_label_or_caption_text(text);
    let mut pointsize = max_pointsize;
    loop {
        if pointsize <= min_pointsize {
            return render_label(font, content, pointsize, color);
        }
        let metrics = get_type_metrics(font, content, pointsize);
        let cols = (metrics.width + 1.0 + 0.5).floor().max(1.0) as usize;
        if cols <= max_width {
            return render_label(font, content, pointsize, color);
        }
        pointsize -= 2.0;
    }
}

/// Steps `pointsize` down by `2.0` from `start_pointsize` to `min_pointsize` until
/// `render_caption` has `height <= max_height` (`render_quote` / `render_bio`).
#[allow(clippy::too_many_arguments)]
pub fn render_caption_to_fit(
    font: &Font<'_>,
    text: &str,
    start_pointsize: f64,
    min_pointsize: f64,
    color: Rgba,
    width: usize,
    max_height: usize,
    interline_spacing: f64,
) -> Canvas {
    let mut pointsize = start_pointsize;
    loop {
        let canvas = render_caption(font, text, pointsize, color, width, interline_spacing);
        if canvas.height <= max_height || pointsize <= min_pointsize {
            return canvas;
        }
        pointsize -= 2.0;
    }
}

/// Draws text directly onto `canvas` with `NorthWestGravity` (`-gravity NorthWest -draw 'text x,y "..."'`).
pub fn draw_text_northwest(
    canvas: &mut Canvas,
    font: &Font<'_>,
    text: &str,
    x: f64,
    y: f64,
    pointsize: f64,
    color: Rgba,
) {
    let (metrics, glyphs) = layout_line(font, text, pointsize, true);
    let offset_x = x;
    // Matches Debian/Ubuntu ImageMagick 6 (`6.9.10` / Heroku production) `NorthWestGravity`
    // baseline offset (`translate.y + metrics.ascent`), placing the opening quote mark (`body_top - 30`)
    // cleanly inside the window body (`y = 149..185`) below the `bar_y = 126` title bar.
    let offset_y = y + metrics.ascent;
    for g in &glyphs {
        rasterize_glyph_onto(canvas, g, offset_x, offset_y, color);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn bold_font_bytes() -> Vec<u8> {
        let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../../..");
        std::fs::read(root.join("app/assets/fonts/NotoSans-Bold.ttf")).unwrap()
    }

    fn medium_font_bytes() -> Vec<u8> {
        let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../../..");
        std::fs::read(root.join("app/assets/fonts/NotoSans-Medium.ttf")).unwrap()
    }

    #[test]
    fn renders_labels_and_captions_with_expected_dimensions() {
        let bold_bytes = bold_font_bytes();
        let bold = Font::from_bytes(&bold_bytes).unwrap();
        let medium_bytes = medium_font_bytes();
        let medium = Font::from_bytes(&medium_bytes).unwrap();

        let label = render_label(&bold, "Jane Doe", 28.0, Rgba::BLACK);
        assert_eq!((label.width, label.height), (130, 40));

        let blank = render_label(&bold, "   ", 28.0, Rgba::BLACK);
        assert!(blank.width >= 1 && blank.height >= 1);

        let caption = render_caption(
            &bold,
            "Why rewriting ImageMagick pipelines in Rust eliminates Sidekiq memory spikes.",
            44.0,
            Rgba::BLACK,
            806,
            -4.0,
        );
        assert_eq!(caption.width, 806);
        assert!(caption.height > 80);

        let fitted = render_label_to_fit(
            &medium,
            "Austin, TX  ·  samrivera.dev  ·  Joined Oct 2026  ·  very-long-domain-name-example.dev",
            22.0,
            16.0,
            Rgba::BLACK,
            400,
        );
        assert!(fitted.height <= 32);
    }
}
