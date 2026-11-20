//! Procedural mascot avatar renderer (the pure-Rust replacement for the ImageMagick
//! `convert` pipeline in `Images::ProfileImageGenerator`).
//!
//! Renders a deterministic `400x400` 8-bit RGB PNG from a [`ProfileAvatarTraits`] specification
//! with zero subprocesses or temporary ImageMagick files.

use super::canvas::{Canvas, Rgba};
use super::draw::{
    circle, draw_primitive_styled, draw_subpaths_styled, ellipse, line, parse_svg_path, polygon,
    round_rectangle, FillRule, LineCap, LineJoin, Point, StrokeStyle, Subpath,
};
use super::{encode_png, SocialImageError};

pub const AVATAR_SIZE: usize = 400;
const INK_HEX: &str = "#18181b";

/// Palette colors selected by `Images::ProfileImageGenerator`.
#[derive(Clone, Debug)]
pub struct AvatarPalette<'a> {
    pub bg: &'a str,
    pub halo: &'a str,
    pub sparkle: &'a str,
    pub shadow: &'a str,
    pub body: &'a str,
    pub shirt: &'a str,
    pub trim: &'a str,
    pub accent: &'a str,
    pub cheek: &'a str,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BackdropStyle {
    Bubbles,
    Sparkles,
    Rings,
    Confetti,
    Clouds,
    Planets,
}

impl BackdropStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "bubbles" => Ok(Self::Bubbles),
            "sparkles" => Ok(Self::Sparkles),
            "rings" => Ok(Self::Rings),
            "confetti" => Ok(Self::Confetti),
            "clouds" => Ok(Self::Clouds),
            "planets" => Ok(Self::Planets),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown backdrop style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum OutfitStyle {
    CrewSweater,
    Hoodie,
    Overalls,
    StripedTee,
    StarSweater,
    Bandana,
}

impl OutfitStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "crew_sweater" => Ok(Self::CrewSweater),
            "hoodie" => Ok(Self::Hoodie),
            "overalls" => Ok(Self::Overalls),
            "striped_tee" => Ok(Self::StripedTee),
            "star_sweater" => Ok(Self::StarSweater),
            "bandana" => Ok(Self::Bandana),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown outfit style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ArmStyle {
    None,
    LeftWave,
    RightWave,
    BothCheering,
}

impl ArmStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "none" => Ok(Self::None),
            "left_wave" => Ok(Self::LeftWave),
            "right_wave" => Ok(Self::RightWave),
            "both_cheering" => Ok(Self::BothCheering),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown arm style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HeadStyle {
    Squircle,
    Mochi,
    BearCub,
    KittyEars,
    BunnyEars,
    CloudPuff,
    RetroBot,
    PearBean,
}

impl HeadStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "squircle" => Ok(Self::Squircle),
            "mochi" => Ok(Self::Mochi),
            "bear_cub" => Ok(Self::BearCub),
            "kitty_ears" => Ok(Self::KittyEars),
            "bunny_ears" => Ok(Self::BunnyEars),
            "cloud_puff" => Ok(Self::CloudPuff),
            "retro_bot" => Ok(Self::RetroBot),
            "pear_bean" => Ok(Self::PearBean),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown head style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TopperStyle {
    Sprout,
    Antenna,
    TwinFeelers,
    Beanie,
    Crown,
    Halo,
    CurlTuft,
    PartyCone,
    FlowerStem,
}

impl TopperStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "sprout" => Ok(Self::Sprout),
            "antenna" => Ok(Self::Antenna),
            "twin_feelers" => Ok(Self::TwinFeelers),
            "beanie" => Ok(Self::Beanie),
            "crown" => Ok(Self::Crown),
            "halo" => Ok(Self::Halo),
            "curl_tuft" => Ok(Self::CurlTuft),
            "party_cone" => Ok(Self::PartyCone),
            "flower_stem" => Ok(Self::FlowerStem),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown topper style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EyeStyle {
    KawaiiSparkle,
    HappyArcs,
    WinkSparkle,
    StarryEyes,
    CuriousPupils,
    OvalShine,
    CozySmile,
    VisorEyes,
}

impl EyeStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "kawaii_sparkle" => Ok(Self::KawaiiSparkle),
            "happy_arcs" => Ok(Self::HappyArcs),
            "wink_sparkle" => Ok(Self::WinkSparkle),
            "starry_eyes" => Ok(Self::StarryEyes),
            "curious_pupils" => Ok(Self::CuriousPupils),
            "oval_shine" => Ok(Self::OvalShine),
            "cozy_smile" => Ok(Self::CozySmile),
            "visor_eyes" => Ok(Self::VisorEyes),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown eye style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AccessoryStyle {
    None,
    RoundGlasses,
    BrowBeans,
    ForeheadStar,
}

impl AccessoryStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "none" => Ok(Self::None),
            "round_glasses" => Ok(Self::RoundGlasses),
            "brow_beans" => Ok(Self::BrowBeans),
            "forehead_star" => Ok(Self::ForeheadStar),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown accessory style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CheekStyle {
    OvalBlush,
    SlashBlush,
    FreckleBlush,
}

impl CheekStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "oval_blush" => Ok(Self::OvalBlush),
            "slash_blush" => Ok(Self::SlashBlush),
            "freckle_blush" => Ok(Self::FreckleBlush),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown cheek style: {other}"
            ))),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MouthStyle {
    OpenLaugh,
    SmileCurve,
    CatMouth,
    BlepTongue,
    LittleO,
    ToothyGrin,
    CheerfulV,
    SmirkGrin,
}

impl MouthStyle {
    pub fn parse(s: &str) -> Result<Self, SocialImageError> {
        match s {
            "open_laugh" => Ok(Self::OpenLaugh),
            "smile_curve" => Ok(Self::SmileCurve),
            "cat_mouth" => Ok(Self::CatMouth),
            "blep_tongue" => Ok(Self::BlepTongue),
            "little_o" => Ok(Self::LittleO),
            "toothy_grin" => Ok(Self::ToothyGrin),
            "cheerful_v" => Ok(Self::CheerfulV),
            "smirk_grin" => Ok(Self::SmirkGrin),
            other => Err(SocialImageError::InvalidImage(format!(
                "unknown mouth style: {other}"
            ))),
        }
    }
}

/// Complete resolved traits for a procedural user profile avatar.
#[derive(Clone, Debug)]
pub struct ProfileAvatarTraits<'a> {
    pub palette: AvatarPalette<'a>,
    pub backdrop: BackdropStyle,
    pub outfit: OutfitStyle,
    pub arm: ArmStyle,
    pub head: HeadStyle,
    pub topper: TopperStyle,
    pub eyes: EyeStyle,
    pub accessory: AccessoryStyle,
    pub cheeks: CheekStyle,
    pub mouth: MouthStyle,
}

impl<'a> ProfileAvatarTraits<'a> {
    /// Parses a flat 18-element slice `[bg, halo, sparkle, shadow, body, shirt, trim, accent,
    /// cheek, backdrop, outfit, arm, head, topper, eyes, accessory, cheeks, mouth]`.
    pub fn from_flat_strings(fields: &[&'a str]) -> Result<Self, SocialImageError> {
        if fields.len() != 18 {
            return Err(SocialImageError::InvalidImage(format!(
                "expected 18 profile avatar trait strings, got {}",
                fields.len()
            )));
        }
        Ok(Self {
            palette: AvatarPalette {
                bg: fields[0],
                halo: fields[1],
                sparkle: fields[2],
                shadow: fields[3],
                body: fields[4],
                shirt: fields[5],
                trim: fields[6],
                accent: fields[7],
                cheek: fields[8],
            },
            backdrop: BackdropStyle::parse(fields[9])?,
            outfit: OutfitStyle::parse(fields[10])?,
            arm: ArmStyle::parse(fields[11])?,
            head: HeadStyle::parse(fields[12])?,
            topper: TopperStyle::parse(fields[13])?,
            eyes: EyeStyle::parse(fields[14])?,
            accessory: AccessoryStyle::parse(fields[15])?,
            cheeks: CheekStyle::parse(fields[16])?,
            mouth: MouthStyle::parse(fields[17])?,
        })
    }
}

#[derive(Clone, Copy)]
struct ResolvedPalette {
    bg: Rgba,
    halo: Rgba,
    sparkle: Rgba,
    shadow: Rgba,
    body: Rgba,
    shirt: Rgba,
    trim: Rgba,
    accent: Rgba,
    cheek: Rgba,
    ink: Rgba,
    white: Rgba,
    rose_500: Rgba,
    rose_400: Rgba,
}

fn parse_color(hex: &str) -> Result<Rgba, SocialImageError> {
    Rgba::parse(hex).ok_or_else(|| SocialImageError::InvalidColor(hex.to_owned()))
}

impl ResolvedPalette {
    fn from_palette(p: &AvatarPalette<'_>) -> Result<Self, SocialImageError> {
        Ok(Self {
            bg: parse_color(p.bg)?,
            halo: parse_color(p.halo)?,
            sparkle: parse_color(p.sparkle)?,
            shadow: parse_color(p.shadow)?,
            body: parse_color(p.body)?,
            shirt: parse_color(p.shirt)?,
            trim: parse_color(p.trim)?,
            accent: parse_color(p.accent)?,
            cheek: parse_color(p.cheek)?,
            ink: parse_color(INK_HEX)?,
            white: Rgba::WHITE,
            rose_500: parse_color("#f43f5e")?,
            rose_400: parse_color("#fb7185")?,
        })
    }
}

/// Mirrors `MiniMagick::Tool::Convert`'s stateful `-fill`, `-stroke`, and `-strokewidth` settings.
struct AvatarPainter {
    canvas: Canvas,
    fill: Option<Rgba>,
    stroke: Option<Rgba>,
    stroke_width: f64,
}

impl AvatarPainter {
    fn new(bg: Rgba) -> Self {
        Self {
            canvas: Canvas::new(AVATAR_SIZE, AVATAR_SIZE, bg),
            fill: Some(Rgba::BLACK),
            stroke: None,
            stroke_width: 1.0,
        }
    }

    #[inline]
    fn set_fill(&mut self, c: Option<Rgba>) {
        self.fill = c;
    }

    #[inline]
    fn set_stroke(&mut self, c: Option<Rgba>) {
        self.stroke = c;
    }

    #[inline]
    fn set_stroke_width(&mut self, w: f64) {
        self.stroke_width = w;
    }

    fn draw_shape(&mut self, sub: &Subpath) {
        draw_primitive_styled(
            &mut self.canvas,
            sub,
            self.fill,
            self.stroke,
            StrokeStyle::butt_miter(self.stroke_width),
        );
    }

    fn draw_circle(&mut self, cx: f64, cy: f64, ex: f64, ey: f64) {
        self.draw_shape(&circle(Point::new(cx, cy), Point::new(ex, ey)));
    }

    fn draw_ellipse(&mut self, cx: f64, cy: f64, rx: f64, ry: f64) {
        self.draw_shape(&ellipse(Point::new(cx, cy), Point::new(rx, ry)));
    }

    fn draw_round_rect(&mut self, x0: f64, y0: f64, x1: f64, y1: f64, rx: f64, ry: f64) {
        self.draw_shape(&round_rectangle(
            Point::new(x0, y0),
            Point::new(x1, y1),
            Point::new(rx, ry),
        ));
    }

    fn draw_line(&mut self, x0: f64, y0: f64, x1: f64, y1: f64) {
        self.draw_shape(&line(Point::new(x0, y0), Point::new(x1, y1)));
    }

    fn draw_polygon_pts(&mut self, pts: &[(f64, f64)]) {
        let points: Vec<Point> = pts.iter().map(|&(x, y)| Point::new(x, y)).collect();
        self.draw_shape(&polygon(&points));
    }

    fn draw_path(&mut self, d: &str, cap: LineCap, join: LineJoin) {
        let subpaths = parse_svg_path(d);
        draw_subpaths_styled(
            &mut self.canvas,
            &subpaths,
            self.fill,
            self.stroke,
            StrokeStyle::new(self.stroke_width, cap, join),
            FillRule::EvenOdd,
        );
    }
}

fn four_point_star(cx: f64, cy: f64, r_out: f64, r_in: f64) -> String {
    format!(
        "M {cx},{top} Q {rx},{ty} {right},{cy} Q {rx},{by} {cx},{bot} Q {lx},{by} {left},{cy} Q {lx},{ty} {cx},{top} Z",
        top = cy - r_out,
        bot = cy + r_out,
        left = cx - r_out,
        right = cx + r_out,
        lx = cx - r_in,
        rx = cx + r_in,
        ty = cy - r_in,
        by = cy + r_in,
    )
}

fn five_point_star(cx: f64, cy: f64, r_out: f64, r_in: f64) -> String {
    let mut d = String::with_capacity(128);
    for i in 0..10 {
        let angle = (-90.0 + (i as f64 * 36.0)) * std::f64::consts::PI / 180.0;
        let radius = if i % 2 == 0 { r_out } else { r_in };
        let x = ((cx + radius * angle.cos()) * 10.0).round() / 10.0;
        let y = ((cy + radius * angle.sin()) * 10.0).round() / 10.0;
        if i == 0 {
            d.push_str(&format!("M {x},{y}"));
        } else {
            d.push_str(&format!(" L {x},{y}"));
        }
    }
    d.push_str(" Z");
    d
}

/// Renders `traits` into a `400x400` [`Canvas`].
pub fn render_profile_avatar_canvas(
    traits: &ProfileAvatarTraits<'_>,
) -> Result<Canvas, SocialImageError> {
    let pal = ResolvedPalette::from_palette(&traits.palette)?;
    let mut p = AvatarPainter::new(pal.bg);

    draw_backdrop(&mut p, traits.backdrop, &pal);
    draw_shadow(&mut p, traits.head, &pal);
    draw_arms(&mut p, traits.arm, &pal);
    draw_outfit(&mut p, traits.outfit, &pal);
    draw_behind_head_features(&mut p, traits.head, traits.topper, &pal);
    draw_head(&mut p, traits.head, &pal);
    draw_on_head_topper(&mut p, traits.topper, &pal);
    draw_cheeks(&mut p, traits.cheeks, &pal);
    draw_eyes(&mut p, traits.eyes, &pal);
    draw_accessory(&mut p, traits.accessory, &pal);
    draw_mouth(&mut p, traits.mouth, &pal);

    Ok(p.canvas)
}

/// Renders `traits` and encodes the resulting `400x400` 8-bit RGB PNG (stripped).
pub fn render_profile_avatar_png(
    traits: &ProfileAvatarTraits<'_>,
) -> Result<Vec<u8>, SocialImageError> {
    let canvas = render_profile_avatar_canvas(traits)?;
    encode_png(&canvas)
}

fn draw_backdrop(p: &mut AvatarPainter, style: BackdropStyle, pal: &ResolvedPalette) {
    p.set_stroke(None);
    p.set_fill(Some(pal.halo));
    p.draw_circle(200.0, 205.0, 200.0, 48.0);

    match style {
        BackdropStyle::Bubbles => {
            p.set_fill(Some(pal.sparkle));
            p.draw_circle(68.0, 95.0, 80.0, 95.0);
            p.draw_circle(332.0, 105.0, 342.0, 105.0);
            p.draw_circle(56.0, 245.0, 64.0, 245.0);
            p.draw_circle(344.0, 238.0, 351.0, 238.0);
            p.set_fill(Some(pal.white));
            p.draw_circle(92.0, 62.0, 98.0, 62.0);
            p.draw_circle(308.0, 68.0, 314.0, 68.0);
        }
        BackdropStyle::Sparkles => {
            p.set_fill(Some(pal.sparkle));
            p.draw_path(
                &four_point_star(72.0, 92.0, 16.0, 6.0),
                LineCap::Butt,
                LineJoin::Miter,
            );
            p.draw_path(
                &four_point_star(328.0, 98.0, 14.0, 5.0),
                LineCap::Butt,
                LineJoin::Miter,
            );
            p.set_fill(Some(pal.white));
            p.draw_path(
                &four_point_star(336.0, 225.0, 11.0, 4.0),
                LineCap::Butt,
                LineJoin::Miter,
            );
            p.draw_path(
                &four_point_star(64.0, 232.0, 11.0, 4.0),
                LineCap::Butt,
                LineJoin::Miter,
            );
            p.set_fill(Some(pal.sparkle));
            p.draw_circle(104.0, 58.0, 108.0, 58.0);
            p.draw_circle(296.0, 60.0, 300.0, 60.0);
        }
        BackdropStyle::Rings => {
            p.set_fill(None);
            p.set_stroke(Some(pal.sparkle));
            p.set_stroke_width(4.0);
            p.draw_circle(200.0, 205.0, 200.0, 32.0);
            p.set_stroke(None);
            p.set_fill(Some(pal.sparkle));
            p.draw_circle(70.0, 88.0, 78.0, 88.0);
            p.draw_circle(330.0, 130.0, 337.0, 130.0);
        }
        BackdropStyle::Confetti => {
            p.set_fill(Some(pal.sparkle));
            p.draw_round_rect(58.0, 84.0, 82.0, 96.0, 6.0, 6.0);
            p.draw_round_rect(318.0, 92.0, 342.0, 104.0, 6.0, 6.0);
            p.draw_polygon_pts(&[(68.0, 225.0), (80.0, 242.0), (56.0, 242.0)]);
            p.draw_polygon_pts(&[(334.0, 220.0), (346.0, 237.0), (322.0, 237.0)]);
            p.set_fill(Some(pal.white));
            p.draw_circle(96.0, 60.0, 103.0, 60.0);
            p.draw_circle(304.0, 64.0, 311.0, 64.0);
        }
        BackdropStyle::Clouds => {
            p.set_fill(Some(pal.white));
            p.draw_circle(68.0, 110.0, 86.0, 110.0);
            p.draw_circle(88.0, 104.0, 104.0, 104.0);
            p.draw_circle(106.0, 112.0, 120.0, 112.0);
            p.draw_circle(296.0, 102.0, 312.0, 102.0);
            p.draw_circle(316.0, 96.0, 332.0, 96.0);
            p.draw_circle(334.0, 104.0, 348.0, 104.0);
        }
        BackdropStyle::Planets => {
            p.set_fill(Some(pal.sparkle));
            p.draw_circle(72.0, 96.0, 86.0, 96.0);
            p.set_fill(None);
            p.set_stroke(Some(pal.white));
            p.set_stroke_width(4.0);
            p.draw_ellipse(72.0, 96.0, 24.0, 7.0);
            p.set_stroke(None);
            p.set_fill(Some(pal.white));
            p.draw_circle(330.0, 96.0, 338.0, 96.0);
            p.set_fill(Some(pal.sparkle));
            p.draw_circle(340.0, 232.0, 347.0, 232.0);
        }
    }
}

fn draw_shadow(p: &mut AvatarPainter, head: HeadStyle, pal: &ResolvedPalette) {
    p.set_stroke(None);
    p.set_fill(Some(pal.shadow));
    p.draw_path(
        "M 103,410 C 103,288 145,250 208,250 C 271,250 313,288 313,410 Z",
        LineCap::Butt,
        LineJoin::Miter,
    );
    if matches!(head, HeadStyle::Mochi | HeadStyle::PearBean) {
        p.draw_ellipse(207.0, 190.0, 92.0, 74.0);
    } else {
        p.draw_round_rect(117.0, 115.0, 297.0, 264.0, 56.0, 56.0);
    }
}

fn draw_arms(p: &mut AvatarPainter, arm: ArmStyle, pal: &ResolvedPalette) {
    if arm == ArmStyle::None {
        return;
    }
    p.set_stroke(Some(pal.ink));
    p.set_stroke_width(9.0);
    p.set_fill(Some(pal.body));
    if matches!(arm, ArmStyle::LeftWave | ArmStyle::BothCheering) {
        p.draw_path(
            "M 118,295 C 68,270 54,224 78,206 C 94,194 114,226 128,268 Z",
            LineCap::Round,
            LineJoin::Round,
        );
    }
    if matches!(arm, ArmStyle::RightWave | ArmStyle::BothCheering) {
        p.draw_path(
            "M 282,295 C 332,270 346,224 322,206 C 306,194 286,226 272,268 Z",
            LineCap::Round,
            LineJoin::Round,
        );
    }
}

fn draw_collar(p: &mut AvatarPainter, color: Rgba) {
    p.set_fill(Some(color));
    p.draw_path(
        "M 152,254 Q 200,294 248,254 Q 225,242 200,242 Q 175,242 152,254 Z",
        LineCap::Butt,
        LineJoin::Round,
    );
}

fn draw_outfit(p: &mut AvatarPainter, outfit: OutfitStyle, pal: &ResolvedPalette) {
    p.set_stroke(Some(pal.ink));
    p.set_stroke_width(9.0);
    p.set_fill(Some(if outfit == OutfitStyle::Overalls {
        pal.trim
    } else {
        pal.shirt
    }));
    p.draw_path(
        "M 95,410 C 95,282 140,242 200,242 C 260,242 305,282 305,410 Z",
        LineCap::Round,
        LineJoin::Round,
    );

    match outfit {
        OutfitStyle::CrewSweater => draw_collar(p, pal.trim),
        OutfitStyle::Hoodie => {
            p.set_fill(Some(pal.trim));
            p.draw_path(
                "M 142,256 Q 200,302 258,256 Q 230,242 200,242 Q 170,242 142,256 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_fill(None);
            p.set_stroke_width(7.0);
            p.draw_path("M 176,276 L 176,332", LineCap::Round, LineJoin::Miter);
            p.draw_path("M 224,276 L 224,332", LineCap::Round, LineJoin::Miter);
            p.set_fill(Some(pal.accent));
            p.set_stroke_width(6.0);
            p.draw_circle(176.0, 336.0, 176.0, 328.0);
            p.draw_circle(224.0, 336.0, 224.0, 328.0);
        }
        OutfitStyle::Overalls => {
            p.set_fill(Some(pal.shirt));
            p.draw_path(
                "M 146,250 L 168,250 L 168,325 L 232,325 L 232,250 L 254,250 L 262,410 L 138,410 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_fill(Some(pal.accent));
            p.set_stroke_width(6.0);
            p.draw_circle(157.0, 308.0, 157.0, 299.0);
            p.draw_circle(243.0, 308.0, 243.0, 299.0);
        }
        OutfitStyle::StripedTee => {
            p.set_fill(Some(pal.trim));
            p.draw_path(
                "M 108,315 L 292,315 L 298,348 L 102,348 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            draw_collar(p, pal.trim);
        }
        OutfitStyle::StarSweater => {
            draw_collar(p, pal.trim);
            p.set_fill(Some(pal.accent));
            p.set_stroke_width(6.0);
            p.draw_path(
                &five_point_star(200.0, 336.0, 26.0, 12.0),
                LineCap::Butt,
                LineJoin::Round,
            );
        }
        OutfitStyle::Bandana => {
            p.set_fill(Some(pal.accent));
            p.draw_path(
                "M 136,252 L 200,326 L 264,252 Q 232,242 200,242 Q 168,242 136,252 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
        }
    }
}

fn draw_behind_head_features(
    p: &mut AvatarPainter,
    head: HeadStyle,
    topper: TopperStyle,
    pal: &ResolvedPalette,
) {
    p.set_stroke(Some(pal.ink));
    p.set_stroke_width(9.0);

    match head {
        HeadStyle::BearCub => {
            p.set_fill(Some(pal.body));
            p.draw_circle(126.0, 116.0, 126.0, 84.0);
            p.draw_circle(274.0, 116.0, 274.0, 84.0);
            p.set_stroke(None);
            p.set_fill(Some(pal.cheek));
            p.draw_circle(126.0, 116.0, 126.0, 98.0);
            p.draw_circle(274.0, 116.0, 274.0, 98.0);
        }
        HeadStyle::KittyEars => {
            p.set_fill(Some(pal.body));
            p.draw_path(
                "M 114,148 L 104,76 L 168,112 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.draw_path(
                "M 286,148 L 296,76 L 232,112 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_stroke(None);
            p.set_fill(Some(pal.cheek));
            p.draw_polygon_pts(&[(122.0, 132.0), (116.0, 94.0), (152.0, 114.0)]);
            p.draw_polygon_pts(&[(278.0, 132.0), (284.0, 94.0), (248.0, 114.0)]);
        }
        HeadStyle::BunnyEars => {
            p.set_fill(Some(pal.body));
            p.draw_path(
                "M 126,120 C 116,42 160,42 158,118 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.draw_path(
                "M 274,120 C 284,42 240,42 242,118 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_stroke(None);
            p.set_fill(Some(pal.cheek));
            p.draw_ellipse(140.0, 84.0, 8.0, 22.0);
            p.draw_ellipse(260.0, 84.0, 8.0, 22.0);
        }
        HeadStyle::RetroBot => {
            p.set_fill(Some(pal.accent));
            p.draw_round_rect(92.0, 150.0, 116.0, 188.0, 8.0, 8.0);
            p.draw_round_rect(284.0, 150.0, 308.0, 188.0, 8.0, 8.0);
        }
        _ => {}
    }

    p.set_stroke(Some(pal.ink));
    p.set_stroke_width(9.0);

    match topper {
        TopperStyle::Sprout => {
            p.set_fill(None);
            p.draw_path("M 200,114 L 200,72", LineCap::Round, LineJoin::Miter);
            p.set_fill(Some(pal.accent));
            p.draw_path(
                "M 200,72 C 166,50 148,78 180,90 C 192,94 200,82 200,72 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.draw_path(
                "M 200,72 C 234,50 252,78 220,90 C 208,94 200,82 200,72 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
        }
        TopperStyle::Antenna => {
            p.set_fill(None);
            p.draw_path("M 200,114 L 200,66", LineCap::Round, LineJoin::Miter);
            p.set_fill(Some(pal.accent));
            p.draw_circle(200.0, 56.0, 200.0, 38.0);
            p.set_stroke(None);
            p.set_fill(Some(pal.white));
            p.draw_circle(195.0, 51.0, 195.0, 46.0);
        }
        TopperStyle::TwinFeelers => {
            p.set_fill(None);
            p.draw_path("M 178,114 Q 162,74 146,64", LineCap::Round, LineJoin::Miter);
            p.draw_path("M 222,114 Q 238,74 254,64", LineCap::Round, LineJoin::Miter);
            p.set_fill(Some(pal.accent));
            p.draw_circle(144.0, 62.0, 144.0, 49.0);
            p.draw_circle(256.0, 62.0, 256.0, 49.0);
        }
        TopperStyle::FlowerStem => {
            p.set_fill(None);
            p.draw_path("M 200,114 L 200,72", LineCap::Round, LineJoin::Miter);
            p.set_fill(Some(pal.trim));
            for (fx, fy) in [(184.0, 64.0), (216.0, 64.0), (200.0, 48.0), (200.0, 80.0)] {
                p.draw_circle(fx, fy, fx, fy - 12.0);
            }
            p.set_fill(Some(pal.accent));
            p.draw_circle(200.0, 64.0, 200.0, 53.0);
        }
        _ => {}
    }
}

fn draw_head(p: &mut AvatarPainter, head: HeadStyle, pal: &ResolvedPalette) {
    p.set_stroke(Some(pal.ink));
    p.set_stroke_width(9.0);
    p.set_fill(Some(pal.body));

    match head {
        HeadStyle::Squircle | HeadStyle::BearCub | HeadStyle::KittyEars | HeadStyle::BunnyEars => {
            p.draw_round_rect(110.0, 108.0, 290.0, 258.0, 56.0, 56.0);
        }
        HeadStyle::Mochi => {
            p.draw_path(
                "M 104,190 C 104,118 144,106 200,106 C 256,106 296,118 296,190 C 296,248 258,260 200,260 C 142,260 104,248 104,190 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
        }
        HeadStyle::CloudPuff => {
            p.draw_path(
                "M 112,186 C 96,162 110,128 138,124 C 152,98 188,96 200,110 C 212,96 248,98 262,124 C 290,128 304,162 288,186 C 302,216 282,250 252,252 C 232,266 168,266 148,252 C 118,250 98,216 112,186 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
        }
        HeadStyle::RetroBot => {
            p.draw_round_rect(110.0, 108.0, 290.0, 258.0, 38.0, 38.0);
            p.set_stroke_width(6.0);
            p.set_fill(Some(pal.bg));
            p.draw_round_rect(128.0, 128.0, 272.0, 240.0, 24.0, 24.0);
        }
        HeadStyle::PearBean => {
            p.draw_path(
                "M 122,154 C 122,112 154,104 200,104 C 246,104 278,112 278,154 C 298,192 296,258 200,258 C 104,258 102,192 122,154 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
        }
    }

    if head == HeadStyle::RetroBot {
        return;
    }

    p.set_fill(None);
    p.set_stroke(Some(pal.white));
    p.set_stroke_width(7.0);
    p.draw_path(
        "M 134,142 Q 144,124 168,124",
        LineCap::Round,
        LineJoin::Miter,
    );
}

fn draw_on_head_topper(p: &mut AvatarPainter, topper: TopperStyle, pal: &ResolvedPalette) {
    p.set_stroke(Some(pal.ink));
    p.set_stroke_width(9.0);

    match topper {
        TopperStyle::Beanie => {
            p.set_fill(Some(pal.accent));
            p.draw_path(
                "M 120,132 C 124,78 276,78 280,132 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_fill(Some(pal.shirt));
            p.draw_round_rect(114.0, 118.0, 286.0, 142.0, 12.0, 12.0);
            p.set_fill(Some(pal.trim));
            p.draw_circle(200.0, 72.0, 200.0, 54.0);
        }
        TopperStyle::Crown => {
            p.set_fill(Some(pal.accent));
            p.draw_path(
                "M 164,112 L 158,70 L 182,90 L 200,62 L 218,90 L 242,70 L 236,112 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
        }
        TopperStyle::Halo => {
            p.set_fill(None);
            p.set_stroke(Some(pal.accent));
            p.set_stroke_width(11.0);
            p.draw_ellipse(200.0, 68.0, 48.0, 13.0);
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(4.0);
            p.draw_ellipse(200.0, 68.0, 52.0, 16.0);
        }
        TopperStyle::CurlTuft => {
            p.set_fill(Some(pal.body));
            p.draw_path(
                "M 184,112 C 176,72 218,62 222,88 C 224,102 206,108 198,98",
                LineCap::Round,
                LineJoin::Round,
            );
        }
        TopperStyle::PartyCone => {
            p.set_fill(Some(pal.accent));
            p.draw_path(
                "M 164,110 L 200,48 L 236,110 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_fill(Some(pal.trim));
            p.draw_circle(200.0, 44.0, 200.0, 31.0);
        }
        _ => {}
    }
}

fn draw_cheeks(p: &mut AvatarPainter, style: CheekStyle, pal: &ResolvedPalette) {
    p.set_stroke(None);
    p.set_fill(Some(pal.cheek));
    p.draw_ellipse(146.0, 204.0, 14.0, 9.0);
    p.draw_ellipse(254.0, 204.0, 14.0, 9.0);

    match style {
        CheekStyle::OvalBlush => {}
        CheekStyle::SlashBlush => {
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(3.0);
            p.draw_line(141.0, 200.0, 147.0, 208.0);
            p.draw_line(148.0, 200.0, 154.0, 208.0);
            p.draw_line(247.0, 200.0, 253.0, 208.0);
            p.draw_line(254.0, 200.0, 260.0, 208.0);
        }
        CheekStyle::FreckleBlush => {
            p.set_fill(Some(pal.ink));
            p.draw_circle(142.0, 192.0, 142.0, 189.0);
            p.draw_circle(151.0, 194.0, 151.0, 191.0);
            p.draw_circle(249.0, 194.0, 249.0, 191.0);
            p.draw_circle(258.0, 192.0, 258.0, 189.0);
        }
    }
}

fn draw_eyes(p: &mut AvatarPainter, style: EyeStyle, pal: &ResolvedPalette) {
    match style {
        EyeStyle::KawaiiSparkle => {
            p.set_stroke(None);
            p.set_fill(Some(pal.ink));
            p.draw_circle(162.0, 178.0, 162.0, 162.0);
            p.draw_circle(238.0, 178.0, 238.0, 162.0);
            p.set_fill(Some(pal.white));
            p.draw_circle(157.0, 173.0, 157.0, 167.0);
            p.draw_circle(233.0, 173.0, 233.0, 167.0);
            p.draw_circle(167.0, 183.0, 167.0, 180.0);
            p.draw_circle(243.0, 183.0, 243.0, 180.0);
        }
        EyeStyle::HappyArcs => {
            p.set_fill(None);
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(8.0);
            p.draw_path(
                "M 146,182 Q 162,160 178,182",
                LineCap::Round,
                LineJoin::Miter,
            );
            p.draw_path(
                "M 222,182 Q 238,160 254,182",
                LineCap::Round,
                LineJoin::Miter,
            );
        }
        EyeStyle::WinkSparkle => {
            p.set_stroke(None);
            p.set_fill(Some(pal.ink));
            p.draw_circle(162.0, 178.0, 162.0, 162.0);
            p.set_fill(Some(pal.white));
            p.draw_circle(157.0, 173.0, 157.0, 167.0);
            p.draw_circle(167.0, 183.0, 167.0, 180.0);
            p.set_fill(None);
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(8.0);
            p.draw_path(
                "M 222,168 L 244,178 L 222,188",
                LineCap::Round,
                LineJoin::Round,
            );
        }
        EyeStyle::StarryEyes => {
            p.set_stroke(None);
            p.set_fill(Some(pal.ink));
            p.draw_circle(162.0, 178.0, 162.0, 161.0);
            p.draw_circle(238.0, 178.0, 238.0, 161.0);
            p.set_fill(Some(pal.white));
            p.draw_path(
                &four_point_star(160.0, 176.0, 9.0, 3.0),
                LineCap::Butt,
                LineJoin::Miter,
            );
            p.draw_path(
                &four_point_star(236.0, 176.0, 9.0, 3.0),
                LineCap::Butt,
                LineJoin::Miter,
            );
        }
        EyeStyle::CuriousPupils => {
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(6.0);
            p.set_fill(Some(pal.white));
            p.draw_circle(162.0, 178.0, 162.0, 161.0);
            p.draw_circle(238.0, 178.0, 238.0, 161.0);
            p.set_stroke(None);
            p.set_fill(Some(pal.ink));
            p.draw_circle(166.0, 178.0, 166.0, 168.0);
            p.draw_circle(234.0, 178.0, 234.0, 168.0);
            p.set_fill(Some(pal.white));
            p.draw_circle(163.0, 174.0, 163.0, 171.0);
            p.draw_circle(231.0, 174.0, 231.0, 171.0);
        }
        EyeStyle::OvalShine => {
            p.set_stroke(None);
            p.set_fill(Some(pal.ink));
            p.draw_ellipse(162.0, 178.0, 12.0, 17.0);
            p.draw_ellipse(238.0, 178.0, 12.0, 17.0);
            p.set_fill(Some(pal.white));
            p.draw_ellipse(158.0, 171.0, 5.0, 6.0);
            p.draw_ellipse(234.0, 171.0, 5.0, 6.0);
        }
        EyeStyle::CozySmile => {
            p.set_fill(None);
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(8.0);
            p.draw_path(
                "M 146,178 C 152,164 172,164 178,178",
                LineCap::Round,
                LineJoin::Miter,
            );
            p.draw_path(
                "M 222,178 C 228,164 248,164 254,178",
                LineCap::Round,
                LineJoin::Miter,
            );
            p.set_stroke_width(6.0);
            p.draw_path("M 142,174 L 136,168", LineCap::Round, LineJoin::Miter);
            p.draw_path("M 258,174 L 264,168", LineCap::Round, LineJoin::Miter);
        }
        EyeStyle::VisorEyes => {
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(7.0);
            p.set_fill(Some(pal.accent));
            p.draw_round_rect(136.0, 162.0, 264.0, 192.0, 15.0, 15.0);
            p.set_stroke(None);
            p.set_fill(Some(pal.white));
            p.draw_round_rect(148.0, 168.0, 178.0, 175.0, 3.0, 3.0);
        }
    }
}

fn draw_accessory(p: &mut AvatarPainter, style: AccessoryStyle, pal: &ResolvedPalette) {
    match style {
        AccessoryStyle::None => {}
        AccessoryStyle::RoundGlasses => {
            p.set_fill(None);
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(6.0);
            p.draw_circle(162.0, 178.0, 162.0, 154.0);
            p.draw_circle(238.0, 178.0, 238.0, 154.0);
            p.draw_line(186.0, 178.0, 214.0, 178.0);
        }
        AccessoryStyle::BrowBeans => {
            p.set_stroke(None);
            p.set_fill(Some(pal.ink));
            p.draw_round_rect(148.0, 148.0, 174.0, 156.0, 4.0, 4.0);
            p.draw_round_rect(226.0, 148.0, 252.0, 156.0, 4.0, 4.0);
        }
        AccessoryStyle::ForeheadStar => {
            p.set_stroke(Some(pal.ink));
            p.set_stroke_width(4.0);
            p.set_fill(Some(pal.accent));
            p.draw_path(
                &four_point_star(200.0, 144.0, 12.0, 5.0),
                LineCap::Butt,
                LineJoin::Miter,
            );
        }
    }
}

fn draw_mouth(p: &mut AvatarPainter, style: MouthStyle, pal: &ResolvedPalette) {
    p.set_stroke(Some(pal.ink));
    p.set_stroke_width(7.0);

    match style {
        MouthStyle::OpenLaugh => {
            p.set_fill(Some(pal.rose_500));
            p.draw_path(
                "M 182,198 L 218,198 C 218,226 182,226 182,198 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
        }
        MouthStyle::SmileCurve => {
            p.set_fill(None);
            p.draw_path(
                "M 183,200 Q 200,218 217,200",
                LineCap::Round,
                LineJoin::Miter,
            );
        }
        MouthStyle::CatMouth => {
            p.set_fill(None);
            p.draw_path(
                "M 178,200 Q 189,215 200,200 Q 211,215 222,200",
                LineCap::Round,
                LineJoin::Round,
            );
        }
        MouthStyle::BlepTongue => {
            p.set_fill(Some(pal.rose_400));
            p.draw_path(
                "M 194,204 C 194,226 216,226 216,204 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_fill(None);
            p.draw_path(
                "M 182,200 Q 200,214 218,200",
                LineCap::Round,
                LineJoin::Miter,
            );
        }
        MouthStyle::LittleO => {
            p.set_fill(Some(pal.rose_500));
            p.draw_ellipse(200.0, 208.0, 9.0, 11.0);
        }
        MouthStyle::ToothyGrin => {
            p.set_fill(Some(pal.rose_500));
            p.draw_path(
                "M 180,196 L 220,196 C 220,224 180,224 180,196 Z",
                LineCap::Butt,
                LineJoin::Round,
            );
            p.set_fill(Some(pal.white));
            p.set_stroke_width(5.0);
            p.draw_round_rect(193.0, 196.0, 207.0, 207.0, 3.0, 3.0);
        }
        MouthStyle::CheerfulV => {
            p.set_fill(None);
            p.draw_path(
                "M 185,198 L 200,214 L 215,198",
                LineCap::Round,
                LineJoin::Round,
            );
        }
        MouthStyle::SmirkGrin => {
            p.set_fill(None);
            p.draw_path(
                "M 183,204 Q 202,216 218,196",
                LineCap::Round,
                LineJoin::Miter,
            );
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::social_image::decode_image;

    fn sample_palette() -> AvatarPalette<'static> {
        AvatarPalette {
            bg: "#fef3c7",
            halo: "#fde68a",
            sparkle: "#f59e0b",
            shadow: "#d97706",
            body: "#38bdf8",
            shirt: "#ec4899",
            trim: "#fbcfe8",
            accent: "#34d399",
            cheek: "#fb7185",
        }
    }

    #[test]
    fn renders_all_trait_variants_into_valid_400x400_pngs() {
        let backdrops = [
            BackdropStyle::Bubbles,
            BackdropStyle::Sparkles,
            BackdropStyle::Rings,
            BackdropStyle::Confetti,
            BackdropStyle::Clouds,
            BackdropStyle::Planets,
        ];
        let outfits = [
            OutfitStyle::CrewSweater,
            OutfitStyle::Hoodie,
            OutfitStyle::Overalls,
            OutfitStyle::StripedTee,
            OutfitStyle::StarSweater,
            OutfitStyle::Bandana,
        ];
        let arms = [
            ArmStyle::None,
            ArmStyle::LeftWave,
            ArmStyle::RightWave,
            ArmStyle::BothCheering,
        ];
        let heads = [
            HeadStyle::Squircle,
            HeadStyle::Mochi,
            HeadStyle::BearCub,
            HeadStyle::KittyEars,
            HeadStyle::BunnyEars,
            HeadStyle::CloudPuff,
            HeadStyle::RetroBot,
            HeadStyle::PearBean,
        ];
        let toppers = [
            TopperStyle::Sprout,
            TopperStyle::Antenna,
            TopperStyle::TwinFeelers,
            TopperStyle::Beanie,
            TopperStyle::Crown,
            TopperStyle::Halo,
            TopperStyle::CurlTuft,
            TopperStyle::PartyCone,
            TopperStyle::FlowerStem,
        ];
        let eyes = [
            EyeStyle::KawaiiSparkle,
            EyeStyle::HappyArcs,
            EyeStyle::WinkSparkle,
            EyeStyle::StarryEyes,
            EyeStyle::CuriousPupils,
            EyeStyle::OvalShine,
            EyeStyle::CozySmile,
            EyeStyle::VisorEyes,
        ];
        let accessories = [
            AccessoryStyle::None,
            AccessoryStyle::RoundGlasses,
            AccessoryStyle::BrowBeans,
            AccessoryStyle::ForeheadStar,
        ];
        let cheeks = [
            CheekStyle::OvalBlush,
            CheekStyle::SlashBlush,
            CheekStyle::FreckleBlush,
        ];
        let mouths = [
            MouthStyle::OpenLaugh,
            MouthStyle::SmileCurve,
            MouthStyle::CatMouth,
            MouthStyle::BlepTongue,
            MouthStyle::LittleO,
            MouthStyle::ToothyGrin,
            MouthStyle::CheerfulV,
            MouthStyle::SmirkGrin,
        ];

        // Sweep through every single enum variant at least once.
        for i in 0..toppers.len() {
            let traits = ProfileAvatarTraits {
                palette: sample_palette(),
                backdrop: backdrops[i % backdrops.len()],
                outfit: outfits[i % outfits.len()],
                arm: arms[i % arms.len()],
                head: heads[i % heads.len()],
                topper: toppers[i % toppers.len()],
                eyes: eyes[i % eyes.len()],
                accessory: accessories[i % accessories.len()],
                cheeks: cheeks[i % cheeks.len()],
                mouth: mouths[i % mouths.len()],
            };
            let png = render_profile_avatar_png(&traits).unwrap();
            assert!(png.starts_with(b"\x89PNG\r\n\x1a\n"));
            let decoded = decode_image(&png).unwrap();
            assert_eq!(decoded.width, 400);
            assert_eq!(decoded.height, 400);
            assert!(!decoded.has_alpha);
        }
    }
}
