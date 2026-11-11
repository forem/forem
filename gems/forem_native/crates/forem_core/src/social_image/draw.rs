//! Vector shape rasterization ported from ImageMagick 6 `magick/draw.c`.
//!
//! ImageMagick does not compute area coverage. It traces each primitive into short
//! polyline segments (`TraceEllipse`, `TraceRoundRectangle`, ...), splits the path into
//! y-monotonic edges (`ConvertPathToPolygon`), and then derives an opacity for every pixel
//! *center* (integer coordinates) from its distance to those segments
//! (`GetOpacityPixel`):
//!
//! * fill: `1.0` inside (even-odd or non-zero winding), otherwise `(1 - d)^2` for `d < 1`
//! * thin strokes (`stroke_width / 2 <= 1`): `1.0` for `d <= mid - 0.25`, otherwise
//!   `(d - mid - 0.75)^2` up to `mid + 0.75`
//! * wide strokes: a stroke outline polygon (`TraceStrokePolygon`) filled with the rules above
//!
//! Segment and edge culling (`mid + 0.5` padding) is reproduced too, since it truncates the
//! anti-aliasing fringe around curves exactly like ImageMagick does.

use super::canvas::{Canvas, Rgba};

const MAGICK_EPSILON: f64 = 1.0e-12;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub const fn new(x: f64, y: f64) -> Self {
        Point { x, y }
    }
}

/// One traced primitive: the polyline ImageMagick builds before rasterizing.
#[derive(Clone, Debug)]
pub struct Subpath {
    pub points: Vec<Point>,
    pub closed: bool,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum FillRule {
    EvenOdd,
    NonZero,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum LineCap {
    Butt,
    Round,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum LineJoin {
    Miter,
    Round,
}

#[derive(Clone, Copy, Debug)]
pub struct StrokeStyle {
    pub width: f64,
    pub cap: LineCap,
    pub join: LineJoin,
}

impl StrokeStyle {
    pub const fn new(width: f64, cap: LineCap, join: LineJoin) -> Self {
        StrokeStyle { width, cap, join }
    }

    pub const fn butt_miter(width: f64) -> Self {
        StrokeStyle {
            width,
            cap: LineCap::Butt,
            join: LineJoin::Miter,
        }
    }

    pub const fn round(width: f64) -> Self {
        StrokeStyle {
            width,
            cap: LineCap::Round,
            join: LineJoin::Round,
        }
    }
}

/// `TraceEllipse`: "ellipses are just short segmented polys".
pub fn trace_ellipse(center: Point, radii: Point, arc_start: f64, arc_end: f64) -> Vec<Point> {
    let mut points = Vec::new();
    if radii.x.abs() < MAGICK_EPSILON || radii.y.abs() < MAGICK_EPSILON {
        return points;
    }
    // ImageMagick 6.9.11/6.9.12 (Ubuntu jammy/noble production) step; 6.9.13 uses a finer one.
    let delta = 2.0 * perceptible_reciprocal(radii.x.max(radii.y));
    let mut step = std::f64::consts::PI / 8.0;
    if (0.0..std::f64::consts::PI / 8.0).contains(&delta) {
        step = std::f64::consts::PI
            / 4.0
            / (std::f64::consts::PI * perceptible_reciprocal(delta) / 2.0);
    }
    let mut angle_x = arc_start.to_radians();
    let mut y = arc_end;
    while y < arc_start {
        y += 360.0;
    }
    let angle_y = y.to_radians();
    let full = 360f64.to_radians();
    while angle_x < angle_y {
        let a = angle_x % full;
        points.push(Point::new(
            a.cos() * radii.x + center.x,
            a.sin() * radii.y + center.y,
        ));
        angle_x += step;
    }
    let a = angle_y % full;
    points.push(Point::new(
        a.cos() * radii.x + center.x,
        a.sin() * radii.y + center.y,
    ));
    points
}

/// `ellipse cx,cy rx,ry 0,360`.
pub fn ellipse(center: Point, radii: Point) -> Subpath {
    let points = trace_ellipse(center, radii, 0.0, 360.0);
    let closed = is_closed(&points);
    Subpath { points, closed }
}

/// `circle cx,cy px,py` (`TraceCircle`): the radius is the distance to the second point.
pub fn circle(center: Point, edge: Point) -> Subpath {
    let radius = (edge.x - center.x).hypot(edge.y - center.y);
    ellipse(center, Point::new(radius, radius))
}

/// `rectangle x0,y0 x1,y1` (`TraceRectangle`).
pub fn rectangle(start: Point, end: Point) -> Subpath {
    Subpath {
        points: vec![
            start,
            Point::new(start.x, end.y),
            end,
            Point::new(end.x, start.y),
            start,
        ],
        closed: true,
    }
}

/// `roundrectangle x0,y0 x1,y1 rx,ry` (`TraceRoundRectangle`).
pub fn round_rectangle(start: Point, end: Point, arc: Point) -> Subpath {
    let segment = Point::new((end.x - start.x).abs(), (end.y - start.y).abs());
    if segment.x < MAGICK_EPSILON || segment.y < MAGICK_EPSILON {
        return Subpath {
            points: Vec::new(),
            closed: true,
        };
    }
    let arc = Point::new(arc.x.min(0.5 * segment.x), arc.y.min(0.5 * segment.y));
    let mut points = Vec::new();
    let corners = [
        (
            Point::new(start.x + segment.x - arc.x, start.y + arc.y),
            270.0,
            360.0,
        ),
        (
            Point::new(start.x + segment.x - arc.x, start.y + segment.y - arc.y),
            0.0,
            90.0,
        ),
        (
            Point::new(start.x + arc.x, start.y + segment.y - arc.y),
            90.0,
            180.0,
        ),
        (Point::new(start.x + arc.x, start.y + arc.y), 180.0, 270.0),
    ];
    for (center, from, to) in corners {
        points.extend(trace_ellipse(center, arc, from, to));
    }
    if let Some(first) = points.first().copied() {
        points.push(first);
    }
    Subpath {
        points,
        closed: true,
    }
}

/// `line x0,y0 x1,y1` (`TraceLine`).
pub fn line(start: Point, end: Point) -> Subpath {
    Subpath {
        points: vec![start, end],
        closed: false,
    }
}

/// `polygon x0,y0 x1,y1 ...` (`TracePolygon` closed).
pub fn polygon(vertices: &[Point]) -> Subpath {
    let mut points = Vec::with_capacity(vertices.len() + 1);
    points.extend_from_slice(vertices);
    if points.len() >= 2 && !is_closed(&points) {
        points.push(points[0]);
    }
    Subpath {
        points,
        closed: true,
    }
}

/// `polyline x0,y0 x1,y1 ...` (open polyline).
pub fn polyline(vertices: &[Point]) -> Subpath {
    Subpath {
        points: vertices.to_vec(),
        closed: false,
    }
}

struct SvgPathCursor<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> SvgPathCursor<'a> {
    fn new(d: &'a str) -> Self {
        Self {
            bytes: d.as_bytes(),
            pos: 0,
        }
    }

    fn skip_ws_and_commas(&mut self) {
        while self.pos < self.bytes.len() {
            let b = self.bytes[self.pos];
            if b.is_ascii_whitespace() || b == b',' {
                self.pos += 1;
            } else {
                break;
            }
        }
    }

    fn peek_command(&mut self) -> Option<u8> {
        self.skip_ws_and_commas();
        let b = *self.bytes.get(self.pos)?;
        if b.is_ascii_alphabetic() {
            Some(b)
        } else {
            None
        }
    }

    fn next_command(&mut self) -> Option<u8> {
        let cmd = self.peek_command()?;
        self.pos += 1;
        Some(cmd)
    }

    fn has_number(&mut self) -> bool {
        self.skip_ws_and_commas();
        matches!(
            self.bytes.get(self.pos),
            Some(b'+' | b'-' | b'.' | b'0'..=b'9')
        )
    }

    fn read_number(&mut self) -> Option<f64> {
        self.skip_ws_and_commas();
        let start = self.pos;
        if self.pos < self.bytes.len() && matches!(self.bytes[self.pos], b'+' | b'-') {
            self.pos += 1;
        }
        let mut has_digits = false;
        while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
            self.pos += 1;
            has_digits = true;
        }
        if self.pos < self.bytes.len() && self.bytes[self.pos] == b'.' {
            self.pos += 1;
            while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
                self.pos += 1;
                has_digits = true;
            }
        }
        if !has_digits {
            self.pos = start;
            return None;
        }
        if self.pos < self.bytes.len() && matches!(self.bytes[self.pos], b'e' | b'E') {
            let exp_start = self.pos;
            self.pos += 1;
            if self.pos < self.bytes.len() && matches!(self.bytes[self.pos], b'+' | b'-') {
                self.pos += 1;
            }
            let digits_start = self.pos;
            while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
                self.pos += 1;
            }
            if self.pos == digits_start {
                self.pos = exp_start;
            }
        }
        let s = std::str::from_utf8(&self.bytes[start..self.pos]).ok()?;
        s.parse::<f64>().ok()
    }

    fn read_flag(&mut self) -> Option<bool> {
        self.skip_ws_and_commas();
        match self.bytes.get(self.pos) {
            Some(b'0') => {
                self.pos += 1;
                Some(false)
            }
            Some(b'1') => {
                self.pos += 1;
                Some(true)
            }
            _ => None,
        }
    }
}

fn flatten_quad_bezier(p0: Point, p1: Point, p2: Point, out: &mut Vec<Point>) {
    let approx_len = (p1.x - p0.x).hypot(p1.y - p0.y) + (p2.x - p1.x).hypot(p2.y - p1.y);
    let steps = ((approx_len / 1.25).ceil() as usize).clamp(8, 128);
    for i in 1..=steps {
        let t = i as f64 / steps as f64;
        let mt = 1.0 - t;
        let x = mt * mt * p0.x + 2.0 * mt * t * p1.x + t * t * p2.x;
        let y = mt * mt * p0.y + 2.0 * mt * t * p1.y + t * t * p2.y;
        out.push(Point::new(x, y));
    }
}

fn flatten_cubic_bezier(p0: Point, p1: Point, p2: Point, p3: Point, out: &mut Vec<Point>) {
    let approx_len = (p1.x - p0.x).hypot(p1.y - p0.y)
        + (p2.x - p1.x).hypot(p2.y - p1.y)
        + (p3.x - p2.x).hypot(p3.y - p2.y);
    let steps = ((approx_len / 1.25).ceil() as usize).clamp(12, 192);
    for i in 1..=steps {
        let t = i as f64 / steps as f64;
        let mt = 1.0 - t;
        let b0 = mt * mt * mt;
        let b1 = 3.0 * mt * mt * t;
        let b2 = 3.0 * mt * t * t;
        let b3 = t * t * t;
        out.push(Point::new(
            b0 * p0.x + b1 * p1.x + b2 * p2.x + b3 * p3.x,
            b0 * p0.y + b1 * p1.y + b2 * p2.y + b3 * p3.y,
        ));
    }
}

#[allow(clippy::too_many_arguments)]
fn flatten_svg_arc(
    p0: Point,
    mut rx: f64,
    mut ry: f64,
    x_axis_rotation_deg: f64,
    large_arc: bool,
    sweep: bool,
    p1: Point,
    out: &mut Vec<Point>,
) {
    if (p0.x - p1.x).abs() < MAGICK_EPSILON && (p0.y - p1.y).abs() < MAGICK_EPSILON {
        return;
    }
    rx = rx.abs();
    ry = ry.abs();
    if rx < MAGICK_EPSILON || ry < MAGICK_EPSILON {
        out.push(p1);
        return;
    }

    // W3C SVG 1.1 Appendix F.6.5 endpoint-to-center conversion.
    let phi = x_axis_rotation_deg.to_radians();
    let (sin_phi, cos_phi) = phi.sin_cos();
    let dx2 = 0.5 * (p0.x - p1.x);
    let dy2 = 0.5 * (p0.y - p1.y);
    let x1p = cos_phi * dx2 + sin_phi * dy2;
    let y1p = -sin_phi * dx2 + cos_phi * dy2;

    let mut rx2 = rx * rx;
    let mut ry2 = ry * ry;
    let x1p2 = x1p * x1p;
    let y1p2 = y1p * y1p;

    let lambda = x1p2 / rx2 + y1p2 / ry2;
    if lambda > 1.0 {
        let s = lambda.sqrt();
        rx *= s;
        ry *= s;
        rx2 = rx * rx;
        ry2 = ry * ry;
    }

    let num = (rx2 * ry2 - rx2 * y1p2 - ry2 * x1p2).max(0.0);
    let den = rx2 * y1p2 + ry2 * x1p2;
    let factor = if den > MAGICK_EPSILON {
        (num / den).sqrt() * if large_arc == sweep { -1.0 } else { 1.0 }
    } else {
        0.0
    };
    let cxp = factor * rx * y1p / ry;
    let cyp = -factor * ry * x1p / rx;

    let cx = cos_phi * cxp - sin_phi * cyp + 0.5 * (p0.x + p1.x);
    let cy = sin_phi * cxp + cos_phi * cyp + 0.5 * (p0.y + p1.y);

    let vec_angle = |ux: f64, uy: f64, vx: f64, vy: f64| -> f64 {
        let dot = ux * vx + uy * vy;
        let len = (ux.hypot(uy) * vx.hypot(vy)).max(MAGICK_EPSILON);
        let cos_a = (dot / len).clamp(-1.0, 1.0);
        let sign = if ux * vy - uy * vx < 0.0 { -1.0 } else { 1.0 };
        sign * cos_a.acos()
    };

    let ux = (x1p - cxp) / rx;
    let uy = (y1p - cyp) / ry;
    let vx = (-x1p - cxp) / rx;
    let vy = (-y1p - cyp) / ry;

    let theta1 = vec_angle(1.0, 0.0, ux, uy);
    let mut dtheta = vec_angle(ux, uy, vx, vy);
    let two_pi = 2.0 * std::f64::consts::PI;
    if !sweep && dtheta > 0.0 {
        dtheta -= two_pi;
    } else if sweep && dtheta < 0.0 {
        dtheta += two_pi;
    }

    let arc_len = dtheta.abs() * rx.max(ry);
    let steps = ((arc_len / 1.25).ceil() as usize).clamp(8, 128);
    for i in 1..steps {
        let t = theta1 + dtheta * (i as f64 / steps as f64);
        let (st, ct) = t.sin_cos();
        let x = cos_phi * rx * ct - sin_phi * ry * st + cx;
        let y = sin_phi * rx * ct + cos_phi * ry * st + cy;
        out.push(Point::new(x, y));
    }
    out.push(p1);
}

/// Parses an SVG `d` path data string (`M/m`, `L/l`, `H/h`, `V/v`, `C/c`, `S/s`, `Q/q`,
/// `T/t`, `A/a`, `Z/z`) into flattened [`Subpath`]s ready for rasterization.
pub fn parse_svg_path(d: &str) -> Vec<Subpath> {
    let mut cursor = SvgPathCursor::new(d);
    let mut subpaths: Vec<Subpath> = Vec::new();
    let mut cur_pts: Vec<Point> = Vec::new();
    let mut cur = Point::new(0.0, 0.0);
    let mut subpath_start = Point::new(0.0, 0.0);
    let mut last_cubic_ctrl: Option<Point> = None;
    let mut last_quad_ctrl: Option<Point> = None;

    let flush_open = |pts: &mut Vec<Point>, out: &mut Vec<Subpath>| {
        if pts.len() >= 2 {
            out.push(Subpath {
                points: std::mem::take(pts),
                closed: false,
            });
        } else {
            pts.clear();
        }
    };

    while let Some(cmd) = cursor.next_command() {
        let rel = cmd.is_ascii_lowercase();
        match cmd.to_ascii_uppercase() {
            b'M' => {
                flush_open(&mut cur_pts, &mut subpaths);
                let Some(mut x) = cursor.read_number() else {
                    break;
                };
                let Some(mut y) = cursor.read_number() else {
                    break;
                };
                if rel {
                    x += cur.x;
                    y += cur.y;
                }
                cur = Point::new(x, y);
                subpath_start = cur;
                cur_pts.push(cur);
                last_cubic_ctrl = None;
                last_quad_ctrl = None;
                while cursor.has_number() {
                    let (Some(mut lx), Some(mut ly)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    if rel {
                        lx += cur.x;
                        ly += cur.y;
                    }
                    cur = Point::new(lx, ly);
                    cur_pts.push(cur);
                }
            }
            b'L' => {
                last_cubic_ctrl = None;
                last_quad_ctrl = None;
                while cursor.has_number() {
                    let (Some(mut x), Some(mut y)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    if rel {
                        x += cur.x;
                        y += cur.y;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    cur = Point::new(x, y);
                    cur_pts.push(cur);
                }
            }
            b'H' => {
                last_cubic_ctrl = None;
                last_quad_ctrl = None;
                while let Some(mut x) = cursor.read_number() {
                    if rel {
                        x += cur.x;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    cur = Point::new(x, cur.y);
                    cur_pts.push(cur);
                }
            }
            b'V' => {
                last_cubic_ctrl = None;
                last_quad_ctrl = None;
                while let Some(mut y) = cursor.read_number() {
                    if rel {
                        y += cur.y;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    cur = Point::new(cur.x, y);
                    cur_pts.push(cur);
                }
            }
            b'C' => {
                last_quad_ctrl = None;
                while cursor.has_number() {
                    let (Some(mut x1), Some(mut y1)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    let (Some(mut x2), Some(mut y2)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    let (Some(mut x), Some(mut y)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    if rel {
                        x1 += cur.x;
                        y1 += cur.y;
                        x2 += cur.x;
                        y2 += cur.y;
                        x += cur.x;
                        y += cur.y;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    let p1 = Point::new(x1, y1);
                    let p2 = Point::new(x2, y2);
                    let p3 = Point::new(x, y);
                    flatten_cubic_bezier(cur, p1, p2, p3, &mut cur_pts);
                    last_cubic_ctrl = Some(p2);
                    cur = p3;
                }
            }
            b'S' => {
                last_quad_ctrl = None;
                while cursor.has_number() {
                    let (Some(mut x2), Some(mut y2)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    let (Some(mut x), Some(mut y)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    if rel {
                        x2 += cur.x;
                        y2 += cur.y;
                        x += cur.x;
                        y += cur.y;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    let p1 = match last_cubic_ctrl {
                        Some(prev) => Point::new(2.0 * cur.x - prev.x, 2.0 * cur.y - prev.y),
                        None => cur,
                    };
                    let p2 = Point::new(x2, y2);
                    let p3 = Point::new(x, y);
                    flatten_cubic_bezier(cur, p1, p2, p3, &mut cur_pts);
                    last_cubic_ctrl = Some(p2);
                    cur = p3;
                }
            }
            b'Q' => {
                last_cubic_ctrl = None;
                while cursor.has_number() {
                    let (Some(mut x1), Some(mut y1)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    let (Some(mut x), Some(mut y)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    if rel {
                        x1 += cur.x;
                        y1 += cur.y;
                        x += cur.x;
                        y += cur.y;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    let p1 = Point::new(x1, y1);
                    let p2 = Point::new(x, y);
                    flatten_quad_bezier(cur, p1, p2, &mut cur_pts);
                    last_quad_ctrl = Some(p1);
                    cur = p2;
                }
            }
            b'T' => {
                last_cubic_ctrl = None;
                while cursor.has_number() {
                    let (Some(mut x), Some(mut y)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    if rel {
                        x += cur.x;
                        y += cur.y;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    let p1 = match last_quad_ctrl {
                        Some(prev) => Point::new(2.0 * cur.x - prev.x, 2.0 * cur.y - prev.y),
                        None => cur,
                    };
                    let p2 = Point::new(x, y);
                    flatten_quad_bezier(cur, p1, p2, &mut cur_pts);
                    last_quad_ctrl = Some(p1);
                    cur = p2;
                }
            }
            b'A' => {
                last_cubic_ctrl = None;
                last_quad_ctrl = None;
                while cursor.has_number() {
                    let (Some(rx), Some(ry), Some(rot)) = (
                        cursor.read_number(),
                        cursor.read_number(),
                        cursor.read_number(),
                    ) else {
                        break;
                    };
                    let (Some(large_arc), Some(sweep)) = (cursor.read_flag(), cursor.read_flag())
                    else {
                        break;
                    };
                    let (Some(mut x), Some(mut y)) = (cursor.read_number(), cursor.read_number())
                    else {
                        break;
                    };
                    if rel {
                        x += cur.x;
                        y += cur.y;
                    }
                    if cur_pts.is_empty() {
                        cur_pts.push(cur);
                    }
                    let p1 = Point::new(x, y);
                    flatten_svg_arc(cur, rx, ry, rot, large_arc, sweep, p1, &mut cur_pts);
                    cur = p1;
                }
            }
            b'Z' => {
                last_cubic_ctrl = None;
                last_quad_ctrl = None;
                if !cur_pts.is_empty() {
                    if !is_closed(&cur_pts) {
                        cur_pts.push(subpath_start);
                    }
                    subpaths.push(Subpath {
                        points: std::mem::take(&mut cur_pts),
                        closed: true,
                    });
                }
                cur = subpath_start;
            }
            _ => break,
        }
    }
    flush_open(&mut cur_pts, &mut subpaths);
    subpaths
}

fn is_closed(points: &[Point]) -> bool {
    match (points.first(), points.last()) {
        (Some(a), Some(b)) => {
            (a.x - b.x).abs() < MAGICK_EPSILON && (a.y - b.y).abs() < MAGICK_EPSILON
        }
        _ => false,
    }
}

#[inline]
fn perceptible_reciprocal(x: f64) -> f64 {
    let sign = if x < 0.0 { -1.0 } else { 1.0 };
    if sign * x >= MAGICK_EPSILON {
        1.0 / x
    } else {
        sign / MAGICK_EPSILON
    }
}

/// A y-monotonic run of segments (`EdgeInfo`), points sorted by increasing y.
#[derive(Clone, Debug)]
struct Edge {
    points: Vec<Point>,
    x1: f64,
    x2: f64,
    y1: f64,
    y2: f64,
    ghostline: bool,
    direction: bool,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum PathCode {
    MoveTo,
    Open,
    Ghostline,
    LineTo,
}

/// `ConvertPrimitiveToPath`: drops duplicate consecutive points and closes open subpaths
/// with a ghost line (which counts for filling but is never stroked).
fn primitive_to_path(subpaths: &[Subpath]) -> Vec<(PathCode, Point)> {
    let mut path = Vec::new();
    for sub in subpaths {
        let n = sub.points.len();
        if n == 0 {
            continue;
        }
        let start = path.len();
        let first = sub.points[0];
        let mut q = Point::new(-1.0, -1.0);
        for (i, &pt) in sub.points.iter().enumerate() {
            let code = if i == 0 {
                PathCode::MoveTo
            } else {
                PathCode::LineTo
            };
            let last = i == n - 1;
            if code == PathCode::MoveTo
                || last
                || (q.x - pt.x).abs() >= MAGICK_EPSILON
                || (q.y - pt.y).abs() >= MAGICK_EPSILON
            {
                path.push((code, pt));
                q = pt;
            }
        }
        if !sub.closed {
            path[start].0 = PathCode::Open;
            path.push((PathCode::Ghostline, sub.points[n - 1]));
            path.push((PathCode::LineTo, first));
        }
    }
    path
}

/// `ConvertPathToPolygon`: splits the path into y-monotonic edges.
fn path_to_edges(path: &[(PathCode, Point)]) -> Vec<Edge> {
    let mut edges = Vec::new();
    let mut points: Vec<Point> = Vec::new();
    let mut direction: i32 = 0;
    let mut ghostline = false;
    let mut point = Point::new(0.0, 0.0);
    let mut bx1 = 0.0;
    let mut bx2 = 0.0;

    let finish = |points: &mut Vec<Point>,
                  direction: i32,
                  ghostline: bool,
                  bx1: f64,
                  bx2: f64,
                  edges: &mut Vec<Edge>| {
        let mut pts = std::mem::take(points);
        if direction < 0 {
            pts.reverse();
        }
        let y1 = pts[0].y;
        let y2 = pts[pts.len() - 1].y;
        edges.push(Edge {
            points: pts,
            x1: bx1,
            x2: bx2,
            y1,
            y2,
            ghostline,
            direction: direction > 0,
        });
    };

    for &(code, pt) in path {
        if matches!(
            code,
            PathCode::MoveTo | PathCode::Open | PathCode::Ghostline
        ) {
            if points.len() >= 2 {
                finish(&mut points, direction, ghostline, bx1, bx2, &mut edges);
            }
            points.clear();
            ghostline = code == PathCode::Ghostline;
            point = pt;
            points.push(pt);
            bx1 = pt.x;
            bx2 = pt.x;
            direction = 0;
            continue;
        }
        let next_direction =
            if pt.y > point.y || ((pt.y - point.y).abs() < MAGICK_EPSILON && pt.x > point.x) {
                1
            } else {
                -1
            };
        if !points.is_empty() && direction != 0 && direction != next_direction {
            point = points[points.len() - 1];
            finish(&mut points, direction, ghostline, bx1, bx2, &mut edges);
            ghostline = false;
            points.push(point);
            bx1 = point.x;
            bx2 = point.x;
        }
        direction = next_direction;
        point = pt;
        points.push(pt);
        if pt.x < bx1 {
            bx1 = pt.x;
        }
        if pt.x > bx2 {
            bx2 = pt.x;
        }
    }
    if points.len() >= 2 {
        finish(&mut points, direction, ghostline, bx1, bx2, &mut edges);
    }
    edges
}

/// Rasterization-ready polygon: edges plus the per-row search hints that stand in for
/// ImageMagick's `highwater` scanline cache.
pub struct Polygon {
    edges: Vec<Edge>,
}

#[derive(Clone, Copy)]
struct RowEdge {
    dist_active: bool,
    seg_start: usize,
    seg_end: usize,
    dist_x1: f64,
    dist_x2: f64,
    wind_active: bool,
    wind_q: Point,
    wind_q1: Point,
}

impl Polygon {
    pub fn new(subpaths: &[Subpath]) -> Self {
        Polygon {
            edges: path_to_edges(&primitive_to_path(subpaths)),
        }
    }

    fn bounds(&self) -> Option<(f64, f64, f64, f64)> {
        let first = self.edges.first()?;
        let mut b = (first.x1, first.y1, first.x2, first.y2);
        for e in &self.edges[1..] {
            b.0 = b.0.min(e.x1);
            b.1 = b.1.min(e.y1);
            b.2 = b.2.max(e.x2);
            b.3 = b.3.max(e.y2);
        }
        Some(b)
    }

    /// `GetOpacityPixel`: returns `(fill_opacity, stroke_opacity)` for pixel center `(x, y)`.
    fn opacity(
        &self,
        mid: f64,
        fill: bool,
        rule: FillRule,
        x: f64,
        y: f64,
        row_edges: &[RowEdge],
    ) -> (f64, f64) {
        let mut stroke_opacity: f64 = 0.0;
        let mut subpath_opacity: f64 = 0.0;
        for (edge, re) in self.edges.iter().zip(row_edges) {
            if !re.dist_active || x <= re.dist_x1 || x > re.dist_x2 {
                continue;
            }
            let pts = &edge.points;
            for i in re.seg_start..re.seg_end {
                let q = pts[i - 1];
                let q1 = pts[i];
                let mut dx = q1.x - q.x;
                let mut dy = q1.y - q.y;
                let mut beta = dx * (x - q.x) + dy * (y - q.y);
                let distance;
                if beta <= 0.0 {
                    dx = x - q.x;
                    dy = y - q.y;
                    distance = dx * dx + dy * dy;
                } else {
                    let alpha = dx * dx + dy * dy;
                    if beta >= alpha {
                        dx = x - q1.x;
                        dy = y - q1.y;
                        distance = dx * dx + dy * dy;
                    } else {
                        let alpha = perceptible_reciprocal(alpha);
                        beta = dx * (y - q.y) - dy * (x - q.x);
                        distance = alpha * beta * beta;
                    }
                }
                let mut beta = 0.0;
                if !edge.ghostline {
                    let alpha = mid + 0.5;
                    if stroke_opacity < 1.0 && distance <= (alpha + 0.25) * (alpha + 0.25) {
                        let alpha = mid - 0.5;
                        if distance <= (alpha + 0.25) * (alpha + 0.25) {
                            stroke_opacity = 1.0;
                        } else {
                            beta = 1.0;
                            if (distance - 1.0).abs() >= MAGICK_EPSILON {
                                beta = distance.sqrt();
                            }
                            let alpha = beta - mid - 0.5;
                            if stroke_opacity < (alpha - 0.25) * (alpha - 0.25) {
                                stroke_opacity = (alpha - 0.25) * (alpha - 0.25);
                            }
                        }
                    }
                }
                if !fill || distance > 1.0 || subpath_opacity >= 1.0 {
                    continue;
                }
                if distance <= 0.0 {
                    subpath_opacity = 1.0;
                    continue;
                }
                if beta.abs() < MAGICK_EPSILON {
                    beta = 1.0;
                    if (distance - 1.0).abs() >= MAGICK_EPSILON {
                        beta = distance.sqrt();
                    }
                }
                let alpha = beta - 1.0;
                if subpath_opacity < alpha * alpha {
                    subpath_opacity = alpha * alpha;
                }
            }
        }
        if !fill {
            return (0.0, stroke_opacity);
        }
        if subpath_opacity >= 1.0 {
            return (1.0, stroke_opacity);
        }
        let mut winding: i64 = 0;
        for (edge, re) in self.edges.iter().zip(row_edges) {
            if !re.wind_active || x <= edge.x1 {
                continue;
            }
            let w = if edge.direction { 1 } else { -1 };
            if x > edge.x2 {
                winding += w;
                continue;
            }
            let q = re.wind_q;
            let q1 = re.wind_q1;
            if (q1.x - q.x) * (y - q.y) <= (q1.y - q.y) * (x - q.x) {
                winding += w;
            }
        }
        let inside = match rule {
            FillRule::EvenOdd => winding.abs() & 1 != 0,
            FillRule::NonZero => winding != 0,
        };
        (if inside { 1.0 } else { subpath_opacity }, stroke_opacity)
    }

    /// Precomputes active segment bounds and winding segment per edge for row `y`.
    fn prepare_row(&self, mid: f64, y: f64, row_edges: &mut Vec<RowEdge>) {
        row_edges.clear();
        let reach = mid + 0.5;
        let reach_pad = mid + 1.0;
        for edge in &self.edges {
            let pts = &edge.points;
            let mut dist_active = false;
            let mut seg_start = 1usize;
            let mut seg_end = 1usize;
            let mut dist_x1 = 0.0;
            let mut dist_x2 = -1.0;

            if pts.len() >= 2 && y > edge.y1 - reach && y <= edge.y2 + reach {
                seg_start = pts.partition_point(|p| y > p.y + reach).max(1);
                seg_end = seg_start;
                let mut min_x = f64::INFINITY;
                let mut max_x = f64::NEG_INFINITY;
                while seg_end < pts.len() {
                    let q = pts[seg_end - 1];
                    if y <= q.y - reach {
                        break;
                    }
                    let q1 = pts[seg_end];
                    min_x = min_x.min(q.x.min(q1.x));
                    max_x = max_x.max(q.x.max(q1.x));
                    seg_end += 1;
                }
                if seg_start < seg_end {
                    dist_active = true;
                    dist_x1 = (min_x - reach_pad).max(edge.x1 - reach);
                    dist_x2 = (max_x + reach_pad).min(edge.x2 + reach);
                }
            }

            let wind_active = pts.len() >= 2 && y > edge.y1 && y <= edge.y2;
            let (wind_q, wind_q1) = if wind_active {
                let i = if pts.len() <= 2 {
                    1
                } else {
                    (pts[1..pts.len() - 1].partition_point(|p| y > p.y) + 1).min(pts.len() - 1)
                };
                (pts[i - 1], pts[i])
            } else {
                (Point { x: 0.0, y: 0.0 }, Point { x: 0.0, y: 0.0 })
            };

            row_edges.push(RowEdge {
                dist_active,
                seg_start,
                seg_end,
                dist_x1,
                dist_x2,
                wind_active,
                wind_q,
                wind_q1,
            });
        }
    }
}

/// `DrawPolygonPrimitive`: fills and/or strokes `polygon` onto `canvas`.
pub fn draw_polygon(
    canvas: &mut Canvas,
    polygon: &Polygon,
    mid: f64,
    fill: Option<Rgba>,
    stroke: Option<Rgba>,
    rule: FillRule,
) {
    let Some((mut x1, mut y1, mut x2, mut y2)) = polygon.bounds() else {
        return;
    };
    x1 -= mid + 1.0;
    y1 -= mid + 1.0;
    x2 += mid + 1.0;
    y2 += mid + 1.0;
    let cols = canvas.width as f64;
    let rows = canvas.height as f64;
    if x1 >= cols || y1 >= rows || x2 <= 0.0 || y2 <= 0.0 {
        return;
    }
    let clamp = |v: f64, max: f64| {
        if v < 0.0 {
            0.0
        } else if v >= max - 1.0 {
            max - 1.0
        } else {
            v
        }
    };
    let (x1, y1, x2, y2) = (
        clamp(x1, cols),
        clamp(y1, rows),
        clamp(x2, cols),
        clamp(y2, rows),
    );
    let ex1 = (x1 - 0.5).ceil() as i64;
    let ey1 = (y1 - 0.5).ceil() as i64;
    let ex2 = (x2 + 0.5).floor() as i64;
    let ey2 = (y2 + 0.5).floor() as i64;
    let fill_color = fill.unwrap_or(Rgba::TRANSPARENT);
    let stroke_color = stroke.unwrap_or(Rgba::TRANSPARENT);
    // ImageMagick always evaluates the fill test (`FloodfillMethod`); a transparent fill
    // simply composites nothing.
    let mut row_edges = Vec::with_capacity(polygon.edges.len());
    for y in ey1..=ey2 {
        let yf = y as f64;
        polygon.prepare_row(mid, yf, &mut row_edges);
        for x in ex1..=ex2 {
            let (fill_opacity, stroke_opacity) =
                polygon.opacity(mid, true, rule, x as f64, yf, &row_edges);
            if fill_opacity > 0.0 && fill_color.a > 0.0 {
                canvas.blend(x as usize, y as usize, fill_color, fill_opacity as f32);
            }
            if stroke_opacity > 0.0 && stroke_color.a > 0.0 {
                canvas.blend(x as usize, y as usize, stroke_color, stroke_opacity as f32);
            }
        }
    }
}

/// The stroke outline ImageMagick fills for strokes wider than two pixels
/// (`TraceStrokePolygon` with the default butt caps and miter joins).
fn stroke_outline(sub: &Subpath, width: f64) -> Vec<Subpath> {
    let mid = width / 2.0;
    let mut pts: Vec<Point> = Vec::with_capacity(sub.points.len());
    for &p in &sub.points {
        if pts.last().is_none_or(|l: &Point| {
            (l.x - p.x).abs() >= MAGICK_EPSILON || (l.y - p.y).abs() >= MAGICK_EPSILON
        }) {
            pts.push(p);
        }
    }
    let closed = sub.closed || is_closed(&sub.points);
    if closed && pts.len() > 1 && is_closed(&pts) {
        pts.pop();
    }
    if pts.len() < 2 {
        return Vec::new();
    }
    let normal = |a: Point, b: Point| {
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let len = dx.hypot(dy);
        Point::new(-dy / len, dx / len)
    };
    let n = pts.len();
    if !closed {
        // Butt caps: each segment becomes a rectangle; joins use the miter point.
        let mut left = Vec::with_capacity(n);
        let mut right = Vec::with_capacity(n);
        for i in 0..n {
            let (na, nb) = if i == 0 {
                let nn = normal(pts[0], pts[1]);
                (nn, nn)
            } else if i == n - 1 {
                let nn = normal(pts[n - 2], pts[n - 1]);
                (nn, nn)
            } else {
                (normal(pts[i - 1], pts[i]), normal(pts[i], pts[i + 1]))
            };
            let m = miter(na, nb, mid);
            left.push(Point::new(pts[i].x + m.x, pts[i].y + m.y));
            right.push(Point::new(pts[i].x - m.x, pts[i].y - m.y));
        }
        let mut outline = left;
        right.reverse();
        outline.extend(right);
        outline.push(outline[0]);
        return vec![Subpath {
            points: outline,
            closed: true,
        }];
    }
    let mut left = Vec::with_capacity(n + 1);
    let mut right = Vec::with_capacity(n + 1);
    for i in 0..n {
        let prev = pts[(i + n - 1) % n];
        let next = pts[(i + 1) % n];
        let m = miter(normal(prev, pts[i]), normal(pts[i], next), mid);
        left.push(Point::new(pts[i].x + m.x, pts[i].y + m.y));
        right.push(Point::new(pts[i].x - m.x, pts[i].y - m.y));
    }
    left.push(left[0]);
    right.reverse();
    right.push(right[0]);
    vec![
        Subpath {
            points: left,
            closed: true,
        },
        Subpath {
            points: right,
            closed: true,
        },
    ]
}

/// Offset of a miter join between two unit normals at distance `mid` (clamped at miterlimit 4).
fn miter(na: Point, nb: Point, mid: f64) -> Point {
    let denom = 1.0 + na.x * nb.x + na.y * nb.y;
    if denom.abs() < 1e-9 {
        return Point::new(na.x * mid, na.y * mid);
    }
    let mx = (na.x + nb.x) * mid / denom;
    let my = (na.y + nb.y) * mid / denom;
    let len = mx.hypot(my);
    let limit = 4.0 * mid;
    if len > limit {
        let scale = limit / len;
        Point::new(mx * scale, my * scale)
    } else {
        Point::new(mx, my)
    }
}

/// Appends circular arc points from normal `n_from` to `n_to` around `center` at radius `mid`.
fn push_arc_between_normals(
    center: Point,
    n_from: Point,
    n_to: Point,
    mid: f64,
    ccw: bool,
    out: &mut Vec<Point>,
) {
    let a0 = n_from.y.atan2(n_from.x);
    let a1 = n_to.y.atan2(n_to.x);
    let two_pi = 2.0 * std::f64::consts::PI;
    let mut delta = a1 - a0;
    if ccw {
        while delta < 0.0 {
            delta += two_pi;
        }
    } else {
        while delta > 0.0 {
            delta -= two_pi;
        }
    }
    let steps = ((delta.abs() * mid / 1.0).ceil() as usize).clamp(4, 32);
    for i in 0..=steps {
        let a = a0 + delta * (i as f64 / steps as f64);
        out.push(Point::new(
            center.x + a.cos() * mid,
            center.y + a.sin() * mid,
        ));
    }
}

/// Builds stroke outlines supporting mixed `LineCap` / `LineJoin` modes.
fn stroke_outline_styled(sub: &Subpath, style: StrokeStyle) -> Vec<Subpath> {
    if style.cap == LineCap::Butt && style.join == LineJoin::Miter {
        return stroke_outline(sub, style.width);
    }
    let mid = style.width / 2.0;
    let mut pts: Vec<Point> = Vec::with_capacity(sub.points.len());
    for &p in &sub.points {
        if pts.last().is_none_or(|l: &Point| {
            (l.x - p.x).abs() >= MAGICK_EPSILON || (l.y - p.y).abs() >= MAGICK_EPSILON
        }) {
            pts.push(p);
        }
    }
    let closed = sub.closed || is_closed(&sub.points);
    if closed && pts.len() > 1 && is_closed(&pts) {
        pts.pop();
    }
    if pts.len() < 2 {
        return Vec::new();
    }
    let normal = |a: Point, b: Point| {
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let len = dx.hypot(dy).max(MAGICK_EPSILON);
        Point::new(-dy / len, dx / len)
    };
    let n = pts.len();
    let mut left: Vec<Point> = Vec::with_capacity(n * 4);
    let mut right: Vec<Point> = Vec::with_capacity(n * 4);

    if !closed {
        let n_start = normal(pts[0], pts[1]);
        left.push(Point::new(
            pts[0].x + n_start.x * mid,
            pts[0].y + n_start.y * mid,
        ));
        right.push(Point::new(
            pts[0].x - n_start.x * mid,
            pts[0].y - n_start.y * mid,
        ));

        for i in 1..n - 1 {
            let na = normal(pts[i - 1], pts[i]);
            let nb = normal(pts[i], pts[i + 1]);
            match style.join {
                LineJoin::Miter => {
                    let m = miter(na, nb, mid);
                    left.push(Point::new(pts[i].x + m.x, pts[i].y + m.y));
                    right.push(Point::new(pts[i].x - m.x, pts[i].y - m.y));
                }
                LineJoin::Round => {
                    let cross = na.x * nb.y - na.y * nb.x;
                    if cross > 1e-6 {
                        push_arc_between_normals(pts[i], na, nb, mid, true, &mut left);
                        let m = miter(na, nb, mid);
                        right.push(Point::new(pts[i].x - m.x, pts[i].y - m.y));
                    } else if cross < -1e-6 {
                        let m = miter(na, nb, mid);
                        left.push(Point::new(pts[i].x + m.x, pts[i].y + m.y));
                        push_arc_between_normals(
                            pts[i],
                            Point::new(-na.x, -na.y),
                            Point::new(-nb.x, -nb.y),
                            mid,
                            false,
                            &mut right,
                        );
                    } else {
                        left.push(Point::new(pts[i].x + nb.x * mid, pts[i].y + nb.y * mid));
                        right.push(Point::new(pts[i].x - nb.x * mid, pts[i].y - nb.y * mid));
                    }
                }
            }
        }

        let n_end = normal(pts[n - 2], pts[n - 1]);
        left.push(Point::new(
            pts[n - 1].x + n_end.x * mid,
            pts[n - 1].y + n_end.y * mid,
        ));
        right.push(Point::new(
            pts[n - 1].x - n_end.x * mid,
            pts[n - 1].y - n_end.y * mid,
        ));

        let mut outline = left;
        if style.cap == LineCap::Round {
            push_arc_between_normals(
                pts[n - 1],
                n_end,
                Point::new(-n_end.x, -n_end.y),
                mid,
                false,
                &mut outline,
            );
        }
        right.reverse();
        outline.extend(right);
        if style.cap == LineCap::Round {
            push_arc_between_normals(
                pts[0],
                Point::new(-n_start.x, -n_start.y),
                n_start,
                mid,
                false,
                &mut outline,
            );
        }
        if let Some(&first) = outline.first() {
            if !is_closed(&outline) {
                outline.push(first);
            }
        }
        return vec![Subpath {
            points: outline,
            closed: true,
        }];
    }

    stroke_outline(sub, style.width)
}

/// Exact Minkowski-capsule stroke rasterizer for wide strokes (`mid > 1.0`) with round joins
/// and round caps (or closed paths with round joins). Evaluates exact Euclidean distance to
/// the polyline segments so tight Bézier curves never self-intersect.
fn draw_round_stroke(canvas: &mut Canvas, polygon: &Polygon, mid: f64, stroke_color: Rgba) {
    if stroke_color.a <= 0.0 {
        return;
    }
    let Some((mut x1, mut y1, mut x2, mut y2)) = polygon.bounds() else {
        return;
    };
    let pad = mid + 1.0;
    x1 -= pad;
    y1 -= pad;
    x2 += pad;
    y2 += pad;
    let cols = canvas.width as f64;
    let rows = canvas.height as f64;
    if x1 >= cols || y1 >= rows || x2 <= 0.0 || y2 <= 0.0 {
        return;
    }
    let clamp = |v: f64, max: f64| v.clamp(0.0, max - 1.0);
    let (x1, y1, x2, y2) = (
        clamp(x1, cols),
        clamp(y1, rows),
        clamp(x2, cols),
        clamp(y2, rows),
    );
    let ex1 = (x1 - 0.5).ceil() as i64;
    let ey1 = (y1 - 0.5).ceil() as i64;
    let ex2 = (x2 + 0.5).floor() as i64;
    let ey2 = (y2 + 0.5).floor() as i64;

    let outer = mid + 1.0;
    let outer_sq = outer * outer;
    let inner_sq = mid * mid;
    // `prepare_row` uses `mid_arg + 0.5` as `reach`, so pass `mid + 0.5` to get `mid + 1.0`.
    let row_reach_mid = mid + 0.5;
    let mut row_edges = Vec::with_capacity(polygon.edges.len());

    for y in ey1..=ey2 {
        let yf = y as f64;
        polygon.prepare_row(row_reach_mid, yf, &mut row_edges);
        for x in ex1..=ex2 {
            let xf = x as f64;
            let mut min_dist_sq = f64::INFINITY;
            for (edge, re) in polygon.edges.iter().zip(&row_edges) {
                if edge.ghostline || !re.dist_active || xf <= re.dist_x1 || xf > re.dist_x2 {
                    continue;
                }
                let pts = &edge.points;
                for i in re.seg_start..re.seg_end {
                    let q = pts[i - 1];
                    let q1 = pts[i];
                    let dx = q1.x - q.x;
                    let dy = q1.y - q.y;
                    let beta = dx * (xf - q.x) + dy * (yf - q.y);
                    let dist_sq = if beta <= 0.0 {
                        let px = xf - q.x;
                        let py = yf - q.y;
                        px * px + py * py
                    } else {
                        let alpha = dx * dx + dy * dy;
                        if beta >= alpha {
                            let px = xf - q1.x;
                            let py = yf - q1.y;
                            px * px + py * py
                        } else {
                            let cross = dx * (yf - q.y) - dy * (xf - q.x);
                            perceptible_reciprocal(alpha) * cross * cross
                        }
                    };
                    if dist_sq < min_dist_sq {
                        min_dist_sq = dist_sq;
                        if min_dist_sq <= inner_sq {
                            break;
                        }
                    }
                }
                if min_dist_sq <= inner_sq {
                    break;
                }
            }
            if min_dist_sq <= inner_sq {
                canvas.blend(x as usize, y as usize, stroke_color, 1.0);
            } else if min_dist_sq < outer_sq {
                let d = min_dist_sq.sqrt() - mid;
                let opacity = (1.0 - d) * (1.0 - d);
                if opacity > 0.0 {
                    canvas.blend(x as usize, y as usize, stroke_color, opacity as f32);
                }
            }
        }
    }
}

/// Fills and strokes a multi-subpath primitive with explicit [`StrokeStyle`] and [`FillRule`].
pub fn draw_subpaths_styled(
    canvas: &mut Canvas,
    subpaths: &[Subpath],
    fill: Option<Rgba>,
    stroke: Option<Rgba>,
    style: StrokeStyle,
    rule: FillRule,
) {
    let valid_any = subpaths.iter().any(|s| s.points.len() >= 2);
    if !valid_any {
        return;
    }
    let mid = style.width / 2.0;
    let stroke_visible = stroke.is_some_and(|s| s.a > 0.0) && style.width > 0.0;
    let fill_visible = fill.is_some_and(|f| f.a > 0.0);
    let polygon = Polygon::new(subpaths);

    if mid > 1.0 && stroke_visible {
        if fill_visible {
            draw_polygon(canvas, &polygon, 0.0, fill, None, rule);
        }
        let all_closed = subpaths.iter().all(|s| s.closed || is_closed(&s.points));
        if (all_closed || style.cap == LineCap::Round) && style.join == LineJoin::Round {
            if let Some(sc) = stroke {
                draw_round_stroke(canvas, &polygon, mid, sc);
            }
        } else {
            let mut outlines = Vec::new();
            for sub in subpaths {
                outlines.extend(stroke_outline_styled(sub, style));
            }
            let outline_poly = Polygon::new(&outlines);
            draw_polygon(canvas, &outline_poly, 0.0, stroke, None, FillRule::NonZero);
        }
    } else {
        draw_polygon(
            canvas,
            &polygon,
            if stroke_visible { mid } else { 0.0 },
            fill,
            if stroke_visible { stroke } else { None },
            rule,
        );
    }
}

/// Draws a single [`Subpath`] with explicit [`StrokeStyle`] (`LineCap` + `LineJoin`).
pub fn draw_primitive_styled(
    canvas: &mut Canvas,
    sub: &Subpath,
    fill: Option<Rgba>,
    stroke: Option<Rgba>,
    style: StrokeStyle,
) {
    draw_subpaths_styled(
        canvas,
        std::slice::from_ref(sub),
        fill,
        stroke,
        style,
        FillRule::EvenOdd,
    );
}

/// `DrawPrimitive` for path-like primitives: fills, then strokes, with ImageMagick's split
/// between thin strokes (distance ramp) and wide strokes (filled outline polygon).
pub fn draw_primitive(
    canvas: &mut Canvas,
    sub: &Subpath,
    fill: Option<Rgba>,
    stroke: Option<Rgba>,
    stroke_width: f64,
) {
    if sub.points.len() < 2 {
        return;
    }
    let mid = stroke_width / 2.0;
    let stroke_visible = stroke.is_some_and(|s| s.a > 0.0);
    let polygon = Polygon::new(std::slice::from_ref(sub));
    if mid > 1.0 && stroke_visible {
        draw_polygon(canvas, &polygon, 0.0, fill, None, FillRule::EvenOdd);
        let outline = Polygon::new(&stroke_outline(sub, stroke_width));
        draw_polygon(canvas, &outline, 0.0, stroke, None, FillRule::NonZero);
    } else {
        draw_polygon(canvas, &polygon, mid, fill, stroke, FillRule::EvenOdd);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn alpha_at(c: &Canvas, x: usize, y: usize) -> f32 {
        c.get(x, y).a
    }

    #[test]
    fn integer_rectangles_have_crisp_edges() {
        let mut c = Canvas::new(20, 20, Rgba::TRANSPARENT);
        draw_primitive(
            &mut c,
            &rectangle(Point::new(5.0, 5.0), Point::new(10.0, 10.0)),
            Some(Rgba::BLACK),
            None,
            1.0,
        );
        assert_eq!(alpha_at(&c, 5, 5), 1.0);
        assert_eq!(alpha_at(&c, 10, 10), 1.0);
        assert_eq!(alpha_at(&c, 4, 7), 0.0);
        assert_eq!(alpha_at(&c, 11, 7), 0.0);
    }

    #[test]
    fn wide_line_strokes_cover_inclusive_rows() {
        let mut c = Canvas::new(40, 20, Rgba::WHITE);
        draw_primitive(
            &mut c,
            &line(Point::new(5.0, 10.0), Point::new(30.0, 10.0)),
            Some(Rgba::WHITE),
            Some(Rgba::BLACK),
            4.0,
        );
        for y in 8..=12 {
            assert_eq!(c.get(15, y).r, 0.0, "row {y} should be black");
        }
        assert_eq!(c.get(15, 7).r, 1.0);
        assert_eq!(c.get(15, 13).r, 1.0);
    }

    #[test]
    fn thin_line_strokes_use_distance_ramp() {
        let mut c = Canvas::new(40, 20, Rgba::WHITE);
        draw_primitive(
            &mut c,
            &line(Point::new(5.0, 10.0), Point::new(30.0, 10.0)),
            Some(Rgba::BLACK),
            Some(Rgba::BLACK),
            2.0,
        );
        assert_eq!(c.get(15, 10).r, 0.0);
        // Rows at distance 1 get (1 - 1.75)^2 = 0.5625 of the stroke color.
        assert!((c.get(15, 9).r - (1.0 - 0.5625)).abs() < 1e-5);
        assert_eq!(c.get(15, 7).r, 1.0);
    }

    #[test]
    fn round_rectangle_spans_requested_corners() {
        let sub = round_rectangle(
            Point::new(10.0, 10.0),
            Point::new(50.0, 40.0),
            Point::new(8.0, 8.0),
        );
        assert!(sub.closed);
        let min_x = sub.points.iter().map(|p| p.x).fold(f64::MAX, f64::min);
        let max_y = sub.points.iter().map(|p| p.y).fold(f64::MIN, f64::max);
        assert!((min_x - 10.0).abs() < 1e-9);
        assert!((max_y - 40.0).abs() < 1e-9);
    }

    #[test]
    fn circles_fill_their_center() {
        let mut c = Canvas::new(30, 30, Rgba::TRANSPARENT);
        draw_primitive(
            &mut c,
            &circle(Point::new(15.0, 15.0), Point::new(21.0, 15.0)),
            Some(Rgba::BLACK),
            None,
            4.0,
        );
        assert_eq!(alpha_at(&c, 15, 15), 1.0);
        assert_eq!(alpha_at(&c, 21, 15), 1.0);
        assert_eq!(alpha_at(&c, 2, 2), 0.0);
    }
}
