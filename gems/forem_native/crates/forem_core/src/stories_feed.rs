//! Single-pass streaming JSON serializer and cached-fragment splicer for Forem's
//! `Stories::FeedsController#show` (`GET /stories/feed`) endpoint.
//!
//! Replaces `app/views/stories/feeds/show.json.jbuilder`'s per-story Jbuilder hash
//! assembly, `cached_user.as_json` / `cached_organization.as_json` intermediate hash
//! copies, `Comment#decorate` Draper allocations, `cached_tag_list_array` string
//! splitting, Marshal'd Hash fragment cache round-trips, and `ActiveSupport::JSON.encode`
//! tree traversal with a two-tier zero-copy Rust streaming pipeline:
//!
//! - **Tier 1 composable primitives**:
//!   - [`splice_stories_feed_item_json`]: appends per-request tail fields (`url`,
//!     `current_user_signed_in`, `feed_config`) onto a pre-serialized cached JSON
//!     object fragment in a single `memcpy` with zero JSON parsing or Ruby Hash
//!     allocation.
//!   - [`write_stories_feed_item_fragment_json`]: streams a single story's cacheable
//!     JSON object directly into a caller-owned buffer, reusing
//!     [`write_public_reaction_categories_json`], [`write_homepage_tag_list_json`],
//!     [`write_readable_publish_date`], [`write_utc_iso8601`],
//!     [`write_utc_iso8601_millis`], [`format_video_duration`],
//!     [`cloudflare_image_url`], and [`write_json_string`].
//! - **Tier 2 single-pass pipeline kernel**:
//!   - [`serialize_stories_feed_json`]: streams an entire feed page (`[{...}, ...]`)
//!     of mixed cached and uncached stories into one pre-sized buffer in a single
//!     FFI call, optionally capturing newly serialized cacheable fragments so the
//!     caller can persist all cache misses in a single `Rails.cache.write_multi`.

use std::borrow::Cow;
use std::fmt::Write;

use crate::api_articles::{
    check_blank, write_readable_publish_date, write_utc_iso8601_millis, ImageOptimizerMode,
};
use crate::api_comments::write_utc_iso8601;
use crate::feed::format_video_duration;
use crate::homepage_articles::{
    write_homepage_tag_list_json, write_public_reaction_categories_json, PublicReactionCategory,
};
use crate::image::cloudflare_image_url;
use crate::json::write_json_string;

/// Cached user or organization entity (`Articles::CachedEntity`).
#[derive(Debug, Clone, Copy)]
pub struct StoriesFeedCachedEntity<'a> {
    pub name: Option<&'a str>,
    pub username: Option<&'a str>,
    pub slug: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
    pub profile_image_url: Option<&'a str>,
    pub cached_base_subscriber: Option<bool>,
    pub cached_community_leader: Option<bool>,
}

/// Optional flare tag metadata (`FlareTag#tag_hash`).
#[derive(Debug, Clone, Copy)]
pub struct StoriesFeedFlareTag<'a> {
    pub name: Option<&'a str>,
    pub bg_color_hex: Option<&'a str>,
    pub text_color_hex: Option<&'a str>,
}

/// Preloaded top comment preview entry.
#[derive(Debug, Clone, Copy)]
pub struct StoriesFeedComment<'a> {
    pub comment_id: i64,
    pub user_id: Option<i64>,
    /// UTC epoch seconds for `comment.created_at`, or `None` when nil.
    pub created_at_sec: Option<i64>,
    pub safe_processed_html: Option<&'a str>,
    pub path: Option<&'a str>,
    pub username: Option<&'a str>,
    pub name: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
}

/// Uncached story payload for `Stories::FeedsController#show`.
#[derive(Debug, Clone, Copy)]
pub struct StoriesFeedItem<'a> {
    pub title: Option<&'a str>,
    pub path: Option<&'a str>,
    pub id: i64,
    pub user_id: Option<i64>,
    pub comments_count: Option<i64>,
    pub public_reactions_count: Option<i64>,
    pub organization_id: Option<i64>,
    pub reading_time: Option<i64>,
    pub video_thumbnail_url: Option<&'a str>,
    pub video: Option<&'a str>,
    /// `(epoch_secs, millis)` for UTC `edited_at`, or `None` when nil.
    pub edited_at_utc: Option<(i64, u32)>,
    pub experience_level_rating: Option<f64>,
    pub experience_level_rating_distribution: Option<f64>,
    pub main_image_height: Option<i64>,
    pub type_of: Option<&'a str>,
    pub subforem_id: Option<i64>,
    pub favorited_by_user_id: Option<i64>,
    pub ai_disclosure_level: Option<&'a str>,
    pub user: StoriesFeedCachedEntity<'a>,
    pub organization: Option<StoriesFeedCachedEntity<'a>>,
    pub pinned: bool,
    pub main_image: Option<&'a str>,
    pub cached_tag_list: Option<&'a str>,
    // Status-article-only fields (emitted only when `type_of == Some("status")`):
    pub body_preview: Option<&'a str>,
    pub title_finalized_for_feed: Option<&'a str>,
    pub title_for_metadata: Option<&'a str>,
    pub flare_tag: Option<StoriesFeedFlareTag<'a>>,
    pub class_name: &'a str,
    pub published: bool,
    pub published_at_int: i64,
    /// UTC epoch seconds for `displayable_published_at`, or `None` when absent.
    pub displayable_published_at_sec: Option<i64>,
    pub main_image_background_hex_color: Option<&'a str>,
    /// Pre-formatted `readable_publish_date` for non-English locales or non-UTC timezones.
    /// When `None`, formatted natively in English UTC via [`write_readable_publish_date`].
    pub readable_publish_date_override: Option<&'a str>,
    pub video_duration_in_seconds: Option<i64>,
    pub subforem_logo: Option<&'a str>,
    pub context_note: Option<&'a str>,
}

/// Per-story entry in the feed response array.
#[derive(Debug, Clone, Copy)]
pub struct StoriesFeedEntry<'a> {
    /// Pre-serialized cacheable JSON object `{...}` when present in cache,
    /// or `None` to serialize the next item from `uncached_items`.
    pub cached_fragment: Option<&'a str>,
    pub url: &'a str,
    pub current_user_signed_in: bool,
    pub feed_config_id: Option<i64>,
}

/// Request-level configuration resolved once in Ruby before streaming the feed.
#[derive(Debug, Clone, Copy)]
pub struct StoriesFeedConfig<'a> {
    pub current_year: i64,
    pub optimizer_mode: ImageOptimizerMode,
    pub cloudflare_domain: Option<&'a str>,
    pub cloudflare_directory: &'a str,
    pub escape_html_entities: bool,
    /// Pre-resolved `I18n.t` labels in order: `[some_ai, fully_autonomous, no_ai, not_disclosed]`.
    pub ai_disclosure_labels: [&'a str; 4],
    /// When `true`, captures each newly serialized uncached fragment for `Rails.cache.write_multi`.
    pub capture_fragments: bool,
}

#[inline]
fn write_opt_str(out: &mut String, val: Option<&str>, escape: bool) {
    match val {
        Some(s) => write_json_string(out, s, escape),
        None => out.push_str("null"),
    }
}

#[inline]
fn write_opt_i64(out: &mut String, val: Option<i64>) {
    match val {
        Some(n) => {
            let _ = write!(out, "{n}");
        }
        None => out.push_str("null"),
    }
}

#[inline]
fn write_opt_bool(out: &mut String, val: Option<bool>) {
    match val {
        Some(true) => out.push_str("true"),
        Some(false) => out.push_str("false"),
        None => out.push_str("null"),
    }
}

/// Formats a finite decimal float matching Ruby's `Float#to_s` / `ActiveSupport::JSON`
/// for values in the non-scientific decimal range (`0.0` or `0.0001 <= |v| < 1e15`).
///
/// Returns `false` for `NaN`, `±Infinity`, or scientific-notation magnitudes so the
/// caller can safely defer to Ruby.
pub fn write_stories_feed_float(out: &mut String, value: f64) -> bool {
    if !value.is_finite() {
        return false;
    }
    if value == 0.0 {
        out.push_str(if value.is_sign_negative() {
            "-0.0"
        } else {
            "0.0"
        });
        return true;
    }
    let abs = value.abs();
    if !(1e-4..1e15).contains(&abs) {
        return false;
    }
    if value.fract() == 0.0 {
        let _ = write!(out, "{value:.1}");
    } else {
        let _ = write!(out, "{value}");
    }
    true
}

#[inline]
fn write_opt_float(out: &mut String, val: Option<f64>) -> bool {
    match val {
        Some(f) => write_stories_feed_float(out, f),
        None => {
            out.push_str("null");
            true
        }
    }
}

fn write_cached_entity(
    out: &mut String,
    entity: &StoriesFeedCachedEntity<'_>,
    include_alias_keys: bool,
    escape: bool,
) {
    out.push_str("{\"name\":");
    write_opt_str(out, entity.name, escape);
    out.push_str(",\"username\":");
    write_opt_str(out, entity.username, escape);
    out.push_str(",\"slug\":");
    write_opt_str(out, entity.slug, escape);
    out.push_str(",\"profile_image_90\":");
    write_opt_str(out, entity.profile_image_90, escape);
    out.push_str(",\"profile_image_url\":");
    write_opt_str(out, entity.profile_image_url, escape);
    out.push_str(",\"cached_base_subscriber?\":");
    write_opt_bool(out, entity.cached_base_subscriber);
    out.push_str(",\"cached_community_leader?\":");
    write_opt_bool(out, entity.cached_community_leader);
    if include_alias_keys {
        out.push_str(",\"cached_base_subscriber\":");
        write_opt_bool(out, entity.cached_base_subscriber);
        out.push_str(",\"cached_community_leader\":");
        write_opt_bool(out, entity.cached_community_leader);
    }
    out.push('}');
}

#[inline]
fn resolve_ai_disclosure_label<'a>(level: Option<&str>, labels: &[&'a str; 4]) -> &'a str {
    match level {
        Some("some_ai") => labels[0],
        Some("fully_autonomous") => labels[1],
        Some("no_ai") => labels[2],
        _ => labels[3],
    }
}

fn resolve_cloudinary_video_url<'a>(
    raw: Option<&'a str>,
    config: &StoriesFeedConfig<'_>,
) -> Option<Option<Cow<'a, str>>> {
    let s = match raw {
        None => return Some(None),
        Some(v) => v,
    };
    if check_blank(s)? {
        return Some(None);
    }
    if s.starts_with('/') || s.contains("/agent_sessions/") {
        return Some(Some(Cow::Borrowed(s)));
    }
    match config.optimizer_mode {
        ImageOptimizerMode::Passthrough => Some(Some(Cow::Borrowed(s))),
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
            Some(Some(Cow::Owned(optimized)))
        }
    }
}

fn write_top_comments(out: &mut String, comments: &[StoriesFeedComment<'_>], escape: bool) -> bool {
    out.push('[');
    for (idx, comment) in comments.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"comment_id\":");
        let _ = write!(out, "{}", comment.comment_id);
        out.push_str(",\"user_id\":");
        write_opt_i64(out, comment.user_id);
        out.push_str(",\"published_timestamp\":\"");
        if let Some(sec) = comment.created_at_sec {
            if !write_utc_iso8601(out, sec) {
                return false;
            }
        }
        out.push_str("\",\"published_at_int\":");
        let _ = write!(out, "{}", comment.created_at_sec.unwrap_or(0));
        out.push_str(",\"safe_processed_html\":");
        write_opt_str(out, comment.safe_processed_html, escape);
        out.push_str(",\"path\":");
        write_opt_str(out, comment.path, escape);
        out.push_str(",\"username\":");
        write_opt_str(out, comment.username, escape);
        out.push_str(",\"name\":");
        write_opt_str(out, comment.name, escape);
        out.push_str(",\"profile_image_90\":");
        write_opt_str(out, comment.profile_image_90, escape);
        out.push('}');
    }
    out.push(']');
    true
}

/// Tier 1 primitive: appends per-request tail fields (`url`, `current_user_signed_in`,
/// `feed_config`) onto a pre-serialized JSON object fragment (`{...}`) directly into `out`.
///
/// Returns `false` if `cached_fragment` does not begin with `{` and end with `}`.
pub fn splice_stories_feed_item_json_into(
    out: &mut String,
    cached_fragment: &str,
    url: &str,
    current_user_signed_in: bool,
    feed_config_id: Option<i64>,
    escape_html_entities: bool,
) -> bool {
    let bytes = cached_fragment.as_bytes();
    if bytes.len() < 2 || bytes[0] != b'{' || bytes[bytes.len() - 1] != b'}' {
        return false;
    }

    let inner = &cached_fragment[1..bytes.len() - 1];
    out.push_str(&cached_fragment[..bytes.len() - 1]);
    if inner
        .bytes()
        .any(|b| !matches!(b, b' ' | b'\t' | b'\r' | b'\n'))
    {
        out.push(',');
    }
    write_tail_fields(
        out,
        url,
        current_user_signed_in,
        feed_config_id,
        escape_html_entities,
    );
    out.push('}');
    true
}

/// Standalone Tier 1 wrapper around [`splice_stories_feed_item_json_into`].
pub fn splice_stories_feed_item_json(
    cached_fragment: &str,
    url: &str,
    current_user_signed_in: bool,
    feed_config_id: Option<i64>,
    escape_html_entities: bool,
) -> Option<String> {
    let mut out = String::with_capacity(cached_fragment.len() + url.len() + 72);
    splice_stories_feed_item_json_into(
        &mut out,
        cached_fragment,
        url,
        current_user_signed_in,
        feed_config_id,
        escape_html_entities,
    )
    .then_some(out)
}

#[inline]
fn write_tail_fields(
    out: &mut String,
    url: &str,
    current_user_signed_in: bool,
    feed_config_id: Option<i64>,
    escape_html_entities: bool,
) {
    out.push_str("\"url\":");
    write_json_string(out, url, escape_html_entities);
    out.push_str(",\"current_user_signed_in\":");
    out.push_str(if current_user_signed_in {
        "true"
    } else {
        "false"
    });
    out.push_str(",\"feed_config\":");
    write_opt_i64(out, feed_config_id);
}

/// Tier 1 primitive: streams a single story's cacheable JSON object (`{...}`)
/// matching `app/views/stories/feeds/show.json.jbuilder` lines 37–96 into `out`.
///
/// Returns `false` if any timestamp or float falls outside the fast-path domain.
pub fn write_stories_feed_item_fragment_json(
    out: &mut String,
    item: &StoriesFeedItem<'_>,
    comments: &[StoriesFeedComment<'_>],
    reaction_counts: &[(&str, i64)],
    reaction_categories: &[PublicReactionCategory<'_>],
    config: &StoriesFeedConfig<'_>,
) -> bool {
    let escape = config.escape_html_entities;

    out.push_str("{\"title\":");
    write_opt_str(out, item.title, escape);
    out.push_str(",\"path\":");
    write_opt_str(out, item.path, escape);
    out.push_str(",\"id\":");
    let _ = write!(out, "{}", item.id);
    out.push_str(",\"user_id\":");
    write_opt_i64(out, item.user_id);
    out.push_str(",\"comments_count\":");
    write_opt_i64(out, item.comments_count);
    out.push_str(",\"public_reactions_count\":");
    write_opt_i64(out, item.public_reactions_count);
    out.push_str(",\"organization_id\":");
    write_opt_i64(out, item.organization_id);
    out.push_str(",\"reading_time\":");
    write_opt_i64(out, item.reading_time);
    out.push_str(",\"video_thumbnail_url\":");
    write_opt_str(out, item.video_thumbnail_url, escape);
    out.push_str(",\"video\":");
    write_opt_str(out, item.video, escape);

    out.push_str(",\"edited_at\":");
    match item.edited_at_utc {
        Some((secs, millis)) => {
            out.push('"');
            if !write_utc_iso8601_millis(out, secs, millis) {
                return false;
            }
            out.push('"');
        }
        None => out.push_str("null"),
    }

    out.push_str(",\"experience_level_rating\":");
    if !write_opt_float(out, item.experience_level_rating) {
        return false;
    }
    out.push_str(",\"experience_level_rating_distribution\":");
    if !write_opt_float(out, item.experience_level_rating_distribution) {
        return false;
    }

    out.push_str(",\"main_image_height\":");
    write_opt_i64(out, item.main_image_height);
    out.push_str(",\"type_of\":");
    write_opt_str(out, item.type_of, escape);
    out.push_str(",\"subforem_id\":");
    write_opt_i64(out, item.subforem_id);
    out.push_str(",\"favorited_by_user_id\":");
    write_opt_i64(out, item.favorited_by_user_id);
    out.push_str(",\"ai_disclosure_level\":");
    write_opt_str(out, item.ai_disclosure_level, escape);

    out.push_str(",\"user\":");
    write_cached_entity(out, &item.user, true, escape);

    if let Some(org) = &item.organization {
        out.push_str(",\"organization\":");
        write_cached_entity(out, org, false, escape);
    }

    out.push_str(",\"pinned\":");
    out.push_str(if item.pinned { "true" } else { "false" });
    out.push_str(",\"main_image\":");
    write_opt_str(out, item.main_image, escape);

    out.push_str(",\"tag_list\":");
    write_homepage_tag_list_json(out, item.cached_tag_list, escape);

    if item.type_of == Some("status") {
        out.push_str(",\"body_preview\":");
        write_opt_str(out, item.body_preview, escape);
        out.push_str(",\"title_finalized_for_feed\":");
        write_opt_str(out, item.title_finalized_for_feed, escape);
        out.push_str(",\"title_for_metadata\":");
        write_opt_str(out, item.title_for_metadata, escape);
    }

    out.push_str(",\"flare_tag\":");
    match &item.flare_tag {
        Some(ft) => {
            out.push_str("{\"name\":");
            write_opt_str(out, ft.name, escape);
            out.push_str(",\"bg_color_hex\":");
            write_opt_str(out, ft.bg_color_hex, escape);
            out.push_str(",\"text_color_hex\":");
            write_opt_str(out, ft.text_color_hex, escape);
            out.push('}');
        }
        None => out.push_str("null"),
    }

    out.push_str(",\"class_name\":");
    write_json_string(out, item.class_name, escape);

    out.push_str(",\"cloudinary_video_url\":");
    let Some(video_url) = resolve_cloudinary_video_url(item.video_thumbnail_url, config) else {
        return false;
    };
    write_opt_str(out, video_url.as_deref(), escape);

    out.push_str(",\"published_at_int\":");
    let _ = write!(out, "{}", item.published_at_int);

    out.push_str(",\"published_timestamp\":\"");
    if item.published {
        if let Some(sec) = item.displayable_published_at_sec {
            if !write_utc_iso8601(out, sec) {
                return false;
            }
        }
    }
    out.push('"');

    out.push_str(",\"main_image_background_hex_color\":");
    write_opt_str(out, item.main_image_background_hex_color, escape);

    out.push_str(",\"public_reaction_categories\":");
    write_public_reaction_categories_json(out, reaction_counts, reaction_categories, escape);

    out.push_str(",\"readable_publish_date\":");
    if let Some(override_str) = item.readable_publish_date_override {
        write_json_string(out, override_str, escape);
    } else if let Some(sec) = item.displayable_published_at_sec {
        out.push('"');
        if !write_readable_publish_date(out, sec, config.current_year) {
            return false;
        }
        out.push('"');
    } else {
        out.push_str("null");
    }

    out.push_str(",\"video_duration_in_minutes\":");
    let Some(duration) = format_video_duration(item.video_duration_in_seconds.unwrap_or(0)) else {
        return false;
    };
    write_json_string(out, &duration, escape);

    out.push_str(",\"ai_disclosure_label\":");
    let label = resolve_ai_disclosure_label(item.ai_disclosure_level, &config.ai_disclosure_labels);
    write_json_string(out, label, escape);

    out.push_str(",\"top_comments\":");
    if !write_top_comments(out, comments, escape) {
        return false;
    }

    out.push_str(",\"subforem_logo\":");
    write_opt_str(out, item.subforem_logo, escape);

    out.push_str(",\"context_note\":");
    write_opt_str(out, item.context_note, escape);

    out.push('}');
    true
}

/// Tier 2 single-pass pipeline kernel: streams the complete JSON array response
/// (`[{...}, ...]`) for `Stories::FeedsController#show` into a single pre-sized buffer.
///
/// Returns `(full_json, newly_serialized_fragments)`. When `config.capture_fragments`
/// is `true`, `newly_serialized_fragments` contains one cacheable `{...}` JSON string
/// per uncached item (in `uncached_items` order) ready for `Rails.cache.write_multi`.
/// When `false`, `newly_serialized_fragments` is empty.
#[allow(clippy::too_many_arguments)]
pub fn serialize_stories_feed_json(
    entries: &[StoriesFeedEntry<'_>],
    uncached_items: &[StoriesFeedItem<'_>],
    comments: &[StoriesFeedComment<'_>],
    comment_lens: &[usize],
    reaction_counts: &[(&str, i64)],
    reaction_counts_lens: &[usize],
    reaction_categories: &[PublicReactionCategory<'_>],
    config: &StoriesFeedConfig<'_>,
) -> Option<(String, Vec<String>)> {
    if comment_lens.len() != uncached_items.len()
        || reaction_counts_lens.len() != uncached_items.len()
    {
        return None;
    }

    let mut total_comments: usize = 0;
    for &n in comment_lens {
        total_comments = total_comments.checked_add(n)?;
    }
    if total_comments != comments.len() {
        return None;
    }

    let mut total_reactions: usize = 0;
    for &n in reaction_counts_lens {
        total_reactions = total_reactions.checked_add(n)?;
    }
    if total_reactions != reaction_counts.len() {
        return None;
    }

    let mut estimated_bytes: usize = 2;
    let mut uncached_count: usize = 0;
    for entry in entries {
        estimated_bytes += entry.url.len() + 72;
        if let Some(frag) = entry.cached_fragment {
            estimated_bytes += frag.len();
        } else {
            uncached_count += 1;
            estimated_bytes += 1400;
        }
    }
    if uncached_count != uncached_items.len() {
        return None;
    }

    let mut out = String::with_capacity(estimated_bytes);
    let mut captured_fragments = if config.capture_fragments {
        Vec::with_capacity(uncached_items.len())
    } else {
        Vec::new()
    };

    out.push('[');
    let mut uncached_idx: usize = 0;
    let mut comment_offset: usize = 0;
    let mut reaction_offset: usize = 0;

    for (entry_idx, entry) in entries.iter().enumerate() {
        if entry_idx > 0 {
            out.push(',');
        }

        if let Some(cached) = entry.cached_fragment {
            if !splice_stories_feed_item_json_into(
                &mut out,
                cached,
                entry.url,
                entry.current_user_signed_in,
                entry.feed_config_id,
                config.escape_html_entities,
            ) {
                return None;
            }
        } else {
            let item = &uncached_items[uncached_idx];
            let c_len = comment_lens[uncached_idx];
            let r_len = reaction_counts_lens[uncached_idx];
            let item_comments = &comments[comment_offset..comment_offset + c_len];
            let item_reactions = &reaction_counts[reaction_offset..reaction_offset + r_len];
            comment_offset += c_len;
            reaction_offset += r_len;
            uncached_idx += 1;

            let frag_start = out.len();
            if !write_stories_feed_item_fragment_json(
                &mut out,
                item,
                item_comments,
                item_reactions,
                reaction_categories,
                config,
            ) {
                return None;
            }
            if config.capture_fragments {
                captured_fragments.push(out[frag_start..].to_owned());
            }

            // Splice tail fields directly in-place by replacing the closing `}` we just wrote.
            out.pop();
            out.push(',');
            write_tail_fields(
                &mut out,
                entry.url,
                entry.current_user_signed_in,
                entry.feed_config_id,
                config.escape_html_entities,
            );
            out.push('}');
        }
    }

    out.push(']');
    Some((out, captured_fragments))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_config(capture: bool) -> StoriesFeedConfig<'static> {
        StoriesFeedConfig {
            current_year: 2026,
            optimizer_mode: ImageOptimizerMode::Passthrough,
            cloudflare_domain: None,
            cloudflare_directory: "cdn-cgi",
            escape_html_entities: true,
            ai_disclosure_labels: [
                "Assisted by AI",
                "Autonomous AI",
                "Human-written",
                "Not disclosed",
            ],
            capture_fragments: capture,
        }
    }

    fn sample_user() -> StoriesFeedCachedEntity<'static> {
        StoriesFeedCachedEntity {
            name: Some("Alice <Dev>"),
            username: Some("alice"),
            slug: Some("alice"),
            profile_image_90: Some("https://img.example/alice-90.png"),
            profile_image_url: Some("https://img.example/alice.png"),
            cached_base_subscriber: Some(true),
            cached_community_leader: Some(false),
        }
    }

    fn sample_item() -> StoriesFeedItem<'static> {
        StoriesFeedItem {
            title: Some("Hello Rust & Ruby"),
            path: Some("/alice/hello-rust-1"),
            id: 42,
            user_id: Some(7),
            comments_count: Some(1),
            public_reactions_count: Some(12),
            organization_id: None,
            reading_time: Some(4),
            video_thumbnail_url: None,
            video: None,
            edited_at_utc: Some((1_795_626_000, 123)),
            experience_level_rating: Some(5.0),
            experience_level_rating_distribution: Some(4.25),
            main_image_height: Some(420),
            type_of: Some("full_post"),
            subforem_id: Some(1),
            favorited_by_user_id: None,
            ai_disclosure_level: Some("no_ai"),
            user: sample_user(),
            organization: None,
            pinned: true,
            main_image: Some("https://img.example/cover.png"),
            cached_tag_list: Some("rust, ruby"),
            body_preview: None,
            title_finalized_for_feed: None,
            title_for_metadata: None,
            flare_tag: Some(StoriesFeedFlareTag {
                name: Some("discuss"),
                bg_color_hex: Some("#000000"),
                text_color_hex: Some("#ffffff"),
            }),
            class_name: "Article",
            published: true,
            published_at_int: 1_795_626_000,
            displayable_published_at_sec: Some(1_795_626_000),
            main_image_background_hex_color: Some("#dddddd"),
            readable_publish_date_override: None,
            video_duration_in_seconds: Some(125),
            subforem_logo: Some("https://img.example/logo.png"),
            context_note: None,
        }
    }

    #[test]
    fn splices_cached_fragment_with_tail_fields() {
        let spliced = splice_stories_feed_item_json(
            r#"{"id":42,"title":"Hi"}"#,
            "https://dev.to/alice/hi",
            true,
            Some(99),
            true,
        )
        .unwrap();
        assert_eq!(
            spliced,
            r#"{"id":42,"title":"Hi","url":"https://dev.to/alice/hi","current_user_signed_in":true,"feed_config":99}"#
        );

        let empty =
            splice_stories_feed_item_json("{}", "https://dev.to/a", false, None, true).unwrap();
        assert_eq!(
            empty,
            r#"{"url":"https://dev.to/a","current_user_signed_in":false,"feed_config":null}"#
        );

        let ws_empty =
            splice_stories_feed_item_json("{  \n\t }", "https://dev.to/a", false, None, true)
                .unwrap();
        assert_eq!(
            ws_empty,
            "{  \n\t \"url\":\"https://dev.to/a\",\"current_user_signed_in\":false,\"feed_config\":null}"
        );
    }

    #[test]
    fn splice_rejects_malformed_fragment() {
        assert!(
            splice_stories_feed_item_json("not-json", "https://dev.to/a", false, None, true)
                .is_none()
        );
        assert!(
            splice_stories_feed_item_json("{", "https://dev.to/a", false, None, true).is_none()
        );
        assert!(
            splice_stories_feed_item_json("[]", "https://dev.to/a", false, None, true).is_none()
        );
    }

    #[test]
    fn serializes_mixed_cached_and_uncached_feed_and_captures_fragments() {
        let item = sample_item();
        let comment = StoriesFeedComment {
            comment_id: 101,
            user_id: Some(8),
            created_at_sec: Some(1_795_626_000),
            safe_processed_html: Some("<p>Great post!</p>"),
            path: Some("/bob/comment/abc"),
            username: Some("bob"),
            name: Some("Bob"),
            profile_image_90: Some("https://img.example/bob.png"),
        };
        let cats = [PublicReactionCategory {
            slug: "like",
            name: Some("Like"),
            icon: Some("heart"),
            position: 1,
        }];
        let entries = [
            StoriesFeedEntry {
                cached_fragment: Some(r#"{"id":1,"title":"Cached"}"#),
                url: "https://dev.to/u/cached",
                current_user_signed_in: false,
                feed_config_id: None,
            },
            StoriesFeedEntry {
                cached_fragment: None,
                url: "https://dev.to/alice/hello-rust-1",
                current_user_signed_in: false,
                feed_config_id: Some(12),
            },
        ];

        let (json, fragments) = serialize_stories_feed_json(
            &entries,
            &[item],
            &[comment],
            &[1],
            &[("like", 5)],
            &[1],
            &cats,
            &sample_config(true),
        )
        .unwrap();

        assert_eq!(fragments.len(), 1);
        assert!(fragments[0].starts_with('{'));
        assert!(fragments[0].ends_with('}'));
        assert!(!fragments[0].contains("\"url\":"));
        assert!(json.contains(r#"{"id":1,"title":"Cached","url":"https://dev.to/u/cached","current_user_signed_in":false,"feed_config":null}"#));
        assert!(json.contains(r#""title":"Hello Rust \u0026 Ruby""#));
        assert!(json.contains(r#""cached_base_subscriber?":true"#));
        assert!(json.contains(r#""cached_base_subscriber":true"#));
        assert!(json.contains(r#""tag_list":["rust","ruby"]"#));
        assert!(json.contains(r#""video_duration_in_minutes":"02:05""#));
        assert!(json.contains(r#""ai_disclosure_label":"Human-written""#));
        assert!(json.contains(r#""comment_id":101"#));
        assert!(json.contains(r#""feed_config":12}"#));
        assert!(!json.contains("\"organization\":"));
        assert!(!json.contains("\"body_preview\":"));
    }

    #[test]
    fn status_article_and_organization_fields_emitted_when_present() {
        let mut item = sample_item();
        item.type_of = Some("status");
        item.body_preview = Some("<p>Status body</p>");
        item.title_finalized_for_feed = Some("Status title");
        item.title_for_metadata = Some("Status meta");
        item.organization = Some(StoriesFeedCachedEntity {
            name: Some("Forem"),
            username: Some("forem"),
            slug: Some("forem"),
            profile_image_90: None,
            profile_image_url: None,
            cached_base_subscriber: None,
            cached_community_leader: None,
        });

        let mut out = String::new();
        assert!(write_stories_feed_item_fragment_json(
            &mut out,
            &item,
            &[],
            &[],
            &[],
            &sample_config(false),
        ));
        assert!(out.contains(r#""organization":{"name":"Forem""#));
        assert!(out.contains(r#""body_preview":"\u003cp\u003eStatus body\u003c/p\u003e""#));
        assert!(out.contains(r#""title_finalized_for_feed":"Status title""#));
        assert!(out.contains(r#""title_for_metadata":"Status meta""#));
    }

    #[test]
    fn float_formatting_guards_out_of_domain_values() {
        let mut out = String::new();
        assert!(write_stories_feed_float(&mut out, 5.0));
        assert_eq!(out, "5.0");
        out.clear();
        assert!(write_stories_feed_float(&mut out, 0.0));
        assert_eq!(out, "0.0");
        out.clear();
        assert!(write_stories_feed_float(&mut out, 4.25));
        assert_eq!(out, "4.25");
        assert!(!write_stories_feed_float(&mut out, f64::NAN));
        assert!(!write_stories_feed_float(&mut out, f64::INFINITY));
        assert!(!write_stories_feed_float(&mut out, 1e-6));
        assert!(!write_stories_feed_float(&mut out, 1e16));
    }
}
