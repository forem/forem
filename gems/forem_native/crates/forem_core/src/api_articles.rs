//! Single-pass streaming JSON serializers for the Forem Articles API
//! (`Api::V0::ArticlesController` and `Api::V1::ArticlesController`:
//! `index`, `show`, `show_by_slug`, `me`, and `search`).
//!
//! Replaces `Article` / `ArticleDecorator` / `Profile` ActiveRecord hydration,
//! per-article `CloudCoverUrl` / `Articles::SocialImage` / `I18n.l` / `FlareTag`
//! Ruby object churn, and ActionView/Jbuilder partial rendering with single-pass
//! Rust streaming serializers:
//!
//! - **Tier 1 composable primitives**:
//!   - [`format_readable_publish_date`] / [`write_readable_publish_date`]:
//!     zero-allocation UTC English short date formatter matching Ruby's
//!     `Article#readable_publish_date` (`%b %-e` in the current year, `%b %-d '%y`
//!     in other years).
//!   - [`format_utc_iso8601_millis`] / [`write_utc_iso8601_millis`]:
//!     zero-allocation UTC ISO-8601 millisecond formatter matching ActiveSupport's
//!     `TimeWithZone#as_json` (`%Y-%m-%dT%H:%M:%S.%3NZ`).
//! - **Tier 2 single-pass pipeline kernels**:
//!   - [`serialize_api_articles_json`]: `/api/articles` index JSON array.
//!   - [`serialize_api_article_show_json`]: `/api/articles/:id` and
//!     `/api/articles/:username/:slug` JSON object (including `body_html` & `body_markdown`).
//!   - [`serialize_api_articles_search_json`]: `/api/articles/search` JSON array
//!     (with optional `body_markdown` for single-hit responses).
//!   - [`serialize_api_articles_me_json`]: `/api/articles/me(/:status)` JSON array.

use std::fmt::Write;

use crate::api_comments::write_utc_iso8601;
use crate::feed::iter_cached_tag_list;
use crate::image::cloudflare_image_url;
use crate::json::write_json_string;
use crate::url::join_url;

const AI_DISCLOSURE_KEYS: [&str; 4] = ["not_disclosed", "no_ai", "some_ai", "fully_autonomous"];

const SHORT_MONTHS: [&str; 12] = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

/// Image optimizer mode resolved once per request from `Images::Optimizer`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImageOptimizerMode {
    /// No image CDN enabled (returns the input URL unchanged).
    Passthrough,
    /// Cloudflare Images CDN enabled (`Images::Optimizer.cloudflare`).
    Cloudflare,
}

/// Flat representation of an article row fetched from PostgreSQL for `/api/articles`.
#[derive(Debug, Clone, Copy)]
pub struct ApiArticleRow<'a> {
    pub id: i64,
    /// Index into deduplicated `users` slice (must be in bounds).
    pub user_idx: i64,
    /// Index into deduplicated `orgs` slice, or `-1` when absent.
    pub org_idx: i64,
    /// Index into deduplicated `base_urls` slice (must be in bounds).
    pub base_url_idx: i64,
    /// Path joined with `base_urls[base_url_idx]` (`"/#{slug}"` for custom domain, else `path`).
    pub url_path: Option<&'a str>,
    pub collection_id: Option<i64>,
    pub title: Option<&'a str>,
    pub description: Option<&'a str>,
    pub main_image: Option<&'a str>,
    pub social_image: Option<&'a str>,
    pub video_thumbnail_url: Option<&'a str>,
    pub cached_tag_list: Option<&'a str>,
    pub slug: Option<&'a str>,
    pub path: Option<&'a str>,
    pub canonical_url: Option<&'a str>,
    pub comments_count: Option<i64>,
    pub public_reactions_count: Option<i64>,
    pub reading_time: Option<i64>,
    pub subforem_id: Option<i64>,
    pub language: Option<&'a str>,
    pub published: bool,
    /// `0` = `not_disclosed`, `1` = `no_ai`, `2` = `some_ai`, `3` = `fully_autonomous`.
    pub ai_disclosure_idx: u8,
    pub created_at_sec: Option<i64>,
    pub edited_at_sec: Option<i64>,
    pub crossposted_at_sec: Option<i64>,
    pub published_at_sec: Option<i64>,
    pub last_comment_at_sec: Option<i64>,
    /// Pre-evaluated `published_at.present? && published_at > Time.zone.local(2026, 3, 1)`
    /// in Ruby so sub-second precision matches `Articles::SocialImage`.
    pub social_image_large: bool,
}

/// Flat representation of an article row fetched from PostgreSQL for `/api/articles/me`.
#[derive(Debug, Clone, Copy)]
pub struct ApiArticleMeRow<'a> {
    pub id: i64,
    /// Index into deduplicated `orgs` slice, or `-1` when absent.
    pub org_idx: i64,
    /// Index into deduplicated `base_urls` slice (must be in bounds).
    pub base_url_idx: i64,
    /// Path joined with `base_urls[base_url_idx]` (`"/#{slug}"` for custom domain, else `path`).
    pub url_path: Option<&'a str>,
    pub title: Option<&'a str>,
    pub description: Option<&'a str>,
    pub published: Option<bool>,
    pub published_at_sec: Option<i64>,
    pub published_at_millis: Option<u32>,
    pub crossposted_at_sec: Option<i64>,
    pub slug: Option<&'a str>,
    pub path: Option<&'a str>,
    pub comments_count: Option<i64>,
    pub public_reactions_count: Option<i64>,
    pub page_views_count: Option<i64>,
    pub body_markdown: Option<&'a str>,
    pub main_image: Option<&'a str>,
    pub cached_tag_list: Option<&'a str>,
    pub canonical_url: Option<&'a str>,
    pub reading_time: Option<i64>,
}

/// Deduplicated user payload for `api/v1/shared/_user.json.jbuilder`.
#[derive(Debug, Clone, Copy)]
pub struct ApiArticleUser<'a> {
    pub id: i64,
    pub name: Option<&'a str>,
    pub username: Option<&'a str>,
    pub twitter_username: Option<&'a str>,
    pub github_username: Option<&'a str>,
    pub website_url: Option<&'a str>,
    pub profile_image: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
}

/// Deduplicated organization payload for `api/v1/shared/_organization.json.jbuilder`.
#[derive(Debug, Clone, Copy)]
pub struct ApiArticleOrganization<'a> {
    pub name: Option<&'a str>,
    pub username: Option<&'a str>,
    pub slug: Option<&'a str>,
    pub profile_image: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
}

/// Flare tag entry matching `FlareTag::FLARE_TAG_IDS_HASH` + `FlareTag.tags_by_id`.
#[derive(Debug, Clone, Copy)]
pub struct ApiArticleFlareTag<'a> {
    /// Key in `FlareTag::FLARE_TAG_IDS_HASH` used to match against `cached_tag_list`.
    pub match_name: &'a str,
    /// `Tag#name` when the tag record exists in `tags_by_id`, or `None` if absent.
    pub name: Option<&'a str>,
    pub bg_color_hex: Option<&'a str>,
    pub text_color_hex: Option<&'a str>,
}

/// Request-level configuration resolved once in Ruby before streaming the batch.
#[derive(Debug, Clone, Copy)]
pub struct ApiArticlesConfig<'a> {
    pub current_year: i64,
    pub main_social_image: &'a str,
    pub cover_image_height: i64,
    pub cover_image_fit: &'a str,
    pub is_development: bool,
    pub optimizer_mode: ImageOptimizerMode,
    pub cloudflare_domain: Option<&'a str>,
    pub cloudflare_directory: &'a str,
    pub ai_disclosure_labels: [&'a str; 4],
    pub escape_html_entities: bool,
}

/// Converts days since Unix epoch (`1970-01-01`) to proleptic Gregorian `(year, month, day)`.
///
/// Uses Howard Hinnant's `civil_from_days` algorithm.
#[inline]
fn civil_from_days(days_since_epoch: i64) -> (i64, u32, u32) {
    let z = days_since_epoch + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097) as u64;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe as i64 + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = if m <= 2 { y + 1 } else { y };
    (year, m as u32, d as u32)
}

/// Writes an English UTC `readable_publish_date` directly into `out`:
/// - `"{Mon} {day}"` when the UTC year equals `current_year` (`%b %-e`)
/// - `"{Mon} {day} '{yy:02}"` otherwise (`%b %-d '%y`)
///
/// Returns `false` if the resolved year falls outside `0..=9999`.
pub fn write_readable_publish_date(out: &mut String, epoch_secs: i64, current_year: i64) -> bool {
    let days = epoch_secs.div_euclid(86_400);
    let (year, month, day) = civil_from_days(days);
    if !(0..=9999).contains(&year) || !(1..=12).contains(&month) {
        return false;
    }

    let mon = SHORT_MONTHS[(month - 1) as usize];
    out.push_str(mon);
    out.push(' ');
    if day >= 10 {
        out.push((b'0' + (day / 10) as u8) as char);
    }
    out.push((b'0' + (day % 10) as u8) as char);

    if year != current_year {
        let yy = (year % 100) as u8;
        out.push_str(" '");
        out.push((b'0' + (yy / 10)) as char);
        out.push((b'0' + (yy % 10)) as char);
    }

    true
}

/// Formats a UTC Unix epoch timestamp into Forem's English `readable_publish_date`.
///
/// Returns `None` if the resolved year is outside `0..=9999`.
pub fn format_readable_publish_date(epoch_secs: i64, current_year: i64) -> Option<String> {
    let mut out = String::with_capacity(12);
    if !write_readable_publish_date(&mut out, epoch_secs, current_year) {
        return None;
    }
    Some(out)
}

/// Writes a UTC ISO-8601 timestamp with 3-digit millisecond precision
/// (`YYYY-MM-DDTHH:MM:SS.mmmZ`), matching ActiveSupport's `TimeWithZone#as_json`
/// when `ActiveSupport::JSON::Encoding.time_precision == 3`.
///
/// Returns `false` if `millis >= 1000` or if the resolved year is outside `0..=9999`.
pub fn write_utc_iso8601_millis(out: &mut String, epoch_secs: i64, millis: u32) -> bool {
    if millis >= 1000 {
        return false;
    }
    if !write_utc_iso8601(out, epoch_secs) {
        return false;
    }
    // Replace trailing 'Z' with `.mmmZ`.
    out.pop();
    out.push('.');
    out.push((b'0' + (millis / 100) as u8) as char);
    out.push((b'0' + ((millis / 10) % 10) as u8) as char);
    out.push((b'0' + (millis % 10) as u8) as char);
    out.push('Z');
    true
}

/// Formats a UTC Unix epoch timestamp with millisecond precision into
/// `"YYYY-MM-DDTHH:MM:SS.mmmZ"`.
///
/// Returns `None` if `millis >= 1000` or if the resolved year is outside `0..=9999`.
pub fn format_utc_iso8601_millis(epoch_secs: i64, millis: u32) -> Option<String> {
    let mut out = String::with_capacity(24);
    if !write_utc_iso8601_millis(&mut out, epoch_secs, millis) {
        return None;
    }
    Some(out)
}

#[inline]
fn is_ruby_ascii_ws(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0b | 0x0c)
}

/// Checks blankness matching ActiveSupport's `String#blank?`.
///
/// Returns `Some(true)` if definitely blank, `Some(false)` if definitely non-blank,
/// or `None` if the string contains non-ASCII bytes that might be Unicode whitespace
/// (deferring to Ruby for exact `blank?` parity).
pub(crate) fn check_blank(s: &str) -> Option<bool> {
    if s.is_empty() {
        return Some(true);
    }
    if s.bytes().any(|b| !b.is_ascii()) {
        // Contains at least one non-ASCII char: if any byte is ASCII non-whitespace, it's definitely present.
        if s.bytes().any(|b| b.is_ascii() && !is_ruby_ascii_ws(b)) {
            return Some(false);
        }
        return None;
    }
    Some(s.bytes().all(is_ruby_ascii_ws))
}

/// Trims ASCII whitespace (plus trailing NUL, matching Ruby's `String#strip`) for `canonical_url`.
///
/// Returns:
/// - `Some(Some(trimmed))` when `present?` and safely trimmed
/// - `Some(None)` when `blank?` (caller should fall back to `article_url`)
/// - `None` when out-of-domain (non-ASCII boundary bytes or NUL edge cases)
fn trim_canonical_url(raw: Option<&str>) -> Option<Option<&str>> {
    let s = match raw {
        None => return Some(None),
        Some(v) => v,
    };
    if s.is_empty() {
        return Some(None);
    }
    let bytes = s.as_bytes();
    // Fast path: starts and ends with printable ASCII non-whitespace -> already stripped & present.
    if bytes[0] > 0x20
        && bytes[0] < 0x7f
        && bytes[bytes.len() - 1] > 0x20
        && bytes[bytes.len() - 1] < 0x7f
    {
        return Some(Some(s));
    }
    if !s.is_ascii() || bytes.contains(&0) {
        return None;
    }
    let mut start = 0;
    let mut end = bytes.len();
    while start < end && is_ruby_ascii_ws(bytes[start]) {
        start += 1;
    }
    while end > start && is_ruby_ascii_ws(bytes[end - 1]) {
        end -= 1;
    }
    if start == end {
        Some(None)
    } else {
        Some(Some(&s[start..end]))
    }
}

fn strip_cloudinary_w1000_prefix(url: &str, require_cloudinary_host: bool) -> Option<&str> {
    if require_cloudinary_host && !url.starts_with("https://res.cloudinary.com/") {
        return Some(url);
    }
    if !url.contains("w_1000/https://") {
        return Some(url);
    }
    if url.ends_with("w_1000/") {
        return None;
    }
    Some(url.rsplit_once("w_1000/").map_or(url, |(_, tail)| tail))
}

/// Applies `Images::Optimizer.call` semantics for `Passthrough` or `Cloudflare` modes.
///
/// Returns `None` to defer to Ruby when the URL starts with the Cloudflare prefix
/// (requiring `extract_suffix_url` / `CGI.unescape`) or when `cloudflare_image_url`
/// declines (non-NFC-stable characters).
pub(crate) fn optimize_image_url(
    img_src: &str,
    width: &str,
    height: &str,
    crop: &str,
    config: &ApiArticlesConfig<'_>,
) -> Option<String> {
    if check_blank(img_src)? || img_src.starts_with('/') || img_src.contains("/agent_sessions/") {
        return Some(img_src.to_string());
    }

    match config.optimizer_mode {
        ImageOptimizerMode::Passthrough => Some(img_src.to_string()),
        ImageOptimizerMode::Cloudflare => {
            let domain = config.cloudflare_domain?;
            let dir = config.cloudflare_directory;
            // Check `img_src.starts_with("https://{domain}/{dir}/image")` without allocating.
            if let Some(rest) = img_src.strip_prefix("https://") {
                if let Some(after_domain) = rest.strip_prefix(domain) {
                    if let Some(after_slash) = after_domain.strip_prefix('/') {
                        if let Some(after_dir) = after_slash.strip_prefix(dir) {
                            if after_dir.starts_with("/image") {
                                return None;
                            }
                        }
                    }
                }
            }
            let fit = if crop == "crop" {
                "cover"
            } else {
                "scale-down"
            };
            cloudflare_image_url(domain, dir, width, height, fit, img_src, img_src)
        }
    }
}

pub(crate) fn write_opt_str(out: &mut String, value: Option<&str>, escape_html: bool) {
    match value {
        Some(s) => write_json_string(out, s, escape_html),
        None => out.push_str("null"),
    }
}

pub(crate) fn write_opt_i64(out: &mut String, value: Option<i64>) {
    match value {
        Some(n) => {
            let _ = write!(out, "{n}");
        }
        None => out.push_str("null"),
    }
}

pub(crate) fn write_opt_utc_iso8601(out: &mut String, epoch_secs: Option<i64>) -> bool {
    match epoch_secs {
        Some(secs) => {
            out.push('"');
            if !write_utc_iso8601(out, secs) {
                return false;
            }
            out.push('"');
            true
        }
        None => {
            out.push_str("null");
            true
        }
    }
}

pub(crate) fn write_user_object(out: &mut String, user: &ApiArticleUser<'_>, escape_html: bool) {
    out.push_str("{\"name\":");
    write_opt_str(out, user.name, escape_html);
    out.push_str(",\"username\":");
    write_opt_str(out, user.username, escape_html);
    out.push_str(",\"twitter_username\":");
    write_opt_str(out, user.twitter_username, escape_html);
    out.push_str(",\"github_username\":");
    write_opt_str(out, user.github_username, escape_html);
    out.push_str(",\"user_id\":");
    let _ = write!(out, "{}", user.id);
    out.push_str(",\"website_url\":");
    write_opt_str(out, user.website_url, escape_html);
    out.push_str(",\"profile_image\":");
    write_opt_str(out, user.profile_image, escape_html);
    out.push_str(",\"profile_image_90\":");
    write_opt_str(out, user.profile_image_90, escape_html);
    out.push('}');
}

pub(crate) fn write_organization_object(
    out: &mut String,
    org: &ApiArticleOrganization<'_>,
    escape_html: bool,
) {
    out.push_str("{\"name\":");
    write_opt_str(out, org.name, escape_html);
    out.push_str(",\"username\":");
    write_opt_str(out, org.username, escape_html);
    out.push_str(",\"slug\":");
    write_opt_str(out, org.slug, escape_html);
    out.push_str(",\"profile_image\":");
    write_opt_str(out, org.profile_image, escape_html);
    out.push_str(",\"profile_image_90\":");
    write_opt_str(out, org.profile_image_90, escape_html);
    out.push('}');
}

fn match_flare_tag<'a>(
    cached_tag_list: Option<&str>,
    flare_tags: &'a [ApiArticleFlareTag<'a>],
) -> Option<&'a ApiArticleFlareTag<'a>> {
    if flare_tags.is_empty() {
        return None;
    }
    let raw = cached_tag_list?;
    if raw.is_empty() {
        return None;
    }
    for tag in iter_cached_tag_list(raw) {
        if let Some(ft) = flare_tags.iter().find(|f| f.match_name == tag) {
            return Some(ft);
        }
    }
    None
}

fn compute_cover_image(
    main_image: Option<&str>,
    cover_height_str: &str,
    config: &ApiArticlesConfig<'_>,
) -> Option<Option<String>> {
    match main_image {
        Some(raw_main) if !check_blank(raw_main)? => {
            if config.is_development {
                Some(Some(raw_main.to_string()))
            } else {
                let (h_str, crop) = if raw_main.contains("ytimg.com") {
                    ("500", "crop")
                } else {
                    (cover_height_str, config.cover_image_fit)
                };
                let img_src = strip_cloudinary_w1000_prefix(raw_main, true)?;
                Some(Some(optimize_image_url(
                    img_src, "1000", h_str, crop, config,
                )?))
            }
        }
        _ => Some(None),
    }
}

fn write_tag_list_array(out: &mut String, cached_tag_list: Option<&str>, escape_html: bool) {
    out.push('[');
    if let Some(raw_tags) = cached_tag_list {
        for (tag_idx, tag) in iter_cached_tag_list(raw_tags).enumerate() {
            if tag_idx > 0 {
                out.push(',');
            }
            write_json_string(out, tag, escape_html);
        }
    }
    out.push(']');
}

fn write_user_org_flare_tail(
    out: &mut String,
    cached_tag_list: Option<&str>,
    user: &ApiArticleUser<'_>,
    org: Option<&ApiArticleOrganization<'_>>,
    flare_tags: &[ApiArticleFlareTag<'_>],
    escape_html: bool,
) {
    out.push_str(",\"user\":");
    write_user_object(out, user, escape_html);

    if let Some(org) = org {
        out.push_str(",\"organization\":");
        write_organization_object(out, org, escape_html);
    }

    if let Some(ft) = match_flare_tag(cached_tag_list, flare_tags) {
        if ft.name.is_some() {
            out.push_str(",\"flare_tag\":{\"name\":");
            write_opt_str(out, ft.name, escape_html);
            out.push_str(",\"bg_color_hex\":");
            write_opt_str(out, ft.bg_color_hex, escape_html);
            out.push_str(",\"text_color_hex\":");
            write_opt_str(out, ft.text_color_hex, escape_html);
            out.push('}');
        }
    }

    out.push('}');
}

/// Writes the shared `api/v*/articles/_article.json.jbuilder` fields from `{`
/// through `reading_time_minutes`.
pub(crate) fn write_article_common_fields(
    out: &mut String,
    article: &ApiArticleRow<'_>,
    base_url: &str,
    cover_height_str: &str,
    config: &ApiArticlesConfig<'_>,
) -> Option<()> {
    let escape_html = config.escape_html_entities;
    let article_url = match article.url_path {
        Some(p) => join_url(base_url, p)?,
        None => base_url.to_string(),
    };

    let ai_idx = usize::from(article.ai_disclosure_idx);
    let ai_key = *AI_DISCLOSURE_KEYS.get(ai_idx)?;
    let ai_label = *config.ai_disclosure_labels.get(ai_idx)?;

    let displayable_sec = article.crossposted_at_sec.or(article.published_at_sec);
    let canonical = trim_canonical_url(article.canonical_url)?.unwrap_or(article_url.as_str());
    let cover_image = compute_cover_image(article.main_image, cover_height_str, config)?;

    // Compute social_image (Articles::SocialImage#url).
    let social_src = match article.main_image {
        Some(s) if !check_blank(s)? => Some(s),
        _ => match article.social_image {
            Some(s) if !check_blank(s)? => Some(s),
            _ => match article.video_thumbnail_url {
                Some(s) if !check_blank(s)? => Some(s),
                _ => None,
            },
        },
    };
    let social_image_owned: Option<String> = match social_src {
        Some(raw_img) => {
            let (w, h) = if article.social_image_large {
                ("1200", "627")
            } else {
                ("1000", "500")
            };
            let img_src = strip_cloudinary_w1000_prefix(raw_img, false)?;
            Some(optimize_image_url(img_src, w, h, "crop", config)?)
        }
        None => None,
    };
    let social_image = social_image_owned
        .as_deref()
        .unwrap_or(config.main_social_image);

    out.push_str("{\"type_of\":\"article\",\"id\":");
    let _ = write!(out, "{}", article.id);

    out.push_str(",\"title\":");
    write_opt_str(out, article.title, escape_html);

    out.push_str(",\"description\":");
    write_opt_str(out, article.description, escape_html);

    out.push_str(",\"readable_publish_date\":");
    match displayable_sec {
        Some(secs) => {
            out.push('"');
            if !write_readable_publish_date(out, secs, config.current_year) {
                return None;
            }
            out.push('"');
        }
        None => out.push_str("null"),
    }

    out.push_str(",\"slug\":");
    write_opt_str(out, article.slug, escape_html);

    out.push_str(",\"path\":");
    write_opt_str(out, article.path, escape_html);

    out.push_str(",\"url\":");
    write_json_string(out, &article_url, escape_html);

    out.push_str(",\"comments_count\":");
    write_opt_i64(out, article.comments_count);

    out.push_str(",\"public_reactions_count\":");
    write_opt_i64(out, article.public_reactions_count);

    out.push_str(",\"collection_id\":");
    write_opt_i64(out, article.collection_id);

    out.push_str(",\"published_timestamp\":\"");
    if article.published {
        if let Some(secs) = displayable_sec {
            if !write_utc_iso8601(out, secs) {
                return None;
            }
        }
    }
    out.push('"');

    out.push_str(",\"language\":");
    write_opt_str(out, article.language, escape_html);

    out.push_str(",\"subforem_id\":");
    write_opt_i64(out, article.subforem_id);

    out.push_str(",\"ai_disclosure_level\":\"");
    out.push_str(ai_key);
    out.push_str("\",\"ai_disclosure_label\":");
    write_json_string(out, ai_label, escape_html);

    out.push_str(",\"positive_reactions_count\":");
    write_opt_i64(out, article.public_reactions_count);

    out.push_str(",\"cover_image\":");
    write_opt_str(out, cover_image.as_deref(), escape_html);

    out.push_str(",\"social_image\":");
    write_json_string(out, social_image, escape_html);

    out.push_str(",\"canonical_url\":");
    write_json_string(out, canonical, escape_html);

    out.push_str(",\"created_at\":");
    if !write_opt_utc_iso8601(out, article.created_at_sec) {
        return None;
    }

    out.push_str(",\"edited_at\":");
    if !write_opt_utc_iso8601(out, article.edited_at_sec) {
        return None;
    }

    out.push_str(",\"crossposted_at\":");
    if !write_opt_utc_iso8601(out, article.crossposted_at_sec) {
        return None;
    }

    out.push_str(",\"published_at\":");
    if !write_opt_utc_iso8601(out, article.published_at_sec) {
        return None;
    }

    out.push_str(",\"last_comment_at\":");
    if !write_opt_utc_iso8601(out, article.last_comment_at_sec) {
        return None;
    }

    out.push_str(",\"reading_time_minutes\":");
    write_opt_i64(out, article.reading_time);

    Some(())
}

fn serialize_api_articles_array(
    articles: &[ApiArticleRow<'_>],
    single_body_markdown: Option<Option<&str>>,
    users: &[ApiArticleUser<'_>],
    orgs: &[ApiArticleOrganization<'_>],
    flare_tags: &[ApiArticleFlareTag<'_>],
    base_urls: &[&str],
    config: &ApiArticlesConfig<'_>,
) -> Option<String> {
    if articles.is_empty() {
        return if single_body_markdown.is_none() {
            Some("[]".to_string())
        } else {
            None
        };
    }
    if single_body_markdown.is_some() && articles.len() != 1 {
        return None;
    }

    let escape_html = config.escape_html_entities;
    let cover_height_str = config.cover_image_height.to_string();
    let md_extra = single_body_markdown
        .flatten()
        .map_or(0, |s| s.len() + s.len() / 8 + 32);
    let mut out = String::with_capacity(
        articles
            .len()
            .saturating_mul(1100)
            .saturating_add(md_extra)
            .saturating_add(16),
    );
    out.push('[');

    for (idx, article) in articles.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }

        let user_idx = usize::try_from(article.user_idx).ok()?;
        let user = users.get(user_idx)?;

        let org = if article.org_idx >= 0 {
            let org_idx = usize::try_from(article.org_idx).ok()?;
            Some(orgs.get(org_idx)?)
        } else if article.org_idx == -1 {
            None
        } else {
            return None;
        };

        let base_url_idx = usize::try_from(article.base_url_idx).ok()?;
        let base_url = *base_urls.get(base_url_idx)?;

        write_article_common_fields(&mut out, article, base_url, &cover_height_str, config)?;

        if let Some(body_md) = single_body_markdown {
            out.push_str(",\"body_markdown\":");
            write_opt_str(&mut out, body_md, escape_html);
        }

        out.push_str(",\"tag_list\":");
        write_tag_list_array(&mut out, article.cached_tag_list, escape_html);

        out.push_str(",\"tags\":");
        write_opt_str(&mut out, article.cached_tag_list, escape_html);

        write_user_org_flare_tail(
            &mut out,
            article.cached_tag_list,
            user,
            org,
            flare_tags,
            escape_html,
        );
    }

    out.push(']');
    Some(out)
}

/// Streams the complete `/api/articles` (v0 & v1) JSON array into a single pre-sized buffer.
///
/// Returns `None` whenever any article row, URL, image, or timestamp falls outside the
/// strict fast-path domain so the controller can transparently fall back to `legacy_index`.
pub fn serialize_api_articles_json(
    articles: &[ApiArticleRow<'_>],
    users: &[ApiArticleUser<'_>],
    orgs: &[ApiArticleOrganization<'_>],
    flare_tags: &[ApiArticleFlareTag<'_>],
    base_urls: &[&str],
    config: &ApiArticlesConfig<'_>,
) -> Option<String> {
    serialize_api_articles_array(articles, None, users, orgs, flare_tags, base_urls, config)
}

/// Streams the complete `/api/articles/search` (v0 & v1) JSON array into a single pre-sized buffer.
///
/// When `single_body_markdown` is `Some(opt_md)` (single-result search), emits `"body_markdown"`
/// right after `"reading_time_minutes"` matching `search.json.jbuilder`.
pub fn serialize_api_articles_search_json(
    articles: &[ApiArticleRow<'_>],
    single_body_markdown: Option<Option<&str>>,
    users: &[ApiArticleUser<'_>],
    orgs: &[ApiArticleOrganization<'_>],
    flare_tags: &[ApiArticleFlareTag<'_>],
    base_urls: &[&str],
    config: &ApiArticlesConfig<'_>,
) -> Option<String> {
    serialize_api_articles_array(
        articles,
        single_body_markdown,
        users,
        orgs,
        flare_tags,
        base_urls,
        config,
    )
}

/// Streams the complete `/api/articles/:id` and `/api/articles/:username/:slug` (v0 & v1)
/// JSON object into a single pre-sized buffer, including `body_html` and `body_markdown`.
///
/// Note: matching `show.json.jbuilder` (see forem/forem#4206), `tag_list` is the raw
/// comma-separated string and `tags` is the tag array — opposite of `/api/articles` index.
#[allow(clippy::too_many_arguments)]
pub fn serialize_api_article_show_json(
    article: &ApiArticleRow<'_>,
    body_html: Option<&str>,
    body_markdown: Option<&str>,
    users: &[ApiArticleUser<'_>],
    orgs: &[ApiArticleOrganization<'_>],
    flare_tags: &[ApiArticleFlareTag<'_>],
    base_urls: &[&str],
    config: &ApiArticlesConfig<'_>,
) -> Option<String> {
    let user_idx = usize::try_from(article.user_idx).ok()?;
    let user = users.get(user_idx)?;

    let org = if article.org_idx >= 0 {
        let org_idx = usize::try_from(article.org_idx).ok()?;
        Some(orgs.get(org_idx)?)
    } else if article.org_idx == -1 {
        None
    } else {
        return None;
    };

    let base_url_idx = usize::try_from(article.base_url_idx).ok()?;
    let base_url = *base_urls.get(base_url_idx)?;

    let escape_html = config.escape_html_entities;
    let cover_height_str = config.cover_image_height.to_string();
    let body_bytes = body_html.map_or(0, str::len) + body_markdown.map_or(0, str::len);
    let mut out = String::with_capacity(
        1400usize
            .saturating_add(body_bytes)
            .saturating_add(body_bytes / 8),
    );

    write_article_common_fields(&mut out, article, base_url, &cover_height_str, config)?;

    out.push_str(",\"tag_list\":");
    write_opt_str(&mut out, article.cached_tag_list, escape_html);

    out.push_str(",\"tags\":");
    write_tag_list_array(&mut out, article.cached_tag_list, escape_html);

    out.push_str(",\"body_html\":");
    write_opt_str(&mut out, body_html, escape_html);

    out.push_str(",\"body_markdown\":");
    write_opt_str(&mut out, body_markdown, escape_html);

    write_user_org_flare_tail(
        &mut out,
        article.cached_tag_list,
        user,
        org,
        flare_tags,
        escape_html,
    );

    Some(out)
}

/// Streams the complete `/api/articles/me(/:status)` (v0 & v1) JSON array into a single
/// pre-sized buffer, matching `api/v*/articles/me.json.jbuilder` key-for-key.
pub fn serialize_api_articles_me_json(
    articles: &[ApiArticleMeRow<'_>],
    user: &ApiArticleUser<'_>,
    orgs: &[ApiArticleOrganization<'_>],
    flare_tags: &[ApiArticleFlareTag<'_>],
    base_urls: &[&str],
    config: &ApiArticlesConfig<'_>,
) -> Option<String> {
    if articles.is_empty() {
        return Some("[]".to_string());
    }

    let escape_html = config.escape_html_entities;
    let cover_height_str = config.cover_image_height.to_string();
    let md_total: usize = articles
        .iter()
        .map(|a| a.body_markdown.map_or(0, str::len))
        .sum();
    let mut out = String::with_capacity(
        articles
            .len()
            .saturating_mul(900)
            .saturating_add(md_total)
            .saturating_add(md_total / 8)
            .saturating_add(16),
    );
    out.push('[');

    for (idx, article) in articles.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }

        let org = if article.org_idx >= 0 {
            let org_idx = usize::try_from(article.org_idx).ok()?;
            Some(orgs.get(org_idx)?)
        } else if article.org_idx == -1 {
            None
        } else {
            return None;
        };

        let base_url_idx = usize::try_from(article.base_url_idx).ok()?;
        let base_url = *base_urls.get(base_url_idx)?;
        let article_url = match article.url_path {
            Some(p) => join_url(base_url, p)?,
            None => base_url.to_string(),
        };

        let displayable_sec = article.crossposted_at_sec.or(article.published_at_sec);
        let canonical = trim_canonical_url(article.canonical_url)?.unwrap_or(article_url.as_str());
        let cover_image = compute_cover_image(article.main_image, &cover_height_str, config)?;

        out.push_str("{\"type_of\":\"article\",\"id\":");
        let _ = write!(out, "{}", article.id);

        out.push_str(",\"title\":");
        write_opt_str(&mut out, article.title, escape_html);

        out.push_str(",\"description\":");
        write_opt_str(&mut out, article.description, escape_html);

        out.push_str(",\"published\":");
        match article.published {
            Some(true) => out.push_str("true"),
            Some(false) => out.push_str("false"),
            None => out.push_str("null"),
        }

        out.push_str(",\"published_at\":");
        match (article.published_at_sec, article.published_at_millis) {
            (Some(secs), Some(millis)) => {
                out.push('"');
                if !write_utc_iso8601_millis(&mut out, secs, millis) {
                    return None;
                }
                out.push('"');
            }
            (None, None) => out.push_str("null"),
            _ => return None,
        }

        out.push_str(",\"slug\":");
        write_opt_str(&mut out, article.slug, escape_html);

        out.push_str(",\"path\":");
        write_opt_str(&mut out, article.path, escape_html);

        out.push_str(",\"url\":");
        write_json_string(&mut out, &article_url, escape_html);

        out.push_str(",\"comments_count\":");
        write_opt_i64(&mut out, article.comments_count);

        out.push_str(",\"public_reactions_count\":");
        write_opt_i64(&mut out, article.public_reactions_count);

        out.push_str(",\"page_views_count\":");
        write_opt_i64(&mut out, article.page_views_count);

        out.push_str(",\"published_timestamp\":\"");
        if article.published == Some(true) {
            if let Some(secs) = displayable_sec {
                if !write_utc_iso8601(&mut out, secs) {
                    return None;
                }
            }
        }
        out.push('"');

        out.push_str(",\"body_markdown\":");
        write_opt_str(&mut out, article.body_markdown, escape_html);

        out.push_str(",\"positive_reactions_count\":");
        write_opt_i64(&mut out, article.public_reactions_count);

        out.push_str(",\"cover_image\":");
        write_opt_str(&mut out, cover_image.as_deref(), escape_html);

        out.push_str(",\"tag_list\":");
        write_tag_list_array(&mut out, article.cached_tag_list, escape_html);

        out.push_str(",\"canonical_url\":");
        write_json_string(&mut out, canonical, escape_html);

        out.push_str(",\"reading_time_minutes\":");
        write_opt_i64(&mut out, article.reading_time);

        write_user_org_flare_tail(
            &mut out,
            article.cached_tag_list,
            user,
            org,
            flare_tags,
            escape_html,
        );
    }

    out.push(']');
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_config() -> ApiArticlesConfig<'static> {
        ApiArticlesConfig {
            current_year: 2026,
            main_social_image: "https://dev.to/assets/default-social.png",
            cover_image_height: 420,
            cover_image_fit: "crop",
            is_development: false,
            optimizer_mode: ImageOptimizerMode::Passthrough,
            cloudflare_domain: None,
            cloudflare_directory: "cdn-cgi",
            ai_disclosure_labels: [
                "Not disclosed",
                "Human written",
                "AI assisted",
                "Fully autonomous",
            ],
            escape_html_entities: true,
        }
    }

    fn sample_user() -> ApiArticleUser<'static> {
        ApiArticleUser {
            id: 42,
            name: Some("Ada Lovelace"),
            username: Some("ada"),
            twitter_username: Some("ada_tw"),
            github_username: Some("ada_gh"),
            website_url: Some("https://ada.example"),
            profile_image: Some("https://img.example/ada-640.png"),
            profile_image_90: Some("https://img.example/ada-90.png"),
        }
    }

    fn sample_article() -> ApiArticleRow<'static> {
        ApiArticleRow {
            id: 101,
            user_idx: 0,
            org_idx: -1,
            base_url_idx: 0,
            url_path: Some("/ada/hello-world"),
            collection_id: Some(7),
            title: Some("Hello <World>"),
            description: Some("Intro post"),
            main_image: Some("https://img.example/cover.png"),
            social_image: None,
            video_thumbnail_url: None,
            cached_tag_list: Some("ruby, discuss, rust"),
            slug: Some("hello-world"),
            path: Some("/ada/hello-world"),
            canonical_url: None,
            comments_count: Some(5),
            public_reactions_count: Some(12),
            reading_time: Some(3),
            subforem_id: Some(1),
            language: Some("en"),
            published: true,
            ai_disclosure_idx: 1,
            created_at_sec: Some(1_772_409_600), // 2026-03-02T00:00:00Z
            edited_at_sec: None,
            crossposted_at_sec: None,
            published_at_sec: Some(1_772_409_600),
            last_comment_at_sec: Some(1_772_496_000),
            social_image_large: true,
        }
    }

    #[test]
    fn formats_readable_publish_date_same_and_different_years() {
        // 2026-03-02T00:00:00Z
        assert_eq!(
            format_readable_publish_date(1_772_409_600, 2026).as_deref(),
            Some("Mar 2")
        );
        assert_eq!(
            format_readable_publish_date(1_772_409_600, 2025).as_deref(),
            Some("Mar 2 '26")
        );
        // 2000-01-05T12:00:00Z -> two-digit zero-padded '00
        assert_eq!(
            format_readable_publish_date(947_073_600, 2026).as_deref(),
            Some("Jan 5 '00")
        );
        // 2024-02-29T23:59:59Z (leap day)
        assert_eq!(
            format_readable_publish_date(1_709_251_199, 2024).as_deref(),
            Some("Feb 29")
        );
        // Out of range year (> 9999)
        assert_eq!(format_readable_publish_date(253_402_300_800, 2026), None);
    }

    #[test]
    fn serializes_empty_articles() {
        let cfg = sample_config();
        assert_eq!(
            serialize_api_articles_json(&[], &[], &[], &[], &[], &cfg).as_deref(),
            Some("[]")
        );
    }

    #[test]
    fn serializes_article_with_org_and_flare_tag() {
        let mut article = sample_article();
        article.org_idx = 0;
        let users = [sample_user()];
        let orgs = [ApiArticleOrganization {
            name: Some("Forem"),
            username: Some("forem"),
            slug: Some("forem"),
            profile_image: Some("https://img.example/org-640.png"),
            profile_image_90: Some("https://img.example/org-90.png"),
        }];
        let flare_tags = [ApiArticleFlareTag {
            match_name: "discuss",
            name: Some("discuss"),
            bg_color_hex: Some("#71EA8B"),
            text_color_hex: Some("#FFFFFF"),
        }];
        let base_urls = ["https://dev.to"];
        let cfg = sample_config();

        let json =
            serialize_api_articles_json(&[article], &users, &orgs, &flare_tags, &base_urls, &cfg)
                .unwrap();

        assert!(json.contains("\"type_of\":\"article\",\"id\":101"));
        assert!(json.contains("\"title\":\"Hello \\u003cWorld\\u003e\""));
        assert!(json.contains("\"readable_publish_date\":\"Mar 2\""));
        assert!(json.contains("\"url\":\"https://dev.to/ada/hello-world\""));
        assert!(json.contains("\"canonical_url\":\"https://dev.to/ada/hello-world\""));
        assert!(json.contains("\"published_timestamp\":\"2026-03-02T00:00:00Z\""));
        assert!(json.contains(
            "\"ai_disclosure_level\":\"no_ai\",\"ai_disclosure_label\":\"Human written\""
        ));
        assert!(json.contains("\"tag_list\":[\"ruby\",\"discuss\",\"rust\"]"));
        assert!(json.contains("\"tags\":\"ruby, discuss, rust\""));
        assert!(json.contains("\"organization\":{\"name\":\"Forem\""));
        assert!(json.contains("\"flare_tag\":{\"name\":\"discuss\",\"bg_color_hex\":\"#71EA8B\",\"text_color_hex\":\"#FFFFFF\"}"));
    }

    #[test]
    fn cloudflare_mode_optimizes_cover_and_social_images() {
        let mut cfg = sample_config();
        cfg.optimizer_mode = ImageOptimizerMode::Cloudflare;
        cfg.cloudflare_domain = Some("media2.dev.to");

        let article = sample_article();
        let users = [sample_user()];
        let base_urls = ["https://dev.to"];

        let json =
            serialize_api_articles_json(&[article], &users, &[], &[], &base_urls, &cfg).unwrap();

        assert!(json.contains(
            "\"cover_image\":\"https://media2.dev.to/cdn-cgi/image/width=1000,height=420,fit=cover,gravity=auto,format=auto/https%3A%2F%2Fimg.example%2Fcover.png\""
        ));
        // social_image_large = true -> 1200x627 (including sub-second past midnight cutoff)
        assert!(json.contains(
            "\"social_image\":\"https://media2.dev.to/cdn-cgi/image/width=1200,height=627,fit=cover,gravity=auto,format=auto/https%3A%2F%2Fimg.example%2Fcover.png\""
        ));

        // Exact midnight cutoff (social_image_large = false) -> 1000x500
        let mut exact_cutoff = sample_article();
        exact_cutoff.published_at_sec = Some(1_772_323_200);
        exact_cutoff.social_image_large = false;
        let json_small =
            serialize_api_articles_json(&[exact_cutoff], &users, &[], &[], &base_urls, &cfg)
                .unwrap();
        assert!(json_small.contains(
            "\"social_image\":\"https://media2.dev.to/cdn-cgi/image/width=1000,height=500,fit=cover,gravity=auto,format=auto/https%3A%2F%2Fimg.example%2Fcover.png\""
        ));
    }

    #[test]
    fn defers_on_cloudflare_prefixed_url_or_invalid_indices() {
        let mut cfg = sample_config();
        cfg.optimizer_mode = ImageOptimizerMode::Cloudflare;
        cfg.cloudflare_domain = Some("media2.dev.to");

        let mut article = sample_article();
        article.main_image =
            Some("https://media2.dev.to/cdn-cgi/image/width=500/https://a.com/b.png");
        let users = [sample_user()];
        let base_urls = ["https://dev.to"];
        assert_eq!(
            serialize_api_articles_json(&[article], &users, &[], &[], &base_urls, &cfg),
            None
        );

        let mut bad_user = sample_article();
        bad_user.user_idx = 99;
        assert_eq!(
            serialize_api_articles_json(
                &[bad_user],
                &users,
                &[],
                &[],
                &base_urls,
                &sample_config()
            ),
            None
        );
    }

    #[test]
    fn flare_tag_without_db_record_omits_without_falling_through() {
        let article = sample_article();
        let users = [sample_user()];
        let flare_tags = [
            ApiArticleFlareTag {
                match_name: "discuss",
                name: None,
                bg_color_hex: None,
                text_color_hex: None,
            },
            ApiArticleFlareTag {
                match_name: "rust",
                name: Some("rust"),
                bg_color_hex: Some("#000"),
                text_color_hex: Some("#fff"),
            },
        ];
        let base_urls = ["https://dev.to"];
        let json = serialize_api_articles_json(
            &[article],
            &users,
            &[],
            &flare_tags,
            &base_urls,
            &sample_config(),
        )
        .unwrap();

        assert!(!json.contains("\"flare_tag\""));
    }

    #[test]
    fn format_utc_iso8601_millis_matches_activesupport() {
        assert_eq!(
            format_utc_iso8601_millis(1_795_528_285, 0).as_deref(),
            Some("2026-11-24T13:51:25.000Z")
        );
        assert_eq!(
            format_utc_iso8601_millis(1_795_528_285, 7).as_deref(),
            Some("2026-11-24T13:51:25.007Z")
        );
        assert_eq!(
            format_utc_iso8601_millis(1_795_528_285, 42).as_deref(),
            Some("2026-11-24T13:51:25.042Z")
        );
        assert_eq!(
            format_utc_iso8601_millis(1_795_528_285, 999).as_deref(),
            Some("2026-11-24T13:51:25.999Z")
        );
        assert_eq!(format_utc_iso8601_millis(1_795_528_285, 1000), None);
        assert_eq!(format_utc_iso8601_millis(-62_167_219_201, 0), None);
    }

    #[test]
    fn serialize_api_article_show_swaps_tags_and_streams_bodies() {
        let mut article = sample_article();
        article.org_idx = 0;
        let users = [sample_user()];
        let orgs = [ApiArticleOrganization {
            name: Some("Forem"),
            username: Some("forem"),
            slug: Some("forem"),
            profile_image: Some("https://img.example/org640.png"),
            profile_image_90: Some("https://img.example/org90.png"),
        }];
        let flare_tags = [ApiArticleFlareTag {
            match_name: "discuss",
            name: Some("discuss"),
            bg_color_hex: Some("#71EA8B"),
            text_color_hex: Some("#FFFFFF"),
        }];
        let base_urls = ["https://dev.to"];
        let cfg = sample_config();

        let json = serialize_api_article_show_json(
            &article,
            Some("<p>Hello &amp; <b>Rust</b></p>"),
            Some("# Hello\n\nRust > Ruby"),
            &users,
            &orgs,
            &flare_tags,
            &base_urls,
            &cfg,
        )
        .unwrap();

        assert!(json.starts_with("{\"type_of\":\"article\",\"id\":101,"));
        assert!(json.ends_with('}'));
        // Opposite of index: tag_list is string, tags is array.
        assert!(json.contains(
            "\"tag_list\":\"ruby, discuss, rust\",\"tags\":[\"ruby\",\"discuss\",\"rust\"]"
        ));
        assert!(json.contains(
            "\"body_html\":\"\\u003cp\\u003eHello \\u0026amp; \\u003cb\\u003eRust\\u003c/b\\u003e\\u003c/p\\u003e\""
        ));
        assert!(json.contains("\"body_markdown\":\"# Hello\\n\\nRust \\u003e Ruby\""));
        assert!(json.contains("\"organization\":{\"name\":\"Forem\""));
        assert!(json.contains("\"flare_tag\":{\"name\":\"discuss\""));
    }

    #[test]
    fn serialize_api_articles_search_includes_markdown_only_for_single_hit() {
        let article = sample_article();
        let users = [sample_user()];
        let base_urls = ["https://dev.to"];
        let cfg = sample_config();

        let single = serialize_api_articles_search_json(
            &[article],
            Some(Some("# Body")),
            &users,
            &[],
            &[],
            &base_urls,
            &cfg,
        )
        .unwrap();
        assert!(single.contains(
            "\"reading_time_minutes\":3,\"body_markdown\":\"# Body\",\"tag_list\":[\"ruby\""
        ));

        let multi = serialize_api_articles_search_json(
            &[article, article],
            None,
            &users,
            &[],
            &[],
            &base_urls,
            &cfg,
        )
        .unwrap();
        assert!(!multi.contains("\"body_markdown\""));

        // Mismatched single_body_markdown with len != 1 defers cleanly.
        assert_eq!(
            serialize_api_articles_search_json(
                &[article, article],
                Some(Some("# Body")),
                &users,
                &[],
                &[],
                &base_urls,
                &cfg,
            ),
            None
        );
    }

    #[test]
    fn serialize_api_articles_me_handles_published_and_draft_rows() {
        let user = sample_user();
        let base_urls = ["https://dev.to"];
        let cfg = sample_config();
        let rows = [
            ApiArticleMeRow {
                id: 10,
                org_idx: -1,
                base_url_idx: 0,
                url_path: Some("/alice/post-1"),
                title: Some("Published"),
                description: Some("Desc"),
                published: Some(true),
                published_at_sec: Some(1_795_528_285),
                published_at_millis: Some(42),
                crossposted_at_sec: None,
                slug: Some("post-1"),
                path: Some("/alice/post-1"),
                comments_count: Some(2),
                public_reactions_count: Some(7),
                page_views_count: Some(123),
                body_markdown: Some("Hello"),
                main_image: None,
                cached_tag_list: Some("rust"),
                canonical_url: None,
                reading_time: Some(3),
            },
            ApiArticleMeRow {
                id: 11,
                org_idx: -1,
                base_url_idx: 0,
                url_path: Some("/alice/draft"),
                title: Some("Draft"),
                description: Some(""),
                published: Some(false),
                published_at_sec: None,
                published_at_millis: None,
                crossposted_at_sec: None,
                slug: Some("draft"),
                path: Some("/alice/draft"),
                comments_count: Some(0),
                public_reactions_count: Some(0),
                page_views_count: Some(0),
                body_markdown: Some("WIP"),
                main_image: None,
                cached_tag_list: None,
                canonical_url: None,
                reading_time: Some(1),
            },
        ];

        let json =
            serialize_api_articles_me_json(&rows, &user, &[], &[], &base_urls, &cfg).unwrap();
        assert!(json.contains("\"published\":true,\"published_at\":\"2026-11-24T13:51:25.042Z\""));
        assert!(json
            .contains("\"page_views_count\":123,\"published_timestamp\":\"2026-11-24T13:51:25Z\""));
        assert!(json.contains("\"published\":false,\"published_at\":null"));
        assert!(json.contains("\"page_views_count\":0,\"published_timestamp\":\"\""));

        // Invalid millis >= 1000 defers.
        let mut bad = rows[0];
        bad.published_at_millis = Some(1000);
        assert_eq!(
            serialize_api_articles_me_json(&[bad], &user, &[], &[], &base_urls, &cfg),
            None
        );
    }
}
