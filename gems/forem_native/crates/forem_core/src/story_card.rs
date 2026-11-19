//! Native Story-Card & Tag-Pill HTML rendering engine for:
//! - Tier 1: `ApplicationHelper#render_tag_link` (`render_tag_link` / `push_tag_link`)
//! - Tier 2: `app/views/articles/_single_story.html.erb` (`render_story_cards`)
//!
//! This module has **zero** Ruby, `magnus`, or `rb-sys` dependencies so it can be unit-tested
//! standalone with `cargo test -p forem_core` and reused across targets (`wasm32`, services).

use crate::comment_tree::{
    format_strftime_date, local_civil_date, push_html_escaped, push_utc_iso8601, COUNT_PLACEHOLDER,
    USER_PLACEHOLDER,
};
use crate::feed::{iter_cached_tag_list, match_first_flare_tag};

/// Placeholder sentinel used in `views.articles.for_org_html`.
pub const ORG_PLACEHOLDER: &str = "__FOREM_ORG__";
/// Placeholder sentinel used in `views.articles.comments.aria_label` and `views.articles.save.*`.
pub const TITLE_PLACEHOLDER: &str = "__FOREM_TITLE__";

const UPPER_HEX: &[u8; 16] = b"0123456789ABCDEF";

/// RFC 3986 `pchar` table matching `ActionDispatch::Journey::Router::Utils.escape_segment`:
/// `unreserved / sub-delims / ":" / "@"`.
#[inline]
const fn is_journey_segment_unescaped(b: u8) -> bool {
    b.is_ascii_alphanumeric()
        || matches!(
            b,
            b'-' | b'.'
                | b'_'
                | b'~'
                | b'!'
                | b'$'
                | b'&'
                | b'\''
                | b'('
                | b')'
                | b'*'
                | b'+'
                | b','
                | b';'
                | b'='
                | b':'
                | b'@'
        )
}

/// Appends `segment` encoded via `ActionDispatch::Journey::Router::Utils.escape_segment` and then
/// HTML-escaped for an `href="..."` attribute (matching `link_to(..., tag_path(tag_route))`).
#[inline]
fn push_escaped_route_segment_in_href(out: &mut String, segment: &str) {
    for &b in segment.as_bytes() {
        if is_journey_segment_unescaped(b) {
            match b {
                b'&' => out.push_str("&amp;"),
                b'\'' => out.push_str("&#39;"),
                _ => out.push(b as char),
            }
        } else {
            out.push('%');
            out.push(UPPER_HEX[usize::from(b >> 4)] as char);
            out.push(UPPER_HEX[usize::from(b & 0x0F)] as char);
        }
    }
}

/// Tier 1 composable primitive: appends a rendered `<a class="crayons-tag ...">` pill matching
/// `ApplicationHelper#render_tag_link(tag, filled:, monochrome:, classes:, path_suffix:)` byte-for-byte.
///
/// Returns `None` if `tag_route` is empty or contains `'/'` (where Rails's `tag_path` raises
/// `ActionController::UrlGenerationError`) or if `bg_color_hex` is outside `color::opacity`'s
/// strict 6-digit hex domain.
#[allow(clippy::too_many_arguments)]
pub fn push_tag_link(
    out: &mut String,
    tag_name: &str,
    tag_route: &str,
    bg_color_hex: &str,
    filled: bool,
    monochrome: bool,
    classes: &str,
    path_suffix: &str,
) -> Option<()> {
    if tag_route.is_empty() || tag_route.contains('/') {
        return None;
    }
    let color_faded = crate::color::opacity(bg_color_hex.as_bytes(), 0.1)?;

    out.reserve(240 + tag_name.len() + tag_route.len() + classes.len() + path_suffix.len());
    out.push_str("<a class=\"crayons-tag ");
    if filled {
        out.push_str("crayons-tag--filled");
    }
    out.push(' ');
    if monochrome {
        out.push_str("crayons-tag--monochrome");
    }
    out.push(' ');
    push_html_escaped(out, classes);
    out.push_str("\" style=\"\n        --tag-bg: ");
    out.push_str(&color_faded);
    out.push_str(";\n        --tag-prefix: ");
    out.push_str(bg_color_hex);
    out.push_str(";\n        --tag-bg-hover: ");
    out.push_str(&color_faded);
    out.push_str(";\n        --tag-prefix-hover: ");
    out.push_str(bg_color_hex);
    out.push_str(";\n      \" href=\"/t/");
    push_escaped_route_segment_in_href(out, tag_route);
    push_html_escaped(out, path_suffix);
    out.push_str("\"><span class=\"crayons-tag__prefix\">#</span>");
    push_html_escaped(out, tag_name);
    out.push_str("</a>");
    Some(())
}

/// Standalone `String`-returning entry point for `ApplicationHelper#render_tag_link`.
pub fn render_tag_link(
    tag_name: &str,
    tag_route: &str,
    bg_color_hex: &str,
    filled: bool,
    monochrome: bool,
    classes: &str,
    path_suffix: &str,
) -> Option<String> {
    let mut out = String::with_capacity(260 + tag_name.len() + tag_route.len());
    push_tag_link(
        &mut out,
        tag_name,
        tag_route,
        bg_color_hex,
        filled,
        monochrome,
        classes,
        path_suffix,
    )?;
    Some(out)
}

/// Static locale strings, pre-rendered icons, and feature-flag fragments shared across
/// story-card feed renders.
#[derive(Debug, Clone)]
pub struct StoryCardStaticContext<'a> {
    pub subscription_icon_html: &'a str,
    pub community_leader_icon_html: &'a str,
    pub favorites_enabled: bool,
    pub icon_favorite_checked_curation: &'a str,
    pub icon_pin_svg: &'a str,
    pub icon_small_favorite_filled: &'a str,
    pub icon_small_favorite_checked: &'a str,
    pub icon_small_comment: &'a str,
    pub icon_small_save_svg: &'a str,
    pub icon_small_save_filled_svg: &'a str,
    pub primary_brand_color_hex: &'a str,
    pub escape_html_entities_in_json: bool,
    pub t_users_details_template: &'a str,
    pub t_users_follow: &'a str,
    pub t_for_org_html_template: &'a str,
    pub t_picked_by_you: &'a str,
    pub t_picked_by_user_template: &'a str,
    pub t_favorited: &'a str,
    pub t_pinned_article: &'a str,
    pub t_comments_aria_template: &'a str,
    pub t_reactions_count_one_html: &'a str,
    pub t_reactions_count_other_html_template: &'a str,
    pub t_start_discussion: &'a str,
    pub t_further_discussion: &'a str,
    pub t_curation_comments_one: &'a str,
    pub t_curation_comments_other_template: &'a str,
    pub t_comments_count_one_html: &'a str,
    pub t_comments_count_other_html_template: &'a str,
    pub t_comments_add: &'a str,
    pub t_reading_time_one: &'a str,
    pub t_reading_time_other_template: &'a str,
    pub t_save_aria_template: &'a str,
    pub t_save_title_template: &'a str,
    pub time_format_short: &'a str,
    pub time_format_short_with_yy: &'a str,
    pub abbr_month_names: [&'a str; 12],
    pub prior_cloudflare_domain: Option<&'a str>,
    pub current_cloudflare_domain: Option<&'a str>,
}

/// Strategy used to resolve `cloud_cover_url(story.main_image)` when `explicit_cover_url` is `None`.
#[derive(Debug, Clone)]
pub enum CoverImageMode<'a> {
    /// Returns `main_image` unchanged (`Rails.env.development?` or no CDN optimizer active).
    Passthrough,
    /// Computes Cloudflare Images URLs in-process via `crate::image::cloudflare_image_url`.
    Cloudflare {
        domain: &'a str,
        directory: &'a str,
        default_height: &'a str,
        default_fit: &'a str,
    },
    /// Requires `explicit_cover_url` whenever `main_image` is non-blank (e.g. Cloudinary / Imgproxy).
    ExplicitOnly,
}

/// Per-invocation view state and batch lookup tables for `render_story_cards`.
#[derive(Debug, Clone)]
pub struct StoryCardViewContext<'a> {
    pub feed_style_rich: bool,
    pub curation_view: bool,
    pub show_bookmark_buttons: bool,
    pub assigned_user_id: Option<i64>,
    pub current_year: i32,
    pub default_base_url: &'a str,
    pub cover_mode: CoverImageMode<'a>,
    pub except_flare_tag: Option<&'a str>,
    pub allowed_flare_tags: Vec<&'a str>,
    pub valid_flare_tags: Vec<&'a str>,
    pub reaction_icon_htmls: Vec<&'a str>,
    pub tag_bg_colors: Vec<(&'a str, &'a str)>,
}

/// Deduplicated story author (`story.cached_user` + `story.user_id`) metadata.
#[derive(Debug, Clone)]
pub struct StoryAuthorInput<'a> {
    pub user_id: i64,
    pub name: &'a str,
    pub username: &'a str,
    pub profile_image_90: &'a str,
    pub is_subscriber: bool,
    pub is_community_leader: bool,
}

/// Deduplicated story organization (`story.cached_organization`) metadata.
#[derive(Debug, Clone)]
pub struct StoryOrgInput<'a> {
    pub slug: &'a str,
    pub name: &'a str,
    pub profile_image_90: &'a str,
}

/// Per-card input slice for `render_story_cards`.
#[derive(Debug, Clone)]
pub struct StoryCardInput<'a> {
    pub id: i64,
    pub author_idx: usize,
    /// `Some(idx)` iff `story.cached_organization` is present AND `show_organization` is truthy.
    pub org_idx: Option<usize>,
    pub featured: bool,
    pub pinned: bool,
    pub type_of: &'a str,
    pub title: &'a str,
    pub path: &'a str,
    pub explicit_article_url: Option<&'a str>,
    pub main_image: Option<&'a str>,
    pub explicit_cover_url: Option<&'a str>,
    pub main_image_height: Option<i64>,
    pub main_image_bg_hex: Option<&'a str>,
    pub video: Option<&'a str>,
    pub video_thumbnail_url: Option<&'a str>,
    pub cloudinary_video_url: Option<&'a str>,
    pub video_duration_str: Option<&'a str>,
    pub context_note_html: Option<&'a str>,
    pub published: bool,
    pub displayable_published_at: Option<(i64, i64)>,
    pub published_at_int: i64,
    pub cached_tag_list: &'a str,
    pub status_body_preview_html: Option<&'a str>,
    pub public_reactions_count: i64,
    /// Indices into `view_ctx.reaction_icon_htmls` in display order (`public_reaction_categories.reverse`).
    pub reaction_icon_indices: Vec<usize>,
    pub favorited_by_user_id: Option<i64>,
    /// `0` = hidden, `1` = `picked_by_you`, `2` = `picked_by_user`, `3` = `favorited`.
    pub curation_picker_state: u8,
    pub favorited_by_username: Option<&'a str>,
    pub comments_count: i64,
    pub reading_time: i64,
}

struct PreparedStoryAuthor {
    user_id_str: String,
    escaped_name: String,
    escaped_username: String,
    escaped_profile_image_90: String,
    escaped_details_aria_label: String,
    escaped_data_info_json: String,
}

struct PreparedStoryOrg {
    author_pic_logo_html: String,
    for_org_span_html: String,
}

struct PreparedTag<'a> {
    name: &'a str,
    bg_color_hex: &'a str,
    monochrome_pill_html: String,
}

#[inline]
fn is_ruby_present(s: &str) -> bool {
    !s.chars().all(char::is_whitespace)
}

#[inline]
fn html_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 8);
    push_html_escaped(&mut out, s);
    out
}

#[inline]
fn push_i64_decimal(out: &mut String, value: i64) {
    if value == 0 {
        out.push('0');
        return;
    }
    let negative = value < 0;
    let mut n = value.unsigned_abs();
    let mut buf = [0u8; 20];
    let mut pos = 20;
    while n > 0 {
        pos -= 1;
        buf[pos] = b'0' + (n % 10) as u8;
        n /= 10;
    }
    if negative {
        pos -= 1;
        buf[pos] = b'-';
    }
    out.push_str(std::str::from_utf8(&buf[pos..20]).unwrap());
}

/// Appends `template` with HTML-escaping applied to its static segments and `escaped_arg`
/// spliced verbatim at every occurrence of `placeholder`.
#[inline]
fn push_escaped_template(out: &mut String, template: &str, placeholder: &str, escaped_arg: &str) {
    let mut rest = template;
    while let Some(pos) = rest.find(placeholder) {
        push_html_escaped(out, &rest[..pos]);
        out.push_str(escaped_arg);
        rest = &rest[pos + placeholder.len()..];
    }
    push_html_escaped(out, rest);
}

/// Appends an already HTML-safe `_html` template, splicing `replacement` at `placeholder`.
#[inline]
fn push_raw_template(out: &mut String, template: &str, placeholder: &str, replacement: &str) {
    let mut rest = template;
    while let Some(pos) = rest.find(placeholder) {
        out.push_str(&rest[..pos]);
        out.push_str(replacement);
        rest = &rest[pos + placeholder.len()..];
    }
    out.push_str(rest);
}

/// Appends an already HTML-safe `_html` count template (`count > 1`), replacing `COUNT_PLACEHOLDER`
/// with `count` formatted in base 10.
#[inline]
fn push_raw_count_template(out: &mut String, template: &str, count: i64) {
    let mut rest = template;
    while let Some(pos) = rest.find(COUNT_PLACEHOLDER) {
        out.push_str(&rest[..pos]);
        push_i64_decimal(out, count);
        rest = &rest[pos + COUNT_PLACEHOLDER.len()..];
    }
    out.push_str(rest);
}

/// Appends a plain-text count template (`count != 1`), HTML-escaping static text and splicing `count`.
#[inline]
fn push_escaped_count_template(out: &mut String, template: &str, count: i64) {
    let mut rest = template;
    while let Some(pos) = rest.find(COUNT_PLACEHOLDER) {
        push_html_escaped(out, &rest[..pos]);
        push_i64_decimal(out, count);
        rest = &rest[pos + COUNT_PLACEHOLDER.len()..];
    }
    push_html_escaped(out, rest);
}

/// Appends `processed_html`, applying `PRIOR_CLOUDFLARE_IMAGES_DOMAIN` -> `CLOUDFLARE_IMAGES_DOMAIN`
/// replacement if configured (`Article#processed_html_final`).
fn push_processed_html_final(
    out: &mut String,
    processed_html: &str,
    prior_domain: Option<&str>,
    current_domain: Option<&str>,
) {
    if let (Some(prior), Some(current)) = (prior_domain, current_domain) {
        if !prior.is_empty() && !current.is_empty() {
            let mut rest = processed_html;
            while let Some(pos) = rest.find(prior) {
                out.push_str(&rest[..pos]);
                out.push_str(current);
                rest = &rest[pos + prior.len()..];
            }
            out.push_str(rest);
            return;
        }
    }
    out.push_str(processed_html);
}

fn prepare_story_author(
    author: &StoryAuthorInput<'_>,
    static_ctx: &StoryCardStaticContext<'_>,
) -> PreparedStoryAuthor {
    let mut user_id_str = String::with_capacity(12);
    push_i64_decimal(&mut user_id_str, author.user_id);

    let escaped_name = html_escape(author.name);
    let escaped_username = html_escape(author.username);
    let escaped_profile_image_90 = html_escape(author.profile_image_90);

    let mut escaped_details_aria_label =
        String::with_capacity(static_ctx.t_users_details_template.len() + escaped_name.len());
    push_escaped_template(
        &mut escaped_details_aria_label,
        static_ctx.t_users_details_template,
        USER_PLACEHOLDER,
        &escaped_name,
    );

    // `DataInfo.to_json(object: cached_user, class_name: "User", id: user_id, style: "full")`
    let mut raw_json = String::with_capacity(64 + author.name.len());
    raw_json.push_str("{\"style\":\"full\",\"id\":");
    raw_json.push_str(&user_id_str);
    raw_json.push_str(",\"className\":\"User\",\"name\":");
    crate::json::write_json_string(
        &mut raw_json,
        author.name,
        static_ctx.escape_html_entities_in_json,
    );
    raw_json.push('}');
    let escaped_data_info_json = html_escape(&raw_json);

    PreparedStoryAuthor {
        user_id_str,
        escaped_name,
        escaped_username,
        escaped_profile_image_90,
        escaped_details_aria_label,
        escaped_data_info_json,
    }
}

fn prepare_story_org(
    org: &StoryOrgInput<'_>,
    static_ctx: &StoryCardStaticContext<'_>,
) -> PreparedStoryOrg {
    let escaped_slug = html_escape(org.slug);
    let escaped_name = html_escape(org.name);
    let escaped_img = html_escape(org.profile_image_90);

    let mut logo_html =
        String::with_capacity(180 + escaped_slug.len() + escaped_name.len() + escaped_img.len());
    logo_html.push_str("          <a class=\"crayons-logo crayons-logo--l\" href=\"/");
    logo_html.push_str(&escaped_slug);
    logo_html.push_str("\">\n            <img alt=\"");
    logo_html.push_str(&escaped_name);
    logo_html.push_str(" logo\" src=\"");
    logo_html.push_str(&escaped_img);
    logo_html.push_str("\" class=\"crayons-logo__image\" loading=\"lazy\" />\n          </a>\n");

    let mut org_anchor = String::with_capacity(80 + escaped_slug.len() + escaped_name.len());
    org_anchor.push_str("<a href=\"/");
    org_anchor.push_str(&escaped_slug);
    org_anchor.push_str("\" class=\"crayons-story__secondary fw-medium\">");
    org_anchor.push_str(&escaped_name);
    org_anchor.push_str("</a>");

    let mut for_org_span =
        String::with_capacity(64 + static_ctx.t_for_org_html_template.len() + org_anchor.len());
    for_org_span.push_str("            <span>\n              ");
    push_raw_template(
        &mut for_org_span,
        static_ctx.t_for_org_html_template,
        ORG_PLACEHOLDER,
        &org_anchor,
    );
    for_org_span.push_str("\n            </span>\n");

    PreparedStoryOrg {
        author_pic_logo_html: logo_html,
        for_org_span_html: for_org_span,
    }
}

fn resolve_cover_url<'a>(
    main_image: Option<&'a str>,
    explicit_cover_url: Option<&'a str>,
    cover_mode: &CoverImageMode<'a>,
) -> Option<String> {
    let Some(raw_url) = main_image else {
        return Some(String::new());
    };
    if !is_ruby_present(raw_url) {
        return Some(String::new());
    }
    if let Some(explicit) = explicit_cover_url {
        return Some(explicit.to_owned());
    }
    match cover_mode {
        CoverImageMode::Passthrough => Some(raw_url.to_owned()),
        CoverImageMode::ExplicitOnly => None,
        CoverImageMode::Cloudflare {
            domain,
            directory,
            default_height,
            default_fit,
        } => {
            if raw_url.ends_with("w_1000/") {
                return None;
            }
            let img_src = if raw_url.starts_with("https://res.cloudinary.com/")
                && raw_url.contains("w_1000/https://")
            {
                raw_url.rsplit("w_1000/").next()?
            } else {
                raw_url
            };
            if !is_ruby_present(img_src)
                || img_src.starts_with('/')
                || img_src.contains("/agent_sessions/")
            {
                return Some(img_src.to_owned());
            }
            // Reject already-nested Cloudflare URLs so Ruby's `extract_suffix_url` handles them.
            let mut cf_prefix = String::with_capacity(20 + domain.len() + directory.len());
            cf_prefix.push_str("https://");
            cf_prefix.push_str(domain);
            cf_prefix.push('/');
            cf_prefix.push_str(directory);
            cf_prefix.push_str("/image");
            if img_src.starts_with(&cf_prefix) {
                return None;
            }
            let (height_str, fit) = if raw_url.contains("ytimg.com") {
                ("500", "cover")
            } else {
                (*default_height, *default_fit)
            };
            crate::image::cloudflare_image_url(
                domain, directory, "1000", height_str, fit, img_src, img_src,
            )
        }
    }
}

fn push_status_title(out: &mut String, title: &str, for_feed: bool) {
    if !is_ruby_present(title) {
        push_html_escaped(out, title);
        return;
    }
    let safe_title = if title.contains(['<', '>']) {
        let mut s = String::with_capacity(title.len() + 16);
        for ch in title.chars() {
            match ch {
                '<' => s.push_str("&lt;"),
                '>' => s.push_str("&gt;"),
                _ => s.push(ch),
            }
        }
        s
    } else {
        title.to_owned()
    };
    let truncate = for_feed && title.bytes().filter(|&b| b == b'\n').count() >= 8;
    out.push_str(&crate::title::quickie_title_html(&safe_title, truncate));
}

#[allow(clippy::too_many_arguments)]
fn render_single_card(
    out: &mut String,
    static_ctx: &StoryCardStaticContext<'_>,
    view_ctx: &StoryCardViewContext<'_>,
    authors: &[StoryAuthorInput<'_>],
    prepared_authors: &[PreparedStoryAuthor],
    prepared_orgs: &[PreparedStoryOrg],
    prepared_tags: &[PreparedTag<'_>],
    card: &StoryCardInput<'_>,
) -> Option<()> {
    if card.comments_count < 0 {
        return None;
    }
    let author = authors.get(card.author_idx)?;
    let prep_author = prepared_authors.get(card.author_idx)?;
    let prep_org = match card.org_idx {
        Some(idx) => Some(prepared_orgs.get(idx)?),
        None => None,
    };

    let mut card_id_str = String::with_capacity(12);
    push_i64_decimal(&mut card_id_str, card.id);

    let article_url = match card.explicit_article_url {
        Some(u) => u.to_owned(),
        None => crate::url::join_url(view_ctx.default_base_url, card.path)?,
    };
    let escaped_article_url = html_escape(&article_url);
    let escaped_title = html_escape(card.title);
    let is_status = card.type_of == "status";

    let cover_url = resolve_cover_url(
        card.main_image,
        card.explicit_cover_url,
        &view_ctx.cover_mode,
    )?;
    let escaped_cover_url = html_escape(&cover_url);

    // 1. Story wrapper & hidden navigation link
    out.push_str("<div class=\"crayons-story ");
    if card.featured {
        out.push_str("crayons-story--featured");
    }
    out.push_str("\" data-feed-content-id=\"");
    out.push_str(&card_id_str);
    out.push_str("\" data-content-user-id=\"");
    out.push_str(&prep_author.user_id_str);
    out.push_str("\">\n  <a href=\"");
    out.push_str(&escaped_article_url);
    out.push_str("\" aria-labelledby=\"article-link-");
    out.push_str(&card_id_str);
    out.push_str("\" class=\"crayons-story__hidden-navigation-link\">");
    if is_status {
        push_status_title(out, card.title, false);
    } else {
        out.push_str(&escaped_title);
    }
    out.push_str("</a>\n");

    if card.featured {
        out.push_str("    <div id=\"featured-story-marker\" data-featured-article=\"articles-");
        out.push_str(&card_id_str);
        out.push_str("\"></div>\n");
    }

    // 2. Video iframe vs cover image
    let video_present = card.video.is_some_and(is_ruby_present);
    let video_str = card.video.unwrap_or("");
    let has_youtube_or_mux = video_str.contains("youtube") || video_str.contains("player.mux.com");
    let has_embed_video =
        video_present && (has_youtube_or_mux || video_str.contains("player.twitch.tv"));

    if has_embed_video {
        out.push_str("    <div class=\"crayons-article__cover crayons-article__cover__image__feed\" style=\"width: 100%; aspect-ratio: 16 / 9; position: relative;\">\n      <iframe src=\"");
        push_html_escaped(out, video_str);
        out.push_str("\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture\" allowfullscreen=\"true\" title=\"");
        out.push_str(&escaped_title);
        out.push_str("\" style=\"border: 0px; position: absolute; top: 0px; left: 0px; width: 100%; height: 100%;\"></iframe>\n    </div>\n");
    } else if card.featured
        || (view_ctx.feed_style_rich && card.main_image.is_some_and(is_ruby_present))
    {
        out.push_str("    <div class=\"crayons-article__cover crayons-article__cover__image__feed\" style=\"aspect-ratio: auto 1000 / ");
        if let Some(h) = card.main_image_height {
            push_i64_decimal(out, h);
        }
        out.push_str(";\">\n              <a href=\"");
        out.push_str(&escaped_article_url);
        out.push_str("\" title=\"");
        out.push_str(&escaped_title);
        out.push_str("\" aria-label=\"article\" class=\"crayons-article__cover__image__feed crayons-story__cover__image\">\n        <img src=\"");
        out.push_str(&escaped_cover_url);
        out.push_str("\" width=\"1000\" height=\"");
        if let Some(h) = card.main_image_height {
            push_i64_decimal(out, h);
        }
        out.push_str("\" style=\"background-color:");
        if let Some(bg_hex) = card.main_image_bg_hex {
            push_html_escaped(out, bg_hex);
        }
        out.push_str(";\" class=\"crayons-article__cover__image__feed\" alt=\"Cover image for ");
        out.push_str(&escaped_title);
        out.push_str("\">\n      </a>\n    </div>\n");
    }

    out.push('\n');

    // 3. Native video thumbnail + duration badge
    if video_present && card.video_thumbnail_url.is_some_and(is_ruby_present) && !has_youtube_or_mux
    {
        out.push_str("  <a href=\"");
        out.push_str(&escaped_article_url);
        out.push_str("\" class=\"crayons-story__video\" style=\"background-image:url(");
        if let Some(cv_url) = card.cloudinary_video_url {
            push_html_escaped(out, cv_url);
        }
        out.push_str(")\">\n    <span class=\"crayons-story__video__time\">\n      ");
        if let Some(dur) = card.video_duration_str {
            push_html_escaped(out, dur);
        }
        out.push_str("\n    </span>\n  </a>\n");
    }

    // 4. Story body & context note
    out.push_str("\n  <div class=\"crayons-story__body crayons-story__body-");
    push_html_escaped(out, card.type_of);
    out.push_str("\">\n");

    if let Some(note_html) = card.context_note_html {
        if is_ruby_present(note_html) {
            out.push_str("      <a href=\"");
            out.push_str(&escaped_article_url);
            out.push_str(
                "\" class=\"crayons-article__context-note crayons-article__context-note__feed\">",
            );
            out.push_str(note_html);
            out.push_str("</a>\n");
        }
    }

    // 5. Top metadata: org logo, user avatar, user preview card, `for_org_html`, publish date
    out.push_str("    <div class=\"crayons-story__top\">\n      <div class=\"crayons-story__meta\">\n        <div class=\"crayons-story__author-pic\">\n");
    if let Some(org) = prep_org {
        out.push_str(&org.author_pic_logo_html);
    }
    out.push_str("\n          <a href=\"/");
    out.push_str(&prep_author.escaped_username);
    out.push_str("\" class=\"crayons-avatar ");
    if prep_org.is_some() {
        out.push_str(" crayons-avatar--s absolute -right-2 -bottom-2 border-solid border-2 border-base-inverted ");
    } else {
        out.push_str(" crayons-avatar--l ");
    }
    out.push_str(" \">\n            <img src=\"");
    out.push_str(&prep_author.escaped_profile_image_90);
    out.push_str("\" alt=\"");
    out.push_str(&prep_author.escaped_username);
    out.push_str(" profile\" class=\"crayons-avatar__image\" loading=\"lazy\" />\n          </a>\n        </div>\n        <div>\n          <div>\n            <a href=\"/");
    out.push_str(&prep_author.escaped_username);
    out.push_str("\" class=\"crayons-story__secondary fw-medium m:hidden\">\n              ");
    out.push_str(&prep_author.escaped_name);
    out.push_str("\n            </a>\n            <div class=\"profile-preview-card relative mb-4 s:mb-0 fw-medium hidden m:inline-block\">\n              <button id=\"story-author-preview-trigger-");
    out.push_str(&card_id_str);
    out.push_str("\" aria-controls=\"story-author-preview-content-");
    out.push_str(&card_id_str);
    out.push_str("\" class=\"profile-preview-card__trigger fs-s p-1 -ml-1 -my-2 crayons-btn crayons-btn--ghost\" aria-label=\"");
    out.push_str(&prep_author.escaped_details_aria_label);
    out.push_str("\">\n                ");
    out.push_str(&prep_author.escaped_name);
    out.push_str("\n                ");
    if author.is_subscriber {
        out.push_str(static_ctx.subscription_icon_html);
    }
    out.push_str("\n                ");
    if author.is_community_leader {
        out.push_str(static_ctx.community_leader_icon_html);
    }
    out.push_str("\n              </button>\n              <div\n                id=\"story-author-preview-content-");
    out.push_str(&card_id_str);
    out.push_str("\"\n                class=\"profile-preview-card__content crayons-dropdown branded-7 p-4 pt-0\"\n                style=\"border-top-color: var(--card-color);\"\n                data-repositioning-dropdown=\"true\"\n                data-testid=\"profile-preview-card\">\n                <div class=\"gap-4 grid\">\n                  <div class=\"-mt-4\">\n                    <a href=\"/");
    out.push_str(&prep_author.escaped_username);
    out.push_str("\" class=\"flex\">\n                      <span class=\"crayons-avatar crayons-avatar--xl mr-2 shrink-0\">\n                        <img\n                          src=\"");
    out.push_str(&prep_author.escaped_profile_image_90);
    out.push_str("\"\n                          class=\"crayons-avatar__image\"\n                          alt=\"\"\n                          loading=\"lazy\" />\n                      </span>\n                      <span class=\"crayons-link crayons-subtitle-2 mt-5\">");
    out.push_str(&prep_author.escaped_name);
    out.push_str("</span>\n                    </a>\n                  </div>\n                  <div class=\"print-hidden\">\n                    <button\n                      class=\"crayons-btn follow-action-button whitespace-nowrap follow-user w-100\"\n                      data-info='");
    out.push_str(&prep_author.escaped_data_info_json);
    out.push_str("'>\n                      ");
    push_html_escaped(out, static_ctx.t_users_follow);
    out.push_str("\n                    </button>\n                  </div>\n                  <div\n                    class=\"author-preview-metadata-container\"\n                    data-author-id=\"");
    out.push_str(&prep_author.user_id_str);
    out.push_str("\"></div>\n                </div>\n              </div>\n            </div>\n\n");

    if let Some(org) = prep_org {
        out.push_str(&org.for_org_span_html);
    }

    // 6. Publish date & curation picker badge
    out.push_str("          </div>\n          <a href=\"");
    out.push_str(&escaped_article_url);
    out.push_str("\" class=\"crayons-story__tertiary fs-xs\"><time datetime=\"");
    if card.published {
        if let Some((tv_sec, _)) = card.displayable_published_at {
            push_utc_iso8601(out, tv_sec)?;
        }
    }
    out.push_str("\">");
    if let Some((tv_sec, utc_offset)) = card.displayable_published_at {
        let (year, month, day) = local_civil_date(tv_sec, utc_offset)?;
        let pattern = if year == view_ctx.current_year {
            static_ctx.time_format_short
        } else {
            static_ctx.time_format_short_with_yy
        };
        let formatted =
            format_strftime_date(pattern, year, month, day, &static_ctx.abbr_month_names)?;
        push_html_escaped(out, &formatted);
    }
    out.push_str("</time><span class=\"time-ago-indicator-initial-placeholder\" data-seconds=\"");
    push_i64_decimal(out, card.published_at_int);
    out.push_str("\"></span></a>\n");

    if view_ctx.curation_view
        && card.favorited_by_user_id.is_some()
        && card.curation_picker_state > 0
    {
        out.push_str("            <span class=\"inline-flex items-center fs-xs fw-medium ml-2\" style=\"color: var(--reaction-favorite-color);\">\n              ");
        out.push_str(static_ctx.icon_favorite_checked_curation);
        out.push('\n');
        match card.curation_picker_state {
            1 => {
                out.push_str("                ");
                push_html_escaped(out, static_ctx.t_picked_by_you);
                out.push('\n');
            }
            2 => {
                let picker_uname = html_escape(card.favorited_by_username.unwrap_or(""));
                out.push_str("                ");
                push_escaped_template(
                    out,
                    static_ctx.t_picked_by_user_template,
                    USER_PLACEHOLDER,
                    &picker_uname,
                );
                out.push('\n');
            }
            _ => {
                out.push_str("                ");
                push_html_escaped(out, static_ctx.t_favorited);
                out.push('\n');
            }
        }
        out.push_str("            </span>\n");
    }

    out.push_str("        </div>\n      </div>\n\n");

    // 7. Pinned badge
    if card.pinned {
        out.push_str("        <div\n          class=\"pinned color-accent-brand fw-bold\"\n          data-testid=\"pinned-article\">\n          ");
        out.push_str(static_ctx.icon_pin_svg);
        push_html_escaped(out, static_ctx.t_pinned_article);
        out.push_str("\n        </div>\n");
    }

    // 8. Title & Indention
    out.push_str("    </div>\n\n    <div class=\"crayons-story__indention\">\n      <h2 class=\"crayons-story__title crayons-story__title-");
    push_html_escaped(out, card.type_of);
    out.push_str("\">\n        <a href=\"");
    out.push_str(&escaped_article_url);
    out.push_str("\" data-preload-image=\"");
    out.push_str(&escaped_cover_url);
    out.push_str("\" id=\"article-link-");
    out.push_str(&card_id_str);
    out.push_str("\">\n          ");
    if is_status {
        push_status_title(out, card.title, true);
    } else {
        out.push_str(&escaped_title);
    }
    out.push_str("\n        </a>\n      </h2>\n");

    // 9. Tag pills (non-status posts)
    if !is_status {
        out.push_str("        <div class=\"crayons-story__tags\">\n");
        let flare_name =
            match_first_flare_tag(card.cached_tag_list, Some(&view_ctx.allowed_flare_tags)).filter(
                |&matched| {
                    Some(matched) != view_ctx.except_flare_tag
                        && view_ctx.valid_flare_tags.contains(&matched)
                },
            );

        if let Some(flare) = flare_name {
            let bg_hex = prepared_tags
                .iter()
                .find(|t| t.name == flare)
                .map(|t| t.bg_color_hex)
                .unwrap_or(static_ctx.primary_brand_color_hex);
            out.push_str("            ");
            push_tag_link(out, flare, flare, bg_hex, true, false, "", "")?;
            out.push('\n');
        }

        for tag in iter_cached_tag_list(card.cached_tag_list) {
            if Some(tag) == flare_name {
                continue;
            }
            out.push_str("            ");
            if let Some(prep_tag) = prepared_tags.iter().find(|t| t.name == tag) {
                out.push_str(&prep_tag.monochrome_pill_html);
            } else {
                push_tag_link(
                    out,
                    tag,
                    tag,
                    static_ctx.primary_brand_color_hex,
                    false,
                    true,
                    "",
                    "",
                )?;
            }
            out.push('\n');
        }
        out.push_str("        </div>\n");
    }

    // 10. Status post `body_preview`
    if is_status {
        if let Some(raw_preview) = card.status_body_preview_html {
            if is_ruby_present(raw_preview) {
                let mut preview_final = String::with_capacity(raw_preview.len());
                push_processed_html_final(
                    &mut preview_final,
                    raw_preview,
                    static_ctx.prior_cloudflare_domain,
                    static_ctx.current_cloudflare_domain,
                );
                if is_ruby_present(&preview_final) && preview_final.chars().count() > 10 {
                    out.push_str("        <div class=\"crayons-story__contentpreview text-styles\">\n          ");
                    out.push_str(&preview_final);
                    out.push_str("\n        </div>\n");
                }
            }
        }
    }

    // 11. Bottom details: reactions, favorited marker, comments button
    out.push_str("      <div class=\"crayons-story__bottom\">\n        <div class=\"crayons-story__details\">\n");

    if card.public_reactions_count > 0 {
        out.push_str("          <a href=\"");
        out.push_str(&escaped_article_url);
        out.push_str("\" class=\"crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon-left\" data-reaction-count data-reactable-id=\"");
        out.push_str(&card_id_str);
        out.push_str("\" aria-label=\"");
        push_escaped_template(
            out,
            static_ctx.t_comments_aria_template,
            TITLE_PLACEHOLDER,
            &escaped_title,
        );
        out.push_str("\">\n            <div class=\"multiple_reactions_aggregate\">\n              <span class=\"multiple_reactions_icons_container\" dir=\"rtl\">\n");
        for &icon_idx in &card.reaction_icon_indices {
            let icon_html = view_ctx.reaction_icon_htmls.get(icon_idx)?;
            out.push_str(
                "                  <span class=\"crayons_icon_container\">\n                    ",
            );
            out.push_str(icon_html);
            out.push_str("\n                  </span>\n");
        }
        out.push_str(
            "              </span>\n              <span class=\"aggregate_reactions_counter\">",
        );
        if card.public_reactions_count == 1 {
            out.push_str(static_ctx.t_reactions_count_one_html);
        } else {
            push_raw_count_template(
                out,
                static_ctx.t_reactions_count_other_html_template,
                card.public_reactions_count,
            );
        }
        out.push_str("</span>\n            </div>\n          </a>\n");
    }

    if !view_ctx.curation_view && static_ctx.favorites_enabled {
        if let Some(fav_uid) = card.favorited_by_user_id {
            out.push_str("            <span\n              class=\"crayons-story__favorited\"\n              data-favorited-marker\n              data-favorited-by-user-id=\"");
            push_i64_decimal(out, fav_uid);
            out.push_str("\">\n              <span class=\"favorited-marker\">\n                <span data-favorited-icon=\"other\">\n                  ");
            out.push_str(static_ctx.icon_small_favorite_filled);
            out.push_str("\n                </span>\n                <span data-favorited-icon=\"self\" class=\"hidden\">\n                  ");
            out.push_str(static_ctx.icon_small_favorite_checked);
            out.push_str("\n                </span>\n              </span>\n            </span>\n");
        }
    }

    if view_ctx.curation_view {
        if card.comments_count == 0 {
            let escaped_start = html_escape(static_ctx.t_start_discussion);
            out.push_str("              <a href=\"");
            out.push_str(&escaped_article_url);
            out.push_str("#comments\" class=\"crayons-btn crayons-btn--s crayons-btn--danger fs-xs fw-bold flex items-center\" aria-label=\"");
            out.push_str(&escaped_start);
            out.push_str("\">\n                <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" class=\"crayons-icon mr-1 shrink-0\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">\n                  <path d=\"M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z\"></path>\n                </svg>\n                ");
            out.push_str(&escaped_start);
            out.push_str("\n              </a>\n");
        } else if card.comments_count < 3 {
            let escaped_further = html_escape(static_ctx.t_further_discussion);
            out.push_str("              <a href=\"");
            out.push_str(&escaped_article_url);
            out.push_str("#comments\" class=\"crayons-btn crayons-btn--s crayons-btn--danger fs-xs fw-bold flex items-center\" aria-label=\"");
            out.push_str(&escaped_further);
            out.push_str("\">\n                <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" class=\"crayons-icon mr-1 shrink-0\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">\n                  <path d=\"M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z\"></path>\n                </svg>\n                ");
            out.push_str(&escaped_further);
            out.push_str(" (");
            if card.comments_count == 1 {
                push_html_escaped(out, static_ctx.t_curation_comments_one);
            } else {
                push_escaped_count_template(
                    out,
                    static_ctx.t_curation_comments_other_template,
                    card.comments_count,
                );
            }
            out.push_str(")\n              </a>\n");
        } else {
            out.push_str("              <a href=\"");
            out.push_str(&escaped_article_url);
            out.push_str("#comments\" class=\"crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon-left flex items-center\" aria-label=\"");
            push_escaped_template(
                out,
                static_ctx.t_comments_aria_template,
                TITLE_PLACEHOLDER,
                &escaped_title,
            );
            out.push_str("\">\n                ");
            out.push_str(static_ctx.icon_small_comment);
            out.push_str("\n                ");
            push_raw_count_template(
                out,
                static_ctx.t_comments_count_other_html_template,
                card.comments_count,
            );
            out.push_str("\n              </a>\n");
        }
    } else if card.comments_count > 0 {
        out.push_str("            <a href=\"");
        out.push_str(&escaped_article_url);
        out.push_str("#comments\" class=\"crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon-left flex items-center\" aria-label=\"");
        push_escaped_template(
            out,
            static_ctx.t_comments_aria_template,
            TITLE_PLACEHOLDER,
            &escaped_title,
        );
        out.push_str("\">\n              ");
        out.push_str(static_ctx.icon_small_comment);
        out.push_str("\n              ");
        if card.comments_count == 1 {
            out.push_str(static_ctx.t_comments_count_one_html);
        } else {
            push_raw_count_template(
                out,
                static_ctx.t_comments_count_other_html_template,
                card.comments_count,
            );
        }
        out.push_str("\n            </a>\n");
    } else {
        out.push_str("            <a href=\"");
        out.push_str(&escaped_article_url);
        out.push_str("#comments\" class=\"crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon-left flex items-center\" aria-label=\"");
        push_escaped_template(
            out,
            static_ctx.t_comments_aria_template,
            TITLE_PLACEHOLDER,
            &escaped_title,
        );
        out.push_str("\">\n              ");
        out.push_str(static_ctx.icon_small_comment);
        out.push_str("\n              <span class=\"hidden s:inline\">");
        push_html_escaped(out, static_ctx.t_comments_add);
        out.push_str("</span>\n            </a>\n");
    }

    // 12. Save area: reading time, bookmark button, moderation button
    out.push_str("        </div>\n        <div class=\"crayons-story__save\">\n          <small class=\"crayons-story__tertiary fs-xs mr-2\">\n            ");
    let display_rt = card.reading_time.max(1);
    if display_rt == 1 {
        push_html_escaped(out, static_ctx.t_reading_time_one);
    } else {
        push_escaped_count_template(out, static_ctx.t_reading_time_other_template, display_rt);
    }
    out.push_str("\n          </small>\n");

    if view_ctx.show_bookmark_buttons && view_ctx.assigned_user_id != Some(author.user_id) {
        out.push_str("            <button\n              type=\"button\"\n              id=\"article-save-button-");
        out.push_str(&card_id_str);
        out.push_str("\"\n              class=\"c-btn c-btn--icon-alone bookmark-button\"\n              data-reactable-id=\"");
        out.push_str(&card_id_str);
        out.push_str("\"\n              data-article-author-id=\"");
        out.push_str(&prep_author.user_id_str);
        out.push_str("\"\n              aria-label=\"");
        push_escaped_template(
            out,
            static_ctx.t_save_aria_template,
            TITLE_PLACEHOLDER,
            &escaped_title,
        );
        out.push_str("\"\n              title=\"");
        push_escaped_template(
            out,
            static_ctx.t_save_title_template,
            TITLE_PLACEHOLDER,
            &escaped_title,
        );
        out.push_str("\">\n              <span class=\"bm-initial crayons-icon c-btn__icon\">\n                ");
        out.push_str(static_ctx.icon_small_save_svg);
        out.push_str("\n              </span>\n              <span class=\"bm-success crayons-icon c-btn__icon\">\n                ");
        out.push_str(static_ctx.icon_small_save_filled_svg);
        out.push_str("\n              </span>\n            </button>\n");
    }

    out.push_str("          \n          <div class=\"only-sidebar-menu-item trusted-visible-block print-hidden align-center\">\n                <button class=\"crayons-btn crayons-btn--ghost crayons-btn--icon-rounded mod-actions-menu-btn\" data-article-path=\"");
    push_html_escaped(out, card.path);
    out.push_str("\">\n                    <svg width=\"24\" height=\"24\" class=\"crayons-icon\" viewBox=\"0 0 24 24\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"mod-actions-button-title-");
    out.push_str(&card_id_str);
    out.push_str("\">\n                     <title id=\"mod-actions-button-title-");
    out.push_str(&card_id_str);
    out.push_str("\">Moderation</title>\n                    <path d=\"M3.783 2.826L12 1l8.217 1.826a1 1 0 01.783.976v9.987a6 6 0 01-2.672 4.992L12 23l-6.328-4.219A6 6 0 013 13.79V3.802a1 1 0 01.783-.976zM5 4.604v9.185a4 4 0 001.781 3.328L12 20.597l5.219-3.48A4 4 0 0019 13.79V4.604L12 3.05 5 4.604zM13 10h3l-5 7v-5H8l5-7v5z\" />\n                  </svg>\n                </button>\n          </div>\n\n        </div>\n      </div>\n    </div>\n  </div>\n</div>\n");

    Some(())
}

/// Tier 2 collection & single-card renderer: renders `1..=N` story cards matching
/// `app/views/articles/_single_story.html.erb` into a single pre-allocated UTF-8 HTML buffer.
///
/// Returns `None` if any URL, hex color, timestamp, or strftime pattern falls outside the native
/// domain so the Ruby caller can fall back to `legacy_render_story_cards`.
pub fn render_story_cards(
    static_ctx: &StoryCardStaticContext<'_>,
    view_ctx: &StoryCardViewContext<'_>,
    authors: &[StoryAuthorInput<'_>],
    orgs: &[StoryOrgInput<'_>],
    cards: &[StoryCardInput<'_>],
) -> Option<String> {
    if cards.is_empty() {
        return Some(String::new());
    }

    let prepared_authors: Vec<PreparedStoryAuthor> = authors
        .iter()
        .map(|a| prepare_story_author(a, static_ctx))
        .collect();

    let prepared_orgs: Vec<PreparedStoryOrg> = orgs
        .iter()
        .map(|o| prepare_story_org(o, static_ctx))
        .collect();

    let mut prepared_tags: Vec<PreparedTag<'_>> = Vec::with_capacity(view_ctx.tag_bg_colors.len());
    for &(tag_name, bg_hex) in &view_ctx.tag_bg_colors {
        let monochrome_pill_html =
            render_tag_link(tag_name, tag_name, bg_hex, false, true, "", "")?;
        prepared_tags.push(PreparedTag {
            name: tag_name,
            bg_color_hex: bg_hex,
            monochrome_pill_html,
        });
    }

    let mut out = String::with_capacity(cards.len() * 4800);
    for card in cards {
        render_single_card(
            &mut out,
            static_ctx,
            view_ctx,
            authors,
            &prepared_authors,
            &prepared_orgs,
            &prepared_tags,
            card,
        )?;
    }
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    const MONTHS: [&str; 12] = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];

    fn sample_static_ctx() -> StoryCardStaticContext<'static> {
        StoryCardStaticContext {
            subscription_icon_html: "<a style=\"display: inline;\" href=\"/++\"><img alt=\"Subscriber\" class=\"subscription-icon\" src=\"/assets/sub.png\" /></a>",
            community_leader_icon_html: "<img alt=\"Community Curator\" class=\"community-leader-icon\" src=\"/assets/leader.svg\" />",
            favorites_enabled: true,
            icon_favorite_checked_curation: "<svg class=\"crayons-icon crayons-icon--default mr-1\"></svg>\n",
            icon_pin_svg: "<svg aria-hidden=\"true\" class=\"mr-1 align-text-bottom color-accent-brand\"></svg>\n",
            icon_small_favorite_filled: "<svg class=\"crayons-icon\"><title>Picked as gem</title></svg>\n",
            icon_small_favorite_checked: "<svg class=\"crayons-icon\"><title>Picked as gem by you</title></svg>\n",
            icon_small_comment: "<svg class=\"crayons-icon\"><title>Comments</title></svg>\n",
            icon_small_save_svg: "<svg aria-hidden=\"true\"></svg>\n",
            icon_small_save_filled_svg: "<svg aria-hidden=\"true\"></svg>\n",
            primary_brand_color_hex: "#3b49df",
            escape_html_entities_in_json: true,
            t_users_details_template: "__FOREM_USER__ profile details",
            t_users_follow: "Follow",
            t_for_org_html_template: "<span class=\"crayons-story__tertiary fw-normal\"> for </span>__FOREM_ORG__",
            t_picked_by_you: "Picked by you",
            t_picked_by_user_template: "Picked by @__FOREM_USER__",
            t_favorited: "Picked as gem",
            t_pinned_article: "Pinned",
            t_comments_aria_template: "Add a comment to post - __FOREM_TITLE__",
            t_reactions_count_one_html: "1<span class=\"hidden s:inline\">\u{00a0}reaction</span>",
            t_reactions_count_other_html_template: "__FOREM_COUNT__<span class=\"hidden s:inline\">\u{00a0}reactions</span>",
            t_start_discussion: "Start the discussion",
            t_further_discussion: "Further the discussion",
            t_curation_comments_one: "1 comment",
            t_curation_comments_other_template: "__FOREM_COUNT__ comments",
            t_comments_count_one_html: "1<span class=\"hidden s:inline\">\u{00a0}comment</span>",
            t_comments_count_other_html_template: "__FOREM_COUNT__<span class=\"hidden s:inline\">\u{00a0}comments</span>",
            t_comments_add: "Add\u{00a0}Comment",
            t_reading_time_one: "1 min read",
            t_reading_time_other_template: "__FOREM_COUNT__ min read",
            t_save_aria_template: "Save post __FOREM_TITLE__ to reading list",
            t_save_title_template: "Save post __FOREM_TITLE__ to reading list",
            time_format_short: "%b %-e",
            time_format_short_with_yy: "%b %-d '%y",
            abbr_month_names: MONTHS,
            prior_cloudflare_domain: Some("media.dev.to"),
            current_cloudflare_domain: Some("media2.dev.to"),
        }
    }

    fn sample_view_ctx() -> StoryCardViewContext<'static> {
        StoryCardViewContext {
            feed_style_rich: false,
            curation_view: false,
            show_bookmark_buttons: true,
            assigned_user_id: Some(999),
            current_year: 2026,
            default_base_url: "https://dev.to",
            cover_mode: CoverImageMode::Cloudflare {
                domain: "media2.dev.to",
                directory: "dynamic",
                default_height: "420",
                default_fit: "cover",
            },
            except_flare_tag: None,
            allowed_flare_tags: vec!["discuss", "help", "watercooler"],
            valid_flare_tags: vec!["discuss", "help"],
            reaction_icon_htmls: vec![
                "<img src=\"/assets/multi-unicorn.svg\" width=\"18\" height=\"18\" />",
                "<img src=\"/assets/sparkle-heart.svg\" width=\"18\" height=\"18\" />",
            ],
            tag_bg_colors: vec![
                ("discuss", "#1ad643"),
                ("rust", "#dea584"),
                ("ruby", "#cc342d"),
            ],
        }
    }

    fn sample_author() -> StoryAuthorInput<'static> {
        StoryAuthorInput {
            user_id: 42,
            name: "Alice \"Rust\" & O'Connor",
            username: "alice",
            profile_image_90: "https://dev.to/uploads/alice90.png",
            is_subscriber: true,
            is_community_leader: true,
        }
    }

    fn sample_org() -> StoryOrgInput<'static> {
        StoryOrgInput {
            slug: "forem-org",
            name: "Forem & <Friends>",
            profile_image_90: "https://dev.to/uploads/org90.png",
        }
    }

    fn sample_card(id: i64) -> StoryCardInput<'static> {
        StoryCardInput {
            id,
            author_idx: 0,
            org_idx: Some(0),
            featured: true,
            pinned: true,
            type_of: "full_post",
            title: "Rewriting <Hot> Paths & \" Views '",
            path: "/forem-org/rewriting-hot-paths-100",
            explicit_article_url: None,
            main_image: Some("https://s3.amazonaws.com/bucket/cover.png"),
            explicit_cover_url: None,
            main_image_height: Some(420),
            main_image_bg_hex: Some("#dddddd"),
            video: None,
            video_thumbnail_url: None,
            cloudinary_video_url: None,
            video_duration_str: None,
            context_note_html: Some("<p>Community <strong>context</strong></p>"),
            published: true,
            displayable_published_at: Some((1_772_713_800, 0)), // 2026-03-05T12:30:00Z
            published_at_int: 1_772_713_800,
            cached_tag_list: "discuss, rust, ruby",
            status_body_preview_html: None,
            public_reactions_count: 5,
            reaction_icon_indices: vec![0, 1],
            favorited_by_user_id: Some(77),
            curation_picker_state: 0,
            favorited_by_username: None,
            comments_count: 3,
            reading_time: 4,
        }
    }

    #[test]
    fn render_tag_link_matches_rails_link_to_byte_for_byte() {
        assert_eq!(
            render_tag_link("javascript", "javascript", "#3b49df", false, true, "", "").as_deref(),
            Some(
                "<a class=\"crayons-tag  crayons-tag--monochrome \" style=\"\n        \
                 --tag-bg: rgba(59, 73, 223, 0.10);\n        \
                 --tag-prefix: #3b49df;\n        \
                 --tag-bg-hover: rgba(59, 73, 223, 0.10);\n        \
                 --tag-prefix-hover: #3b49df;\n      \" \
                 href=\"/t/javascript\"><span class=\"crayons-tag__prefix\">#</span>javascript</a>"
            )
        );

        assert_eq!(
            render_tag_link("a\"b<c>&'d", "a\"b<c>&'d", "#3b49df", false, false, "", "").as_deref(),
            Some(
                "<a class=\"crayons-tag   \" style=\"\n        \
                 --tag-bg: rgba(59, 73, 223, 0.10);\n        \
                 --tag-prefix: #3b49df;\n        \
                 --tag-bg-hover: rgba(59, 73, 223, 0.10);\n        \
                 --tag-prefix-hover: #3b49df;\n      \" \
                 href=\"/t/a%22b%3Cc%3E&amp;&#39;d\"><span class=\"crayons-tag__prefix\">#</span>\
                 a&quot;b&lt;c&gt;&amp;&#39;d</a>"
            )
        );

        // Empty route, slash in route, or malformed hex decline cleanly.
        assert!(render_tag_link("x", "", "#3b49df", false, false, "", "").is_none());
        assert!(render_tag_link("x", "a/b", "#3b49df", false, false, "", "").is_none());
        assert!(render_tag_link("x", "x", "#fff", false, false, "", "").is_none());
    }

    #[test]
    fn renders_featured_story_card_with_flare_org_reactions_and_json_data_info() {
        let static_ctx = sample_static_ctx();
        let view_ctx = sample_view_ctx();
        let authors = [sample_author()];
        let orgs = [sample_org()];
        let card = sample_card(100);

        let html = render_story_cards(&static_ctx, &view_ctx, &authors, &orgs, &[card]).unwrap();

        assert!(html.contains("class=\"crayons-story crayons-story--featured\""));
        assert!(
            html.contains("id=\"featured-story-marker\" data-featured-article=\"articles-100\"")
        );
        assert!(html.contains("https://media2.dev.to/dynamic/image/width=1000,height=420,fit=cover,gravity=auto,format=auto/"));
        assert!(html.contains("data-info='{&quot;style&quot;:&quot;full&quot;,&quot;id&quot;:42,&quot;className&quot;:&quot;User&quot;,&quot;name&quot;:&quot;Alice \\&quot;Rust\\&quot; \\u0026 O&#39;Connor&quot;}'"));
        // Flare tag rendered once as filled, excluded from monochrome list
        assert_eq!(html.matches("href=\"/t/discuss\"").count(), 1);
        assert!(html.contains("crayons-tag crayons-tag--filled  "));
        assert!(html.contains("href=\"/t/rust\""));
        assert!(html.contains("href=\"/t/ruby\""));
        assert!(html.contains("data-favorited-by-user-id=\"77\""));
        assert!(html.contains("id=\"article-save-button-100\""));
    }

    #[test]
    fn renders_status_post_with_quickie_title_and_cloudflare_domain_replaced_preview() {
        let static_ctx = sample_static_ctx();
        let view_ctx = sample_view_ctx();
        let authors = [sample_author()];
        let mut card = sample_card(200);
        card.org_idx = None;
        card.featured = false;
        card.pinned = false;
        card.type_of = "status";
        card.title = "Line 1 <tag>\n\nLine 2 https://www.example.com/very/long/url/path/here";
        card.status_body_preview_html = Some("<p><img src=\"https://media.dev.to/img.png\" /></p>");

        let html = render_story_cards(&static_ctx, &view_ctx, &authors, &[], &[card]).unwrap();

        assert!(html.contains("crayons-story__body-status"));
        assert!(!html.contains("crayons-story__tags"));
        assert!(html.contains("<p class=\"quickie-paragraph\">Line 1 &lt;tag&gt;</p><p class=\"quickie-paragraph\">Line 2 <span style=\"text-decoration: underline;\">example.com/very/long/...</span></p>"));
        assert!(html.contains("https://media2.dev.to/img.png"));
    }

    #[test]
    fn renders_curation_view_branches_and_suppresses_author_self_bookmark() {
        let static_ctx = sample_static_ctx();
        let mut view_ctx = sample_view_ctx();
        view_ctx.curation_view = true;
        view_ctx.assigned_user_id = Some(42); // viewer IS the author
        let authors = [sample_author()];

        let mut c0 = sample_card(301);
        c0.org_idx = None;
        c0.featured = false;
        c0.pinned = false;
        c0.comments_count = 0;
        c0.curation_picker_state = 1; // picked_by_you

        let mut c1 = sample_card(302);
        c1.org_idx = None;
        c1.featured = false;
        c1.pinned = false;
        c1.comments_count = 2;
        c1.curation_picker_state = 2; // picked_by_user
        c1.favorited_by_username = Some("curator_jane");

        let html = render_story_cards(&static_ctx, &view_ctx, &authors, &[], &[c0, c1]).unwrap();

        assert!(html.contains("Picked by you"));
        assert!(html.contains("Picked by @curator_jane"));
        assert!(html.contains("Start the discussion"));
        assert!(html.contains("Further the discussion (2 comments)"));
        assert!(!html.contains("data-favorited-marker"));
        assert!(!html.contains("article-save-button-"));
    }
}
