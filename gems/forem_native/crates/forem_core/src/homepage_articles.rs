//! Single-pass streaming JSON serializer for Forem's Homepage / Feed Content
//! article endpoint (`SearchController#feed_content`, `Homepage::FetchArticles`,
//! `Search::Article`, and `Homepage::ArticleSerializer`).
//!
//! Replaces up to 60–100 `Article` ActiveRecord model instantiations, `Tag` model
//! lookups, per-article `JSONAPI::Serializer` wrapper hashes, `cached_tag_list.split(", ")`
//! arrays, `Reactable#public_reaction_categories` Ruby sorting, and
//! `ActiveSupport::JSON.encode` multi-pass hash walking with a single-pass Rust
//! streaming kernel:
//!
//! - **Tier 1 composable primitives**:
//!   - [`select_top_public_reaction_categories`]: zero-allocation stack-sorted top-3
//!     selector matching `Reactable#public_reaction_categories`.
//!   - [`write_public_reaction_categories_json`]: streams the top-3 public reaction
//!     category JSON array directly into a caller-owned buffer.
//!   - [`write_homepage_tag_list_json`]: streams Ruby-exact `cached_tag_list.to_s.split(", ")`
//!     JSON array without allocating intermediate `Vec`/`String` slices.
//! - **Tier 2 single-pass pipeline kernel**:
//!   - [`serialize_homepage_articles_json`]: composes [`write_readable_publish_date`],
//!     [`crate::feed::format_video_duration`], [`crate::image::cloudflare_image_url`],
//!     [`write_public_reaction_categories_json`], [`write_homepage_tag_list_json`],
//!     and [`crate::json::write_json_string`] to stream the complete `{"result":[...]}`
//!     JSON payload into a single pre-sized buffer.

use std::fmt::Write;

use crate::api_articles::{check_blank, write_readable_publish_date, ImageOptimizerMode};
use crate::feed::format_video_duration;
use crate::image::cloudflare_image_url;
use crate::json::write_json_string;

/// Public reaction category metadata resolved once from `ReactionCategory.for_view`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PublicReactionCategory<'a> {
    pub slug: &'a str,
    pub name: Option<&'a str>,
    pub icon: Option<&'a str>,
    pub position: i64,
}

/// Flat representation of an article row plucked from PostgreSQL for
/// `Homepage::ArticleSerializer` (`SearchController#feed_content`).
#[derive(Debug, Clone, Copy)]
pub struct HomepageArticleRow<'a> {
    pub id: i64,
    /// Index into deduplicated `users` slice (must be in bounds).
    pub user_idx: i64,
    /// Index into deduplicated `orgs` slice, or `-1` when absent.
    pub org_idx: i64,
    pub favorited_by_user_id: Option<i64>,
    pub path: Option<&'a str>,
    pub public_reactions_count: Option<i64>,
    pub reading_time: Option<i64>,
    pub title: Option<&'a str>,
    pub user_id: Option<i64>,
    pub comments_count: Option<i64>,
    pub displayed_comments_count: Option<i64>,
    pub video_duration_in_seconds: Option<i64>,
    pub video_thumbnail_url: Option<&'a str>,
    pub cached_tag_list: Option<&'a str>,
    pub published_at_sec: Option<i64>,
    pub crossposted_at_sec: Option<i64>,
}

/// Deduplicated user payload for `Homepage::ArticleSerializer`'s `user` object.
#[derive(Debug, Clone, Copy)]
pub struct HomepageArticleUser<'a> {
    pub name: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
    pub username: Option<&'a str>,
}

/// Deduplicated organization payload for `Homepage::ArticleSerializer`'s `organization` object.
#[derive(Debug, Clone, Copy)]
pub struct HomepageArticleOrganization<'a> {
    pub name: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
    pub slug: Option<&'a str>,
}

/// Flare tag entry in `Constants::Tags::FLARE_TAG_NAMES` order.
#[derive(Debug, Clone, Copy)]
pub struct HomepageArticleFlareTag<'a> {
    /// Canonical flare tag name matched against `cached_tag_list`.
    pub match_name: &'a str,
    /// `Tag#name` when the record exists in `tags`, or `None` if absent.
    pub name: Option<&'a str>,
    pub bg_color_hex: Option<&'a str>,
    pub text_color_hex: Option<&'a str>,
}

/// Request-level configuration resolved once in Ruby before streaming the batch.
#[derive(Debug, Clone, Copy)]
pub struct HomepageArticlesConfig<'a> {
    pub current_year: i64,
    pub optimizer_mode: ImageOptimizerMode,
    pub cloudflare_domain: Option<&'a str>,
    pub cloudflare_directory: &'a str,
    pub escape_html_entities: bool,
}

/// Selects up to 3 public reaction category indices matching
/// `Reactable#public_reaction_categories`:
///
/// 1. Filters `(slug, count)` entries to `count > 0` where `slug` is in `categories`.
/// 2. Orders by `(-count, position)` ascending (highest count first, lowest `position` on ties).
/// 3. Keeps at most the top 3 entries on the stack with zero heap allocations.
pub fn select_top_public_reaction_categories(
    counts: &[(&str, i64)],
    categories: &[PublicReactionCategory<'_>],
) -> ([usize; 3], usize) {
    // Store `(count, position, cat_idx)` in sorted order: higher `count` first,
    // then lower `position` first.
    let mut top: [(i64, i64, usize); 3] = [(0, 0, 0); 3];
    let mut len: usize = 0;

    for &(slug, count) in counts {
        if count <= 0 {
            continue;
        }
        let Some(cat_idx) = categories.iter().position(|c| c.slug == slug) else {
            continue;
        };
        let pos = categories[cat_idx].position;

        // Find insertion slot so `top[..len]` stays sorted by `(-count, pos)`.
        let mut insert_at = len;
        for (i, &(t_count, t_pos, _)) in top[..len].iter().enumerate() {
            if count > t_count || (count == t_count && pos < t_pos) {
                insert_at = i;
                break;
            }
        }

        if insert_at < 3 {
            let new_len = (len + 1).min(3);
            let mut j = new_len - 1;
            while j > insert_at {
                top[j] = top[j - 1];
                j -= 1;
            }
            top[insert_at] = (count, pos, cat_idx);
            len = new_len;
        }
    }

    ([top[0].2, top[1].2, top[2].2], len)
}

/// Writes the top-3 public reaction categories JSON array directly into `out`,
/// matching `ReactionCategory#as_json` (`slug`, `name`, `icon`, `position`).
pub fn write_public_reaction_categories_json(
    out: &mut String,
    counts: &[(&str, i64)],
    categories: &[PublicReactionCategory<'_>],
    escape_html: bool,
) {
    let (indices, len) = select_top_public_reaction_categories(counts, categories);
    out.push('[');
    for (i, &cat_idx) in indices[..len].iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        let cat = &categories[cat_idx];
        out.push_str("{\"slug\":");
        write_json_string(out, cat.slug, escape_html);
        out.push_str(",\"name\":");
        write_opt_str(out, cat.name, escape_html);
        out.push_str(",\"icon\":");
        write_opt_str(out, cat.icon, escape_html);
        out.push_str(",\"position\":");
        let _ = write!(out, "{}", cat.position);
        out.push('}');
    }
    out.push(']');
}

/// Strips trailing `", "` separators matching Ruby's `String#split(", ")` default
/// behavior (limit `0`, which suppresses trailing empty fields).
#[inline]
fn trim_trailing_tag_separators(raw: &str) -> &str {
    let mut s = raw;
    while let Some(stripped) = s.strip_suffix(", ") {
        s = stripped;
    }
    s
}

/// Streams `cached_tag_list.to_s.split(", ")` directly as a JSON string array into `out`
/// with zero intermediate heap allocations.
pub fn write_homepage_tag_list_json(
    out: &mut String,
    cached_tag_list: Option<&str>,
    escape_html: bool,
) {
    out.push('[');
    if let Some(raw) = cached_tag_list {
        let trimmed = trim_trailing_tag_separators(raw);
        if !trimmed.is_empty() {
            for (i, tag) in trimmed.split(", ").enumerate() {
                if i > 0 {
                    out.push(',');
                }
                write_json_string(out, tag, escape_html);
            }
        }
    }
    out.push(']');
}

#[inline]
fn write_opt_str(out: &mut String, value: Option<&str>, escape_html: bool) {
    match value {
        Some(s) => write_json_string(out, s, escape_html),
        None => out.push_str("null"),
    }
}

#[inline]
fn write_opt_i64(out: &mut String, value: Option<i64>) {
    match value {
        Some(n) => {
            let _ = write!(out, "{n}");
        }
        None => out.push_str("null"),
    }
}

/// Applies `Article#cloudinary_video_url` (`Images::Optimizer.call(video_thumbnail_url, width: 880, quality: 80)`).
///
/// Returns:
/// - `Some(None)` when `video_thumbnail_url` is blank (`null` in JSON)
/// - `Some(Some(url))` when resolved in Rust
/// - `None` when out-of-domain (e.g. non-ASCII whitespace check, already-Cloudflare URL needing
///   `CGI.unescape`, or non-NFC-stable characters) so the caller defers to Ruby.
fn resolve_cloudinary_video_url(
    raw: Option<&str>,
    config: &HomepageArticlesConfig<'_>,
) -> Option<Option<String>> {
    let s = match raw {
        None => return Some(None),
        Some(v) => v,
    };
    if check_blank(s)? {
        return Some(None);
    }
    if s.starts_with('/') || s.contains("/agent_sessions/") {
        return Some(Some(s.to_string()));
    }
    match config.optimizer_mode {
        ImageOptimizerMode::Passthrough => Some(Some(s.to_string())),
        ImageOptimizerMode::Cloudflare => {
            let domain = config.cloudflare_domain?;
            let dir = config.cloudflare_directory;
            if let Some(rest) = s.strip_prefix("https://") {
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
            let optimized = cloudflare_image_url(domain, dir, "880", "", "scale-down", s, s)?;
            Some(Some(optimized))
        }
    }
}

fn find_matching_flare_tag<'a>(
    cached_tag_list: Option<&str>,
    flare_tags: &'a [HomepageArticleFlareTag<'a>],
) -> Option<&'a HomepageArticleFlareTag<'a>> {
    if flare_tags.is_empty() {
        return None;
    }
    let raw = cached_tag_list?;
    let trimmed = trim_trailing_tag_separators(raw);
    if trimmed.is_empty() {
        return None;
    }
    trimmed
        .split(", ")
        .find_map(|tok| flare_tags.iter().find(|ft| ft.match_name == tok))
}

/// Streams the complete `{"result":[...]}` JSON response for `SearchController#feed_content`
/// (`Homepage::ArticleSerializer`) into a single pre-sized buffer.
///
/// Returns `None` if any row falls outside the strict fast-path domain (out-of-bounds indices,
/// out-of-range dates/video durations, mismatched reaction count lengths, or URLs requiring
/// Ruby's `Addressable::Template` / `CGI.unescape`), allowing the Ruby caller to fall back
/// transparently to `Homepage::ArticleSerializer`.
#[allow(clippy::too_many_arguments)]
pub fn serialize_homepage_articles_json(
    articles: &[HomepageArticleRow<'_>],
    users: &[HomepageArticleUser<'_>],
    orgs: &[HomepageArticleOrganization<'_>],
    flare_tags: &[HomepageArticleFlareTag<'_>],
    reaction_categories: &[PublicReactionCategory<'_>],
    reaction_counts_flat: &[(&str, i64)],
    reaction_counts_lens: &[usize],
    config: &HomepageArticlesConfig<'_>,
) -> Option<String> {
    if reaction_counts_lens.len() != articles.len() {
        return None;
    }

    if articles.is_empty() {
        if !reaction_counts_flat.is_empty() {
            return None;
        }
        return Some("{\"result\":[]}".to_string());
    }

    let total_counts: usize = reaction_counts_lens
        .iter()
        .try_fold(0usize, |acc, &len| acc.checked_add(len))?;
    if total_counts != reaction_counts_flat.len() {
        return None;
    }

    let esc = config.escape_html_entities;
    let mut out = String::with_capacity(16 + articles.len() * 512);
    out.push_str("{\"result\":[");

    let mut counts_offset: usize = 0;

    for (idx, row) in articles.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }

        let user_idx = usize::try_from(row.user_idx).ok()?;
        let user = users.get(user_idx)?;

        let org = if row.org_idx >= 0 {
            let org_idx = usize::try_from(row.org_idx).ok()?;
            Some(orgs.get(org_idx)?)
        } else {
            None
        };

        let counts_len = reaction_counts_lens[idx];
        let article_counts = &reaction_counts_flat[counts_offset..counts_offset + counts_len];
        counts_offset += counts_len;

        let cloudinary_video_url = resolve_cloudinary_video_url(row.video_thumbnail_url, config)?;
        let video_duration = format_video_duration(row.video_duration_in_seconds.unwrap_or(0))?;

        let effective_comments_count = match row.displayed_comments_count {
            Some(n) if n != 0 => Some(n),
            _ => row.comments_count,
        };

        out.push_str("{\"class_name\":\"Article\",\"cloudinary_video_url\":");
        write_opt_str(&mut out, cloudinary_video_url.as_deref(), esc);

        out.push_str(",\"favorited_by_user_id\":");
        write_opt_i64(&mut out, row.favorited_by_user_id);

        out.push_str(",\"id\":");
        let _ = write!(out, "{}", row.id);

        out.push_str(",\"path\":");
        write_opt_str(&mut out, row.path, esc);

        out.push_str(",\"public_reactions_count\":");
        write_opt_i64(&mut out, row.public_reactions_count);

        out.push_str(",\"readable_publish_date\":");
        match row.crossposted_at_sec.or(row.published_at_sec) {
            Some(sec) => {
                out.push('"');
                if !write_readable_publish_date(&mut out, sec, config.current_year) {
                    return None;
                }
                out.push('"');
            }
            None => out.push_str("null"),
        }

        out.push_str(",\"reading_time\":");
        write_opt_i64(&mut out, row.reading_time);

        out.push_str(",\"title\":");
        write_opt_str(&mut out, row.title, esc);

        out.push_str(",\"user_id\":");
        write_opt_i64(&mut out, row.user_id);

        out.push_str(",\"public_reaction_categories\":");
        write_public_reaction_categories_json(&mut out, article_counts, reaction_categories, esc);

        out.push_str(",\"comments_count\":");
        write_opt_i64(&mut out, effective_comments_count);

        out.push_str(",\"video_duration_string\":");
        write_json_string(&mut out, &video_duration, esc);

        out.push_str(",\"published_at_int\":");
        let _ = write!(out, "{}", row.published_at_sec.unwrap_or(0));

        out.push_str(",\"tag_list\":");
        write_homepage_tag_list_json(&mut out, row.cached_tag_list, esc);

        out.push_str(",\"flare_tag\":");
        match find_matching_flare_tag(row.cached_tag_list, flare_tags) {
            Some(ft) if ft.name.is_some() => {
                out.push_str("{\"name\":");
                write_opt_str(&mut out, ft.name, esc);
                out.push_str(",\"bg_color_hex\":");
                write_opt_str(&mut out, ft.bg_color_hex, esc);
                out.push_str(",\"text_color_hex\":");
                write_opt_str(&mut out, ft.text_color_hex, esc);
                out.push('}');
            }
            _ => out.push_str("null"),
        }

        out.push_str(",\"user\":{\"name\":");
        write_opt_str(&mut out, user.name, esc);
        out.push_str(",\"profile_image_90\":");
        write_opt_str(&mut out, user.profile_image_90, esc);
        out.push_str(",\"username\":");
        write_opt_str(&mut out, user.username, esc);
        out.push('}');

        if let Some(o) = org {
            out.push_str(",\"organization\":{\"name\":");
            write_opt_str(&mut out, o.name, esc);
            out.push_str(",\"profile_image_90\":");
            write_opt_str(&mut out, o.profile_image_90, esc);
            out.push_str(",\"slug\":");
            write_opt_str(&mut out, o.slug, esc);
            out.push('}');
        }

        out.push('}');
    }

    out.push_str("]}");
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn default_categories() -> Vec<PublicReactionCategory<'static>> {
        vec![
            PublicReactionCategory {
                slug: "like",
                name: Some("Like"),
                icon: Some("sparkle-heart"),
                position: 1,
            },
            PublicReactionCategory {
                slug: "unicorn",
                name: Some("Unicorn"),
                icon: Some("multi-unicorn"),
                position: 2,
            },
            PublicReactionCategory {
                slug: "exploding_head",
                name: Some("Exploding Head"),
                icon: Some("exploding-head"),
                position: 3,
            },
            PublicReactionCategory {
                slug: "raised_hands",
                name: Some("Raised Hands"),
                icon: Some("raised-hands"),
                position: 4,
            },
            PublicReactionCategory {
                slug: "fire",
                name: Some("Fire"),
                icon: Some("fire"),
                position: 5,
            },
        ]
    }

    #[test]
    fn test_select_top_public_reaction_categories_sorts_by_count_desc_then_position_asc() {
        let cats = default_categories();
        let counts = [
            ("fire", 5),
            ("readinglist", 100), // not public -> ignored
            ("thumbsup", 50),     // privileged -> ignored
            ("like", 5),          // ties with fire, lower position wins
            ("unicorn", 10),
            ("raised_hands", 0), // zero -> ignored
            ("exploding_head", 5),
        ];
        let (indices, len) = select_top_public_reaction_categories(&counts, &cats);
        assert_eq!(len, 3);
        assert_eq!(cats[indices[0]].slug, "unicorn");
        assert_eq!(cats[indices[1]].slug, "like");
        assert_eq!(cats[indices[2]].slug, "exploding_head");
    }

    #[test]
    fn test_write_homepage_tag_list_json_matches_ruby_split() {
        let cases = [
            (None, "[]"),
            (Some(""), "[]"),
            (Some(", "), "[]"),
            (Some(", , "), "[]"),
            (Some("ruby"), "[\"ruby\"]"),
            (Some("ruby, rails"), "[\"ruby\",\"rails\"]"),
            (Some("ruby, "), "[\"ruby\"]"),
            (Some(", ruby"), "[\"\",\"ruby\"]"),
            (Some("a, , b"), "[\"a\",\"\",\"b\"]"),
        ];
        for (input, expected) in cases {
            let mut buf = String::new();
            write_homepage_tag_list_json(&mut buf, input, true);
            assert_eq!(buf, expected, "input={input:?}");
        }
    }

    #[test]
    fn test_serialize_homepage_articles_json_empty() {
        let cfg = HomepageArticlesConfig {
            current_year: 2026,
            optimizer_mode: ImageOptimizerMode::Passthrough,
            cloudflare_domain: None,
            cloudflare_directory: "cdn-cgi",
            escape_html_entities: true,
        };
        let json = serialize_homepage_articles_json(&[], &[], &[], &[], &[], &[], &[], &cfg);
        assert_eq!(json.as_deref(), Some("{\"result\":[]}"));
    }

    #[test]
    fn test_serialize_homepage_articles_json_full_article_with_org_flare_and_reactions() {
        let cats = default_categories();
        let users = [HomepageArticleUser {
            name: Some("\"Rowdy\" <Roddy>"),
            profile_image_90: Some("https://cdn.example.com/u90.png"),
            username: Some("roddy"),
        }];
        let orgs = [HomepageArticleOrganization {
            name: Some("Acme & Co"),
            profile_image_90: Some("https://cdn.example.com/o90.png"),
            slug: Some("acme"),
        }];
        let flares = [HomepageArticleFlareTag {
            match_name: "ama",
            name: Some("ama"),
            bg_color_hex: Some("#f3f3f3"),
            text_color_hex: Some("#cccccc"),
        }];
        let rows = [HomepageArticleRow {
            id: 42,
            user_idx: 0,
            org_idx: 0,
            favorited_by_user_id: Some(7),
            path: Some("/roddy/hello-world"),
            public_reactions_count: Some(15),
            reading_time: Some(4),
            title: Some("Hello <World> & Friends"),
            user_id: Some(99),
            comments_count: Some(10),
            displayed_comments_count: Some(8),
            video_duration_in_seconds: Some(125),
            video_thumbnail_url: Some("https://example.com/thumb.jpg"),
            cached_tag_list: Some("ruby, ama"),
            published_at_sec: Some(1_774_915_200), // 2026-03-31 UTC
            crossposted_at_sec: None,
        }];
        let counts = [("fire", 3), ("like", 12)];
        let lens = [2];
        let cfg = HomepageArticlesConfig {
            current_year: 2026,
            optimizer_mode: ImageOptimizerMode::Cloudflare,
            cloudflare_domain: Some("media2.dev.to"),
            cloudflare_directory: "dynamic",
            escape_html_entities: true,
        };

        let json = serialize_homepage_articles_json(
            &rows, &users, &orgs, &flares, &cats, &counts, &lens, &cfg,
        )
        .expect("should serialize");

        assert!(json.contains("\"class_name\":\"Article\""));
        assert!(json.contains("\"cloudinary_video_url\":\"https://media2.dev.to/dynamic/image/width=880,height=,fit=scale-down,gravity=auto,format=auto/https%3A%2F%2Fexample.com%2Fthumb.jpg\""));
        assert!(json.contains("\"favorited_by_user_id\":7"));
        assert!(json.contains("\"comments_count\":8"));
        assert!(json.contains("\"video_duration_string\":\"02:05\""));
        assert!(json.contains("\"readable_publish_date\":\"Mar 31\""));
        assert!(json.contains("\"title\":\"Hello \\u003cWorld\\u003e \\u0026 Friends\""));
        assert!(json.contains("\"tag_list\":[\"ruby\",\"ama\"]"));
        assert!(json.contains("\"flare_tag\":{\"name\":\"ama\",\"bg_color_hex\":\"#f3f3f3\",\"text_color_hex\":\"#cccccc\"}"));
        assert!(json.contains("\"public_reaction_categories\":[{\"slug\":\"like\",\"name\":\"Like\",\"icon\":\"sparkle-heart\",\"position\":1},{\"slug\":\"fire\",\"name\":\"Fire\",\"icon\":\"fire\",\"position\":5}]"));
        assert!(json.contains("\"organization\":{\"name\":\"Acme \\u0026 Co\",\"profile_image_90\":\"https://cdn.example.com/o90.png\",\"slug\":\"acme\"}"));
    }

    #[test]
    fn test_serialize_homepage_articles_json_defers_on_out_of_domain_video_duration() {
        let users = [HomepageArticleUser {
            name: Some("A"),
            profile_image_90: Some("/a.png"),
            username: Some("a"),
        }];
        let rows = [HomepageArticleRow {
            id: 1,
            user_idx: 0,
            org_idx: -1,
            favorited_by_user_id: None,
            path: Some("/a/b"),
            public_reactions_count: Some(0),
            reading_time: Some(1),
            title: Some("t"),
            user_id: Some(1),
            comments_count: Some(0),
            displayed_comments_count: Some(0),
            video_duration_in_seconds: Some(-5), // negative -> None
            video_thumbnail_url: None,
            cached_tag_list: None,
            published_at_sec: Some(1_700_000_000),
            crossposted_at_sec: None,
        }];
        let cfg = HomepageArticlesConfig {
            current_year: 2026,
            optimizer_mode: ImageOptimizerMode::Passthrough,
            cloudflare_domain: None,
            cloudflare_directory: "cdn-cgi",
            escape_html_entities: true,
        };
        assert!(
            serialize_homepage_articles_json(&rows, &users, &[], &[], &[], &[], &[0], &cfg)
                .is_none()
        );
    }

    #[test]
    fn test_find_matching_flare_tag_selects_first_in_article_tag_order() {
        let flares = [
            HomepageArticleFlareTag {
                match_name: "ama",
                name: Some("ama"),
                bg_color_hex: Some("#f3f3f3"),
                text_color_hex: Some("#cccccc"),
            },
            HomepageArticleFlareTag {
                match_name: "discuss",
                name: Some("discuss"),
                bg_color_hex: Some("#123456"),
                text_color_hex: Some("#ffffff"),
            },
        ];
        let matched = find_matching_flare_tag(Some("ruby, discuss, ama"), &flares)
            .expect("should match discuss first");
        assert_eq!(matched.match_name, "discuss");
    }

    #[test]
    fn test_serialize_homepage_articles_json_rejects_overflowing_reaction_counts_lens() {
        let users = [HomepageArticleUser {
            name: Some("A"),
            profile_image_90: Some("/a.png"),
            username: Some("a"),
        }];
        let row = HomepageArticleRow {
            id: 1,
            user_idx: 0,
            org_idx: -1,
            favorited_by_user_id: None,
            path: Some("/a/b"),
            public_reactions_count: Some(0),
            reading_time: Some(1),
            title: Some("t"),
            user_id: Some(1),
            comments_count: Some(0),
            displayed_comments_count: Some(0),
            video_duration_in_seconds: Some(0),
            video_thumbnail_url: None,
            cached_tag_list: None,
            published_at_sec: Some(1_700_000_000),
            crossposted_at_sec: None,
        };
        let rows = [row, row];
        let cfg = HomepageArticlesConfig {
            current_year: 2026,
            optimizer_mode: ImageOptimizerMode::Passthrough,
            cloudflare_domain: None,
            cloudflare_directory: "cdn-cgi",
            escape_html_entities: true,
        };
        assert!(serialize_homepage_articles_json(
            &rows,
            &users,
            &[],
            &[],
            &[],
            &[],
            &[usize::MAX, 1],
            &cfg
        )
        .is_none());
    }
}
