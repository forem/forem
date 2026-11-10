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

/// Offset of a miter join between two unit normals at distance `mid`.
fn miter(na: Point, nb: Point, mid: f64) -> Point {
    let denom = 1.0 + na.x * nb.x + na.y * nb.y;
    if denom.abs() < 1e-9 {
        return Point::new(na.x * mid, na.y * mid);
    }
    Point::new((na.x + nb.x) * mid / denom, (na.y + nb.y) * mid / denom)
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
