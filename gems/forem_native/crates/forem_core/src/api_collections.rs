//! Single-pass streaming JSON serializers for Forem's collection API endpoints:
//!
//! - `Api::V0::TagsController` / `Api::V1::TagsController` (`index`, `supported`)
//! - `Api::V0::FollowsController` / `Api::V1::FollowsController` (`tags`)
//! - `Api::V0::FollowersController` / `Api::V1::FollowersController` (`users`)
//! - `Api::V0::PodcastEpisodesController` / `Api::V1::PodcastEpisodesController` (`index`)
//! - `Api::V0::VideosController` / `Api::V1::VideosController` (`index`)
//! - `Api::V0::ReadinglistController` / `Api::V1::ReadinglistController` (`index`)
//!
//! Replaces ActiveRecord model hydration, Draper decorators, `Profile.instantiate`,
//! and per-row Jbuilder / ActionView partial rendering with zero-intermediate-hash
//! Rust streaming serializers writing directly into a single pre-sized UTF-8 buffer.

use std::fmt::Write;

use crate::api_articles::{
    check_blank, optimize_image_url, write_article_common_fields, write_opt_i64, write_opt_str,
    write_opt_utc_iso8601, write_organization_object, write_user_object, ApiArticleOrganization,
    ApiArticleRow, ApiArticleUser, ApiArticlesConfig, ImageOptimizerMode,
};
use crate::feed::format_video_duration;
use crate::json::write_json_string;
use crate::reactions::write_json_float;

/// Flat representation of a tag row for `GET /api/tags` and `GET /api/tags/supported`.
#[derive(Debug, Clone, Copy)]
pub struct ApiTagRow<'a> {
    pub id: i64,
    pub name: Option<&'a str>,
    pub bg_color_hex: Option<&'a str>,
    pub text_color_hex: Option<&'a str>,
    pub short_summary: Option<&'a str>,
}

/// Flat representation of a followed tag row for `GET /api/follows/tags`.
#[derive(Debug, Clone, Copy)]
pub struct ApiFollowedTagRow<'a> {
    pub id: i64,
    pub name: Option<&'a str>,
    pub points: Option<f64>,
}

/// Flat representation of a follower row for `GET /api/followers/users`.
#[derive(Debug, Clone, Copy)]
pub struct ApiFollowerRow<'a> {
    pub id: i64,
    pub created_at_sec: Option<i64>,
    pub user_id: i64,
    pub name: Option<&'a str>,
    pub path: Option<&'a str>,
    pub username: Option<&'a str>,
    pub profile_image: Option<&'a str>,
}

/// Flat representation of a podcast episode row for `GET /api/podcast_episodes`.
#[derive(Debug, Clone, Copy)]
pub struct ApiPodcastEpisodeRow<'a> {
    pub id: i64,
    pub slug: Option<&'a str>,
    pub title: Option<&'a str>,
    pub image_url: Option<&'a str>,
    pub podcast_title: Option<&'a str>,
    pub podcast_slug: Option<&'a str>,
    pub podcast_image_url: Option<&'a str>,
}

/// Flat representation of a video article row for `GET /api/videos`.
#[derive(Debug, Clone, Copy)]
pub struct ApiVideoRow<'a> {
    pub id: i64,
    pub path: Option<&'a str>,
    pub video_thumbnail_url: Option<&'a str>,
    pub video: Option<&'a str>,
    pub title: Option<&'a str>,
    pub user_id: Option<i64>,
    pub video_duration_in_seconds: Option<i64>,
    pub video_source_url: Option<&'a str>,
    pub user_name: Option<&'a str>,
}

/// Request-scoped image optimizer config for `GET /api/videos`.
#[derive(Debug, Clone, Copy)]
pub struct ApiVideosConfig<'a> {
    pub optimizer_mode: ImageOptimizerMode,
    pub cloudflare_domain: Option<&'a str>,
    pub cloudflare_directory: &'a str,
    pub escape_html_entities: bool,
}

/// Flat representation of a readinglist reaction + article row for `GET /api/readinglist`.
#[derive(Debug, Clone, Copy)]
pub struct ApiReadinglistItem<'a> {
    pub id: i64,
    pub status: Option<&'a str>,
    pub created_at_sec: Option<i64>,
    pub article: ApiArticleRow<'a>,
}

/// Writes `"/#{path.delete_prefix('/')}"` as a JSON string directly into `out`
/// without allocating an intermediate `String`.
fn write_normalized_leading_slash_path(out: &mut String, path: &str, escape_html: bool) {
    let stripped = path.strip_prefix('/').unwrap_or(path);
    out.push('"');
    out.push('/');
    // Emit escaped contents of `stripped` (reuse `write_json_string` by writing into a
    // temporary slice without quotes? Better: write_json_string writes surrounding quotes,
    // so if `path` already starts with `/` we can pass `path` directly with zero extra work!).
    if path.starts_with('/') {
        // Pop the `"/` we pushed and emit `path` directly via `write_json_string`.
        out.pop();
        out.pop();
        write_json_string(out, path, escape_html);
    } else {
        // Push escaped body without outer quotes.
        let start = out.len();
        write_json_string(out, stripped, escape_html);
        // `write_json_string` appended `"<escaped>"`; remove the inner opening quote at `start`.
        out.remove(start);
    }
}

/// Streams a JSON array matching `api/v{0,1}/tags/index.json.jbuilder`.
pub fn serialize_api_tags_json(tags: &[ApiTagRow<'_>], escape_html: bool) -> String {
    if tags.is_empty() {
        return "[]".to_string();
    }

    let mut out = String::with_capacity(tags.len() * 140 + 2);
    out.push('[');

    for (idx, tag) in tags.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"id\":");
        let _ = write!(out, "{}", tag.id);
        out.push_str(",\"name\":");
        write_opt_str(&mut out, tag.name, escape_html);
        out.push_str(",\"bg_color_hex\":");
        write_opt_str(&mut out, tag.bg_color_hex, escape_html);
        out.push_str(",\"text_color_hex\":");
        write_opt_str(&mut out, tag.text_color_hex, escape_html);
        out.push_str(",\"short_summary\":");
        write_opt_str(&mut out, tag.short_summary, escape_html);
        out.push('}');
    }

    out.push(']');
    out
}

/// Streams a JSON array matching `api/v{0,1}/follows/tags.json.jbuilder`.
///
/// Returns `None` if any `points` float falls outside [`write_json_float`]'s exact-parity
/// domain (non-finite or non-dyadic decimals), deferring cleanly to Ruby.
pub fn serialize_api_followed_tags_json(
    tags: &[ApiFollowedTagRow<'_>],
    escape_html: bool,
) -> Option<String> {
    if tags.is_empty() {
        return Some("[]".to_string());
    }

    let mut out = String::with_capacity(tags.len() * 64 + 2);
    out.push('[');

    for (idx, tag) in tags.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"id\":");
        let _ = write!(out, "{}", tag.id);
        out.push_str(",\"name\":");
        write_opt_str(&mut out, tag.name, escape_html);
        out.push_str(",\"points\":");
        match tag.points {
            Some(pts) => {
                if !write_json_float(&mut out, pts) {
                    return None;
                }
            }
            None => out.push_str("null"),
        }
        out.push('}');
    }

    out.push(']');
    Some(out)
}

/// Streams a JSON array matching `api/v{0,1}/followers/users.json.jbuilder` +
/// `api/v{0,1}/shared/_follows.json.jbuilder`.
///
/// Returns `None` if any `created_at_sec` is outside `0..=9999` or `path` is `None`.
pub fn serialize_api_followers_json(
    followers: &[ApiFollowerRow<'_>],
    escape_html: bool,
) -> Option<String> {
    if followers.is_empty() {
        return Some("[]".to_string());
    }

    let mut out = String::with_capacity(followers.len() * 240 + 2);
    out.push('[');

    for (idx, row) in followers.iter().enumerate() {
        let path = row.path?;
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"type_of\":\"user_follower\",\"id\":");
        let _ = write!(out, "{}", row.id);
        out.push_str(",\"created_at\":");
        if !write_opt_utc_iso8601(&mut out, row.created_at_sec) {
            return None;
        }
        out.push_str(",\"user_id\":");
        let _ = write!(out, "{}", row.user_id);
        out.push_str(",\"name\":");
        write_opt_str(&mut out, row.name, escape_html);
        out.push_str(",\"path\":");
        write_normalized_leading_slash_path(&mut out, path, escape_html);
        out.push_str(",\"username\":");
        write_opt_str(&mut out, row.username.or(row.name), escape_html);
        out.push_str(",\"profile_image\":");
        write_opt_str(&mut out, row.profile_image, escape_html);
        out.push('}');
    }

    out.push(']');
    Some(out)
}

/// Streams a JSON array matching `api/v{0,1}/podcast_episodes/index.json.jbuilder`.
pub fn serialize_api_podcast_episodes_json(
    episodes: &[ApiPodcastEpisodeRow<'_>],
    escape_html: bool,
) -> String {
    if episodes.is_empty() {
        return "[]".to_string();
    }

    let mut out = String::with_capacity(episodes.len() * 320 + 2);
    let mut path_buf = String::new();
    out.push('[');

    for (idx, ep) in episodes.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"type_of\":\"podcast_episodes\",\"class_name\":\"PodcastEpisode\",\"id\":");
        let _ = write!(out, "{}", ep.id);
        out.push_str(",\"path\":");
        match ep.podcast_slug {
            Some(pslug) => {
                path_buf.clear();
                path_buf.push('/');
                path_buf.push_str(pslug);
                path_buf.push('/');
                if let Some(eslug) = ep.slug {
                    path_buf.push_str(eslug);
                }
                write_json_string(&mut out, &path_buf, escape_html);
            }
            None => out.push_str("null"),
        }
        out.push_str(",\"title\":");
        write_opt_str(&mut out, ep.title, escape_html);
        out.push_str(",\"image_url\":");
        write_opt_str(&mut out, ep.image_url.or(ep.podcast_image_url), escape_html);
        out.push_str(",\"podcast\":{\"title\":");
        write_opt_str(&mut out, ep.podcast_title, escape_html);
        out.push_str(",\"slug\":");
        write_opt_str(&mut out, ep.podcast_slug, escape_html);
        out.push_str(",\"image_url\":");
        write_opt_str(&mut out, ep.podcast_image_url, escape_html);
        out.push_str("}}");
    }

    out.push(']');
    out
}

/// Streams a JSON array matching `api/v{0,1}/videos/index.json.jbuilder`.
///
/// Returns `None` if any video has a negative duration or an out-of-domain thumbnail URL
/// requiring Ruby's `Images::Optimizer` fallback.
pub fn serialize_api_videos_json(
    videos: &[ApiVideoRow<'_>],
    config: &ApiVideosConfig<'_>,
) -> Option<String> {
    if videos.is_empty() {
        return Some("[]".to_string());
    }

    let escape_html = config.escape_html_entities;
    let articles_cfg = ApiArticlesConfig {
        current_year: 2026,
        cover_image_height: 420,
        cover_image_fit: "crop",
        main_social_image: "",
        optimizer_mode: config.optimizer_mode,
        cloudflare_domain: config.cloudflare_domain,
        cloudflare_directory: config.cloudflare_directory,
        ai_disclosure_labels: ["", "", "", ""],
        is_development: false,
        escape_html_entities: escape_html,
    };

    let mut out = String::with_capacity(videos.len() * 340 + 2);
    out.push('[');

    for (idx, vid) in videos.iter().enumerate() {
        let duration_str = format_video_duration(vid.video_duration_in_seconds.unwrap_or(0))?;
        let cloudinary_url: Option<String> = match vid.video_thumbnail_url {
            Some(raw) if !check_blank(raw)? => {
                Some(optimize_image_url(raw, "880", "", "", &articles_cfg)?)
            }
            _ => None,
        };

        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"type_of\":\"video_article\",\"id\":");
        let _ = write!(out, "{}", vid.id);
        out.push_str(",\"path\":");
        write_opt_str(&mut out, vid.path, escape_html);
        out.push_str(",\"cloudinary_video_url\":");
        write_opt_str(&mut out, cloudinary_url.as_deref(), escape_html);
        out.push_str(",\"video\":");
        write_opt_str(&mut out, vid.video, escape_html);
        out.push_str(",\"title\":");
        write_opt_str(&mut out, vid.title, escape_html);
        out.push_str(",\"user_id\":");
        write_opt_i64(&mut out, vid.user_id);
        out.push_str(",\"video_duration_in_minutes\":");
        write_json_string(&mut out, &duration_str, escape_html);
        out.push_str(",\"video_source_url\":");
        write_opt_str(&mut out, vid.video_source_url, escape_html);
        out.push_str(",\"user\":{\"name\":");
        write_opt_str(&mut out, vid.user_name, escape_html);
        out.push_str("}}");
    }

    out.push(']');
    Some(out)
}

/// Streams a JSON array matching `api/v{0,1}/readinglist/index.json.jbuilder` (including
/// `_article`, `tags`, `_user`, and optional `_organization` partials) in a single pass.
///
/// Returns `None` on out-of-domain timestamps, indices, or URLs so the caller can fall back
/// transparently to Jbuilder.
pub fn serialize_api_readinglist_json(
    items: &[ApiReadinglistItem<'_>],
    users: &[ApiArticleUser<'_>],
    orgs: &[ApiArticleOrganization<'_>],
    base_urls: &[&str],
    config: &ApiArticlesConfig<'_>,
) -> Option<String> {
    if items.is_empty() {
        return Some("[]".to_string());
    }

    let escape_html = config.escape_html_entities;
    let cover_height_str = config.cover_image_height.to_string();
    let mut out = String::with_capacity(items.len() * 1450 + 2);
    out.push('[');

    for (idx, item) in items.iter().enumerate() {
        let article = &item.article;
        let user = users.get(usize::try_from(article.user_idx).ok()?)?;
        let base_url = *base_urls.get(usize::try_from(article.base_url_idx).ok()?)?;
        let org = if article.org_idx >= 0 {
            Some(orgs.get(usize::try_from(article.org_idx).ok()?)?)
        } else {
            None
        };

        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"type_of\":\"readinglist\",\"id\":");
        let _ = write!(out, "{}", item.id);
        out.push_str(",\"status\":");
        write_opt_str(&mut out, item.status, escape_html);
        out.push_str(",\"created_at\":");
        if !write_opt_utc_iso8601(&mut out, item.created_at_sec) {
            return None;
        }
        out.push_str(",\"article\":");
        write_article_common_fields(&mut out, article, base_url, &cover_height_str, config)?;
        out.push_str(",\"tags\":");
        write_opt_str(&mut out, article.cached_tag_list, escape_html);
        out.push_str(",\"user\":");
        write_user_object(&mut out, user, escape_html);
        if let Some(org) = org {
            out.push_str(",\"organization\":");
            write_organization_object(&mut out, org, escape_html);
        }
        out.push_str("}}");
    }

    out.push(']');
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn serializes_tags_with_html_escaping_and_nulls() {
        let rows = [
            ApiTagRow {
                id: 1,
                name: Some("rust"),
                bg_color_hex: Some("#000000"),
                text_color_hex: Some("#ffffff"),
                short_summary: Some("A <fast> & safe language"),
            },
            ApiTagRow {
                id: 2,
                name: Some("ruby"),
                bg_color_hex: None,
                text_color_hex: None,
                short_summary: None,
            },
        ];
        let json = serialize_api_tags_json(&rows, true);
        assert_eq!(
            json,
            r##"[{"id":1,"name":"rust","bg_color_hex":"#000000","text_color_hex":"#ffffff","short_summary":"A \u003cfast\u003e \u0026 safe language"},{"id":2,"name":"ruby","bg_color_hex":null,"text_color_hex":null,"short_summary":null}]"##
        );
    }

    #[test]
    fn serializes_followed_tags_and_defers_non_dyadic_floats() {
        let rows = [ApiFollowedTagRow {
            id: 7,
            name: Some("javascript"),
            points: Some(1.5),
        }];
        assert_eq!(
            serialize_api_followed_tags_json(&rows, true).as_deref(),
            Some(r#"[{"id":7,"name":"javascript","points":1.5}]"#)
        );

        let non_dyadic = [ApiFollowedTagRow {
            id: 8,
            name: Some("python"),
            points: Some(0.1),
        }];
        assert_eq!(serialize_api_followed_tags_json(&non_dyadic, true), None);
    }

    #[test]
    fn serializes_followers_normalizing_leading_slash_and_fallback_username() {
        let rows = [
            ApiFollowerRow {
                id: 10,
                created_at_sec: Some(1_700_000_000),
                user_id: 42,
                name: Some("Alice"),
                path: Some("/alice"),
                username: Some("alice"),
                profile_image: Some("https://cdn.example.com/a.png"),
            },
            ApiFollowerRow {
                id: 11,
                created_at_sec: Some(1_700_000_001),
                user_id: 43,
                name: Some("Bob <Org>"),
                path: Some("bob"),
                username: None,
                profile_image: None,
            },
        ];
        let json = serialize_api_followers_json(&rows, true).unwrap();
        assert_eq!(
            json,
            r#"[{"type_of":"user_follower","id":10,"created_at":"2023-11-14T22:13:20Z","user_id":42,"name":"Alice","path":"/alice","username":"alice","profile_image":"https://cdn.example.com/a.png"},{"type_of":"user_follower","id":11,"created_at":"2023-11-14T22:13:21Z","user_id":43,"name":"Bob \u003cOrg\u003e","path":"/bob","username":"Bob \u003cOrg\u003e","profile_image":null}]"#
        );
    }

    #[test]
    fn serializes_podcast_episodes_with_image_fallback_and_path() {
        let rows = [
            ApiPodcastEpisodeRow {
                id: 5,
                slug: Some("ep-1"),
                title: Some("Episode 1"),
                image_url: None,
                podcast_title: Some("My Pod"),
                podcast_slug: Some("mypod"),
                podcast_image_url: Some("https://cdn.example.com/pod.png"),
            },
            ApiPodcastEpisodeRow {
                id: 6,
                slug: Some("ep-2"),
                title: Some("Episode 2"),
                image_url: Some("https://cdn.example.com/ep2.png"),
                podcast_title: Some("My Pod"),
                podcast_slug: None,
                podcast_image_url: Some("https://cdn.example.com/pod.png"),
            },
        ];
        let json = serialize_api_podcast_episodes_json(&rows, true);
        assert_eq!(
            json,
            r#"[{"type_of":"podcast_episodes","class_name":"PodcastEpisode","id":5,"path":"/mypod/ep-1","title":"Episode 1","image_url":"https://cdn.example.com/pod.png","podcast":{"title":"My Pod","slug":"mypod","image_url":"https://cdn.example.com/pod.png"}},{"type_of":"podcast_episodes","class_name":"PodcastEpisode","id":6,"path":null,"title":"Episode 2","image_url":"https://cdn.example.com/ep2.png","podcast":{"title":"My Pod","slug":null,"image_url":"https://cdn.example.com/pod.png"}}]"#
        );
    }

    #[test]
    fn serializes_videos_with_duration_and_cloudflare_optimizer() {
        let rows = [ApiVideoRow {
            id: 99,
            path: Some("/alice/video-1"),
            video_thumbnail_url: Some("https://media.example.com/thumb.jpg"),
            video: Some("https://video.example.com/v.m3u8"),
            title: Some("Demo Video"),
            user_id: Some(42),
            video_duration_in_seconds: Some(3665),
            video_source_url: Some("https://video.example.com/src.mp4"),
            user_name: Some("Alice"),
        }];
        let cfg = ApiVideosConfig {
            optimizer_mode: ImageOptimizerMode::Cloudflare,
            cloudflare_domain: Some("media2.dev.to"),
            cloudflare_directory: "dynamic",
            escape_html_entities: true,
        };
        let json = serialize_api_videos_json(&rows, &cfg).unwrap();
        assert!(json.contains(r#""video_duration_in_minutes":"1:01:05""#));
        assert!(json.contains(
            r#""cloudinary_video_url":"https://media2.dev.to/dynamic/image/width=880,height=,fit=scale-down,gravity=auto,format=auto/https%3A%2F%2Fmedia.example.com%2Fthumb.jpg""#
        ));
        assert!(json.contains(r#""user":{"name":"Alice"}"#));
    }

    #[test]
    fn serializes_readinglist_with_embedded_article_user_and_org() {
        let items = [ApiReadinglistItem {
            id: 77,
            status: Some("valid"),
            created_at_sec: Some(1_700_000_000),
            article: ApiArticleRow {
                id: 101,
                user_idx: 0,
                org_idx: 0,
                base_url_idx: 0,
                url_path: Some("/alice/hello"),
                collection_id: None,
                title: Some("Hello"),
                description: Some("Desc"),
                main_image: None,
                social_image: None,
                video_thumbnail_url: None,
                cached_tag_list: Some("rust, ruby"),
                slug: Some("hello"),
                path: Some("/alice/hello"),
                canonical_url: None,
                comments_count: Some(2),
                public_reactions_count: Some(5),
                reading_time: Some(3),
                subforem_id: Some(1),
                language: Some("en"),
                published: true,
                ai_disclosure_idx: 0,
                created_at_sec: Some(1_700_000_000),
                edited_at_sec: None,
                crossposted_at_sec: None,
                published_at_sec: Some(1_700_000_000),
                last_comment_at_sec: Some(1_700_000_000),
                social_image_large: false,
            },
        }];
        let users = [ApiArticleUser {
            id: 42,
            name: Some("Alice"),
            username: Some("alice"),
            twitter_username: None,
            github_username: None,
            website_url: None,
            profile_image: Some("https://cdn.example.com/a640.png"),
            profile_image_90: Some("https://cdn.example.com/a90.png"),
        }];
        let orgs = [ApiArticleOrganization {
            name: Some("Forem"),
            username: Some("forem"),
            slug: Some("forem"),
            profile_image: Some("https://cdn.example.com/o640.png"),
            profile_image_90: Some("https://cdn.example.com/o90.png"),
        }];
        let base_urls = ["https://dev.to"];
        let cfg = ApiArticlesConfig {
            current_year: 2023,
            cover_image_height: 420,
            cover_image_fit: "crop",
            main_social_image: "https://dev.to/social.png",
            optimizer_mode: ImageOptimizerMode::Passthrough,
            cloudflare_domain: None,
            cloudflare_directory: "cdn-cgi",
            ai_disclosure_labels: ["Not disclosed", "No AI", "Some AI", "Fully autonomous"],
            is_development: false,
            escape_html_entities: true,
        };
        let json = serialize_api_readinglist_json(&items, &users, &orgs, &base_urls, &cfg).unwrap();
        assert!(json.starts_with(r#"[{"type_of":"readinglist","id":77,"status":"valid","created_at":"2023-11-14T22:13:20Z","article":{"type_of":"article","id":101,"#));
        assert!(json.contains(r#""tags":"rust, ruby""#));
        assert!(json.contains(r#""user":{"name":"Alice""#));
        assert!(json.contains(r#""organization":{"name":"Forem""#));
    }
}
