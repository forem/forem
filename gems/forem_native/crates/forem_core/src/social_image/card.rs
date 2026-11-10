//! Card layout: the browser-window frames drawn by `draw_window` /
//! `draw_profile_window` in `Images::GenerateSocialImageMagickally`, using the same
//! constants and drawing order as the original `mogrify -draw` commands.

use super::canvas::{Canvas, Rgba};
use super::decode::would_encode_as_pseudo_png;
use super::draw::{circle, draw_primitive, ellipse, line, rectangle, round_rectangle, Point};
use super::filter::{blur_gaussian, resize, resize_fit, resize_to_height, ResizeFilter};
use super::text::{draw_text_northwest, render_caption_to_fit, Font};

pub const WIDTH: usize = 1200;
pub const HEIGHT: usize = 627;
pub const X_KEEP_CLEAR: i64 = 80;

pub const MESH_WIDTH: usize = 400;
pub const MESH_HEIGHT: usize = 209;
pub const MESH_BLUR_SIGMA: f64 = 48.0;

pub const WINDOW_WIDTH: i64 = 966;
pub const WINDOW_STACK_OFFSET: i64 = 14;
pub const WINDOW_STACK_DEPTH: i64 = 2;
pub const WINDOW_HEIGHT: i64 =
    HEIGHT as i64 - (2 * X_KEEP_CLEAR) - (WINDOW_STACK_OFFSET * WINDOW_STACK_DEPTH);
pub const WINDOW_RADIUS: f64 = 18.0;
pub const WINDOW_STROKE: f64 = 4.0;
pub const WINDOW_BAR_HEIGHT: i64 = 46;
pub const WINDOW_X: i64 =
    (WIDTH as i64 - WINDOW_WIDTH - (WINDOW_STACK_OFFSET * WINDOW_STACK_DEPTH)) / 2;
pub const WINDOW_Y: i64 = X_KEEP_CLEAR;

pub const LOGO_HEIGHT: usize = 30;
pub const QUOTE_MARK_POINTSIZE: f64 = 150.0;
pub const QUOTE_LEFT: i64 = 110;
pub const QUOTE_WIDTH: usize = (WINDOW_WIDTH - 160) as usize;
pub const QUOTE_MAX_HEIGHT: i64 = WINDOW_HEIGHT - WINDOW_BAR_HEIGHT - 144;
pub const QUOTE_MAX_POINTSIZE: f64 = 54.0;
pub const QUOTE_MIN_POINTSIZE: f64 = 28.0;
pub const BYLINE_HEIGHT: i64 = 92;
pub const AVATAR_SIZE: usize = 64;
pub const NAME_POINTSIZE: f64 = 28.0;
pub const META_POINTSIZE: f64 = 22.0;

pub const PROFILE_STRIP_HEIGHT: i64 = 72;
pub const PROFILE_AVATAR_SIZE: usize = 112;
pub const PROFILE_NAME_MAX_POINTSIZE: f64 = 38.0;
pub const PROFILE_NAME_MIN_POINTSIZE: f64 = 24.0;
pub const PROFILE_HANDLE_POINTSIZE: f64 = 22.0;
pub const PROFILE_FOLLOW_WIDTH: i64 = 136;
pub const PROFILE_FOLLOW_HEIGHT: i64 = 46;
pub const PROFILE_FOLLOW_POINTSIZE: f64 = 21.0;
pub const PROFILE_BIO_WIDTH: usize = (WINDOW_WIDTH - 88) as usize;
pub const PROFILE_BIO_MAX_HEIGHT: i64 = 126;
pub const PROFILE_BIO_MAX_POINTSIZE: f64 = 34.0;
pub const PROFILE_BIO_MIN_POINTSIZE: f64 = 22.0;
pub const PROFILE_FOOTER_HEIGHT: i64 = 70;
pub const PROFILE_META_MAX_POINTSIZE: f64 = 22.0;
pub const PROFILE_META_MIN_POINTSIZE: f64 = 16.0;

pub const TEXT_COLOR: Rgba = Rgba::BLACK;
/// `#525252`
pub const SECONDARY_TEXT_COLOR: Rgba = Rgba::new(82.0 / 255.0, 82.0 / 255.0, 82.0 / 255.0, 1.0);
/// `#d8d8d8`
pub const DIVIDER_COLOR: Rgba = Rgba::new(216.0 / 255.0, 216.0 / 255.0, 216.0 / 255.0, 1.0);

fn pt(x: i64, y: i64) -> Point {
    Point::new(x as f64, y as f64)
}

fn rounded(x0: i64, y0: i64, x1: i64, y1: i64, r: f64) -> super::draw::Subpath {
    round_rectangle(pt(x0, y0), pt(x1, y1), Point::new(r, r))
}

/// `draw_window_stack`: the two offset outlines behind the window, then the window itself.
fn draw_window_stack(canvas: &mut Canvas, x0: i64, x1: i64, y1: i64) {
    for depth in (1..=WINDOW_STACK_DEPTH).rev() {
        let offset = depth * WINDOW_STACK_OFFSET;
        let shape = rounded(
            x0 + offset,
            WINDOW_Y + offset,
            x1 + offset,
            y1 + offset,
            WINDOW_RADIUS,
        );
        draw_primitive(
            canvas,
            &shape,
            Some(Rgba::WHITE),
            Some(TEXT_COLOR),
            WINDOW_STROKE,
        );
    }
    let shape = rounded(x0, WINDOW_Y, x1, y1, WINDOW_RADIUS);
    draw_primitive(
        canvas,
        &shape,
        Some(Rgba::WHITE),
        Some(TEXT_COLOR),
        WINDOW_STROKE,
    );
}

/// `draw_window_dots`: three title-bar dots (`circle` with fill only; the stroke is `none`).
fn draw_window_dots(canvas: &mut Canvas, right_x: i64, dot_y: i64, stroke_width: f64) {
    for i in 0..3 {
        let dot_x = right_x - 34 - (i * 22);
        draw_primitive(
            canvas,
            &circle(pt(dot_x, dot_y), pt(dot_x + 6, dot_y)),
            Some(TEXT_COLOR),
            None,
            stroke_width,
        );
    }
}

/// `draw_window`: the article card frame.
pub fn draw_window(canvas: &mut Canvas) {
    let x0 = WINDOW_X;
    let x1 = WINDOW_X + WINDOW_WIDTH;
    let y1 = WINDOW_Y + WINDOW_HEIGHT;
    let bar_y = WINDOW_Y + WINDOW_BAR_HEIGHT;
    let dot_y = WINDOW_Y + (WINDOW_BAR_HEIGHT / 2);

    // fill white, stroke black, strokewidth 4
    draw_window_stack(canvas, x0, x1, y1);
    draw_primitive(
        canvas,
        &line(pt(x0, bar_y), pt(x1, bar_y)),
        Some(Rgba::WHITE),
        Some(TEXT_COLOR),
        WINDOW_STROKE,
    );
    // stroke none, fill black (strokewidth stays 4)
    draw_window_dots(canvas, x1, dot_y, WINDOW_STROKE);
    // stroke divider, strokewidth 2 (fill is still black)
    let divider_y = y1 - BYLINE_HEIGHT - 14;
    draw_primitive(
        canvas,
        &line(pt(x0 + 40, divider_y), pt(x1 - 40, divider_y)),
        Some(TEXT_COLOR),
        Some(DIVIDER_COLOR),
        2.0,
    );
}

/// `draw_profile_window`: the profile card frame with the brand strip and Follow button.
pub fn draw_profile_window(canvas: &mut Canvas, brand: Rgba) {
    let x0 = WINDOW_X;
    let x1 = WINDOW_X + WINDOW_WIDTH;
    let y1 = WINDOW_Y + WINDOW_HEIGHT;
    let bar_y = WINDOW_Y + WINDOW_BAR_HEIGHT;
    let strip_y = bar_y + PROFILE_STRIP_HEIGHT;
    let btn_x1 = x1 - 44;
    let btn_x0 = btn_x1 - PROFILE_FOLLOW_WIDTH;
    let btn_y0 = strip_y + 18;
    let btn_y1 = btn_y0 + PROFILE_FOLLOW_HEIGHT;

    draw_window_stack(canvas, x0, x1, y1);
    // stroke none, fill brand (strokewidth 4)
    draw_primitive(
        canvas,
        &rectangle(pt(x0 + 2, bar_y), pt(x1 - 2, strip_y)),
        Some(brand),
        None,
        WINDOW_STROKE,
    );
    // draw_profile_window_borders: fill none, stroke black, strokewidth 4 then 3
    draw_primitive(
        canvas,
        &rounded(x0, WINDOW_Y, x1, y1, WINDOW_RADIUS),
        None,
        Some(TEXT_COLOR),
        WINDOW_STROKE,
    );
    draw_primitive(
        canvas,
        &line(pt(x0, bar_y), pt(x1, bar_y)),
        None,
        Some(TEXT_COLOR),
        WINDOW_STROKE,
    );
    draw_primitive(
        canvas,
        &line(pt(x0, strip_y), pt(x1, strip_y)),
        None,
        Some(TEXT_COLOR),
        3.0,
    );
    // draw_window_dots: stroke none, fill black (strokewidth 3)
    draw_window_dots(canvas, x1, WINDOW_Y + (WINDOW_BAR_HEIGHT / 2), 3.0);
    // Follow button shadow: still fill black, stroke none, strokewidth 3
    draw_primitive(
        canvas,
        &rounded(btn_x0 + 3, btn_y0 + 3, btn_x1 + 3, btn_y1 + 3, 10.0),
        Some(TEXT_COLOR),
        None,
        3.0,
    );
    // Follow button: fill brand, stroke black, strokewidth 3
    draw_primitive(
        canvas,
        &rounded(btn_x0, btn_y0, btn_x1, btn_y1, 10.0),
        Some(brand),
        Some(TEXT_COLOR),
        3.0,
    );
    // Footer divider: stroke divider, strokewidth 2 (fill is still brand)
    draw_primitive(
        canvas,
        &line(
            pt(x0 + 44, y1 - PROFILE_FOOTER_HEIGHT),
            pt(x1 - 44, y1 - PROFILE_FOOTER_HEIGHT),
        ),
        Some(brand),
        Some(DIVIDER_COLOR),
        2.0,
    );
}

/// One ellipse blob `(cx, cy, rx, ry, fill_color)` in `draw_background`.
#[derive(Clone, Copy, Debug)]
pub struct BackgroundBlob {
    pub x: i64,
    pub y: i64,
    pub rx: i64,
    pub ry: i64,
    pub color: Rgba,
}

/// `draw_background`: draws `blobs` on a `400x209` canvas filled with `base_color`,
/// applies `-blur 0x48`, and resizes to `1200x627!` with `-filter Gaussian`.
pub fn draw_background(base_color: Rgba, blobs: &[BackgroundBlob]) -> Canvas {
    let mut mesh = Canvas::new(MESH_WIDTH, MESH_HEIGHT, base_color);
    for blob in blobs {
        let shape = ellipse(pt(blob.x, blob.y), pt(blob.rx, blob.ry));
        draw_primitive(&mut mesh, &shape, Some(blob.color), None, 1.0);
    }
    let blurred = blur_gaussian(&mesh, MESH_BLUR_SIGMA);
    resize(&blurred, WIDTH, HEIGHT, ResizeFilter::Gaussian)
}

/// `add_logo`: resizes `logo` with geometry `"x30"` and composites it onto the title bar.
pub fn add_logo(canvas: &mut Canvas, logo: &Canvas) {
    let resized = resize_to_height(logo, LOGO_HEIGHT);
    let x = WINDOW_X + 18;
    let y = WINDOW_Y + ((WINDOW_BAR_HEIGHT - LOGO_HEIGHT as i64) / 2);
    canvas.composite_over(&resized, x, y);
}

/// `render_quote`: renders the opening article quote using `caption:` word-wrapping,
/// stepping down the pointsize until the height fits `QUOTE_MAX_HEIGHT`.
pub fn render_quote(bold_font: &Font<'_>, quote: &str) -> Canvas {
    let char_len = quote.chars().count();
    let start_ps = QUOTE_MAX_POINTSIZE
        - if char_len > 90 { 4.0 } else { 0.0 }
        - if char_len > 140 { 6.0 } else { 0.0 };
    render_caption_to_fit(
        bold_font,
        quote,
        start_ps,
        QUOTE_MIN_POINTSIZE,
        TEXT_COLOR,
        QUOTE_WIDTH,
        QUOTE_MAX_HEIGHT as usize,
        -4.0,
    )
}

/// `render_bio`: renders a user/organization profile bio using `caption:` word-wrapping.
pub fn render_bio(medium_font: &Font<'_>, bio: &str, color: Rgba) -> Canvas {
    let char_len = bio.chars().count();
    let start_ps = PROFILE_BIO_MAX_POINTSIZE - if char_len > 90 { 4.0 } else { 0.0 };
    render_caption_to_fit(
        medium_font,
        bio,
        start_ps,
        PROFILE_BIO_MIN_POINTSIZE,
        color,
        PROFILE_BIO_WIDTH,
        PROFILE_BIO_MAX_HEIGHT as usize,
        -4.0,
    )
}

/// `add_quote`: draws the decorative `\u201C` quotation mark in `accent` and composites
/// `quote_image` vertically centered in the quote area.
pub fn add_quote(canvas: &mut Canvas, quote_image: &Canvas, bold_font: &Font<'_>, accent: Rgba) {
    let body_top = WINDOW_Y + WINDOW_BAR_HEIGHT;
    draw_text_northwest(
        canvas,
        bold_font,
        "\u{201C}",
        (WINDOW_X + 26) as f64,
        (body_top - 30) as f64,
        QUOTE_MARK_POINTSIZE,
        accent,
    );
    let quote_y = body_top + 24 + ((QUOTE_MAX_HEIGHT + 16 - quote_image.height as i64) / 2).max(0);
    canvas.composite_over(quote_image, WINDOW_X + QUOTE_LEFT, quote_y);
}

fn avatar_resize_filter(author_image: &Canvas) -> ResizeFilter {
    // In `GenerateSocialImageMagickally`, `@author_image.format("png")` ran before
    // `@author_image.resize`, turning <=256-color or grayscale images into `PseudoClass` PNGs.
    if author_image.has_alpha || author_image.is_pseudo || would_encode_as_pseudo_png(author_image)
    {
        ResizeFilter::Mitchell
    } else {
        ResizeFilter::Auto
    }
}

/// `add_profile_image`: resizes and masks the author avatar on an article card and draws
/// its 3px circular border.
pub fn add_profile_image(canvas: &mut Canvas, author_image: &Canvas, rounded_mask: &Canvas) {
    let x = WINDOW_X + 40;
    let y = WINDOW_Y + WINDOW_HEIGHT - BYLINE_HEIGHT;
    let filter = avatar_resize_filter(author_image);
    let resized_author = resize(author_image, AVATAR_SIZE, AVATAR_SIZE, filter);
    let resized_mask = resize_fit(rounded_mask, AVATAR_SIZE, AVATAR_SIZE);

    canvas.composite_over(&resized_author, x, y);
    canvas.composite_over(&resized_mask, x, y);

    let radius = (AVATAR_SIZE / 2) as i64;
    draw_primitive(
        canvas,
        &circle(pt(x + radius, y + radius), pt(x + radius, y - 1)),
        None,
        Some(TEXT_COLOR),
        3.0,
    );
}

/// `add_profile_card_avatar`: resizes and `DstOut`-masks the 112x112 profile card avatar,
/// draws the white halo ring, composites the circular avatar, and draws its 3px black border.
pub fn add_profile_card_avatar(canvas: &mut Canvas, author_image: &Canvas, rounded_mask: &Canvas) {
    let x = WINDOW_X + 44;
    let y = WINDOW_Y + WINDOW_BAR_HEIGHT + 18;
    let radius = (PROFILE_AVATAR_SIZE / 2) as i64;
    let cx = x + radius;
    let cy = y + radius;

    let filter = avatar_resize_filter(author_image);
    let mut circular_avatar = resize(
        author_image,
        PROFILE_AVATAR_SIZE,
        PROFILE_AVATAR_SIZE,
        filter,
    );
    let resized_mask = resize(
        rounded_mask,
        PROFILE_AVATAR_SIZE,
        PROFILE_AVATAR_SIZE,
        ResizeFilter::Auto,
    );
    circular_avatar.dst_out(&resized_mask);

    // White halo ring behind the avatar (`fill white, stroke none`).
    draw_primitive(
        canvas,
        &circle(pt(cx, cy), pt(cx, cy - radius - 6)),
        Some(Rgba::WHITE),
        None,
        1.0,
    );

    canvas.composite_over(&circular_avatar, x, y);

    // Black border ring (`fill none, stroke black, strokewidth 3`).
    draw_primitive(
        canvas,
        &circle(pt(cx, cy), pt(cx, cy - radius)),
        None,
        Some(TEXT_COLOR),
        3.0,
    );
}

/// `add_profile_header`: composites the name, `@handle`, and Follow button label onto a
/// profile card.
pub fn add_profile_header(
    canvas: &mut Canvas,
    name_image: &Canvas,
    handle_image: &Canvas,
    follow_image: &Canvas,
) {
    let strip_y = WINDOW_Y + WINDOW_BAR_HEIGHT + PROFILE_STRIP_HEIGHT;
    let text_x = WINDOW_X + 44 + PROFILE_AVATAR_SIZE as i64 + 22;
    let name_y = strip_y + 10;
    let handle_y = name_y + (name_image.height as i64 - 4).max(38);

    canvas.composite_over(name_image, text_x, name_y);
    canvas.composite_over(handle_image, text_x, handle_y);

    let btn_x0 = WINDOW_X + WINDOW_WIDTH - 44 - PROFILE_FOLLOW_WIDTH;
    let btn_y0 = strip_y + 18;
    let follow_x = btn_x0 + ((PROFILE_FOLLOW_WIDTH - follow_image.width as i64) / 2).max(8);
    let follow_y = btn_y0 + ((PROFILE_FOLLOW_HEIGHT - follow_image.height as i64) / 2).max(4);
    canvas.composite_over(follow_image, follow_x, follow_y);
}

/// `add_profile_bio`: composites the rendered bio vertically centered in the bio area.
pub fn add_profile_bio(canvas: &mut Canvas, bio_image: &Canvas) {
    let bio_top = WINDOW_Y + WINDOW_BAR_HEIGHT + PROFILE_STRIP_HEIGHT + 98;
    let bio_y = bio_top + ((PROFILE_BIO_MAX_HEIGHT - bio_image.height as i64) / 2).max(0);
    canvas.composite_over(bio_image, WINDOW_X + 44, bio_y);
}

/// `add_profile_meta`: composites the footer metadata line onto a profile card.
pub fn add_profile_meta(canvas: &mut Canvas, meta_image: &Canvas) {
    let footer_top = WINDOW_Y + WINDOW_HEIGHT - PROFILE_FOOTER_HEIGHT;
    let meta_y = footer_top + ((PROFILE_FOOTER_HEIGHT - meta_image.height as i64) / 2).max(8);
    canvas.composite_over(meta_image, WINDOW_X + 44, meta_y);
}

/// `add_byline`: composites the author name and metadata line onto an article card.
pub fn add_byline(canvas: &mut Canvas, name_image: &Canvas, meta_image: &Canvas) {
    let text_x = WINDOW_X + 40 + AVATAR_SIZE as i64 + 20;
    let top = WINDOW_Y + WINDOW_HEIGHT - BYLINE_HEIGHT;
    canvas.composite_over(name_image, text_x, top - 2);
    canvas.composite_over(meta_image, text_x, top + 36);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn card_stays_above_the_x_title_overlay() {
        let card_bottom = WINDOW_Y + WINDOW_HEIGHT + WINDOW_STACK_OFFSET * WINDOW_STACK_DEPTH;
        assert!(card_bottom <= HEIGHT as i64 - X_KEEP_CLEAR);
    }

    #[test]
    fn card_is_vertically_centered() {
        let card_bottom = WINDOW_Y + WINDOW_HEIGHT + WINDOW_STACK_OFFSET * WINDOW_STACK_DEPTH;
        let bottom_margin = HEIGHT as i64 - card_bottom;
        assert!((WINDOW_Y - bottom_margin).abs() <= 1);
    }

    #[test]
    fn layout_constants_match_the_ruby_service() {
        assert_eq!(WINDOW_X, 103);
        assert_eq!(WINDOW_HEIGHT, 439);
        assert_eq!(QUOTE_MAX_HEIGHT, 249);
        assert_eq!(QUOTE_WIDTH, 806);
        assert_eq!(PROFILE_BIO_WIDTH, 878);
    }

    #[test]
    fn verify_pixel_parity_against_local_im6_oracle() {
        let convert = "/opt/homebrew/opt/imagemagick@6/bin/convert";
        if !std::path::Path::new(convert).exists() {
            return;
        }
        let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../../..");
        let bold_path = root.join("app/assets/fonts/NotoSans-Bold.ttf");
        let medium_path = root.join("app/assets/fonts/NotoSans-Medium.ttf");
        let mask_path = root.join("app/assets/images/rounded_mask.png");
        let logo_path = root.join("spec/fixtures/files/podcast.png");
        let avatar_path = root.join("spec/fixtures/files/800x600.png");

        let bold_bytes = std::fs::read(&bold_path).unwrap();
        let medium_bytes = std::fs::read(&medium_path).unwrap();
        let bold = Font::from_bytes(&bold_bytes).unwrap();
        let medium = Font::from_bytes(&medium_bytes).unwrap();
        let mask = crate::social_image::decode_image(&std::fs::read(&mask_path).unwrap()).unwrap();
        let logo = crate::social_image::decode_image(&std::fs::read(&logo_path).unwrap()).unwrap();
        let avatar =
            crate::social_image::decode_image(&std::fs::read(&avatar_path).unwrap()).unwrap();

        // 1. Compare `label:Jane Doe` composited on white
        let rust_label =
            crate::social_image::text::render_label(&bold, "Jane Doe", 28.0, TEXT_COLOR);
        let im_label_png = std::process::Command::new(convert)
            .args([
                "-background",
                "none",
                "-fill",
                "black",
                "-font",
                bold_path.to_str().unwrap(),
                "-pointsize",
                "28",
                "label:Jane Doe",
                "png:-",
            ])
            .output()
            .unwrap()
            .stdout;
        let im_label = crate::social_image::decode_image(&im_label_png).unwrap();
        assert_eq!(
            (rust_label.width, rust_label.height),
            (im_label.width, im_label.height)
        );
        let mut max_alpha_diff = 0i32;
        let mut sum_alpha_diff = 0u64;
        for (a, b) in rust_label.pixels.iter().zip(im_label.pixels.iter()) {
            let da = ((a.a * 255.0 + 0.5) as i32 - (b.a * 255.0 + 0.5) as i32).abs();
            max_alpha_diff = max_alpha_diff.max(da);
            sum_alpha_diff += da as u64;
        }
        let mean_label_diff = sum_alpha_diff as f64 / rust_label.pixels.len() as f64;
        println!(
            "label:Jane Doe ({}x{}): mean_alpha_diff={:.4}, max_alpha_diff={}",
            rust_label.width, rust_label.height, mean_label_diff, max_alpha_diff
        );
        assert!(
            mean_label_diff < 5.0,
            "label mean diff too high: {mean_label_diff}"
        );

        // 2. Compare `draw_background`
        let palette = ["#3333ff", "#12004a", "#ff4545", "#6aa9ff", "#5b2bd6"];
        let blobs = [
            BackgroundBlob {
                x: 120,
                y: 50,
                rx: 140,
                ry: 90,
                color: Rgba::parse(palette[1]).unwrap(),
            },
            BackgroundBlob {
                x: 310,
                y: 160,
                rx: 110,
                ry: 80,
                color: Rgba::parse(palette[2]).unwrap(),
            },
            BackgroundBlob {
                x: 40,
                y: 180,
                rx: 160,
                ry: 110,
                color: Rgba::parse(palette[3]).unwrap(),
            },
            BackgroundBlob {
                x: 250,
                y: 20,
                rx: 95,
                ry: 70,
                color: Rgba::parse(palette[4]).unwrap(),
            },
            BackgroundBlob {
                x: 380,
                y: 90,
                rx: 130,
                ry: 100,
                color: Rgba::parse(palette[1]).unwrap(),
            },
            BackgroundBlob {
                x: -10,
                y: 40,
                rx: 150,
                ry: 95,
                color: Rgba::parse(palette[2]).unwrap(),
            },
            BackgroundBlob {
                x: 190,
                y: 130,
                rx: 120,
                ry: 85,
                color: Rgba::parse(palette[3]).unwrap(),
            },
        ];
        let rust_bg = draw_background(Rgba::parse(palette[0]).unwrap(), &blobs);
        let mut cmd = std::process::Command::new(convert);
        cmd.args(["-size", "400x209", &format!("xc:{}", palette[0])]);
        for (i, b) in blobs.iter().enumerate() {
            cmd.args([
                "-fill",
                palette[(i % (palette.len() - 1)) + 1],
                "-draw",
                &format!("ellipse {},{} {},{} 0,360", b.x, b.y, b.rx, b.ry),
            ]);
        }
        cmd.args([
            "-blur",
            "0x48",
            "-filter",
            "Gaussian",
            "-resize",
            "1200x627!",
            "-alpha",
            "off",
            "-depth",
            "8",
            "png:-",
        ]);
        let im_bg_png = cmd.output().unwrap().stdout;
        let im_bg = crate::social_image::decode_image(&im_bg_png).unwrap();
        assert_eq!((rust_bg.width, rust_bg.height), (im_bg.width, im_bg.height));
        let rust_bg_rgb = rust_bg.to_rgb8();
        let im_bg_rgb = im_bg.to_rgb8();
        let mut max_bg_diff = 0i32;
        let mut sum_bg_diff = 0u64;
        for (&a, &b) in rust_bg_rgb.iter().zip(im_bg_rgb.iter()) {
            let d = (i32::from(a) - i32::from(b)).abs();
            max_bg_diff = max_bg_diff.max(d);
            sum_bg_diff += d as u64;
        }
        let mean_bg_diff = sum_bg_diff as f64 / rust_bg_rgb.len() as f64;
        println!(
            "draw_background (1200x627): mean_channel_diff={:.4}, max_channel_diff={}",
            mean_bg_diff, max_bg_diff
        );
        assert!(
            max_bg_diff <= 2,
            "background max diff too high: {max_bg_diff}"
        );

        // 3. Full article card assembly check
        let mut card = rust_bg.clone();
        draw_window(&mut card);
        add_logo(&mut card, &logo);
        let quote_img = render_quote(
            &bold,
            "Rewriting ImageMagick social card generation in Rust eliminates subprocess overhead and memory spikes.",
        );
        add_quote(
            &mut card,
            &quote_img,
            &bold,
            Rgba::parse("#12004a").unwrap(),
        );
        add_profile_image(&mut card, &avatar, &mask);
        let name_img =
            crate::social_image::text::render_label(&bold, "Jane Doe", NAME_POINTSIZE, TEXT_COLOR);
        let meta_img = crate::social_image::text::render_label(
            &medium,
            "Oct 31  ·  5 min read",
            META_POINTSIZE,
            SECONDARY_TEXT_COLOR,
        );
        add_byline(&mut card, &name_img, &meta_img);
        assert_eq!((card.width, card.height), (1200, 627));
    }
}
