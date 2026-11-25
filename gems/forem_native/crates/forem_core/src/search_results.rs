//! Single-pass streaming JSON serializers for Forem's Search endpoints (`SearchController`):
//!
//! - `GET /search/reactions` (`Search::ReadingList` / `Search::ReadingListArticleSerializer`)
//! - `GET /search/feed_content?class_name=Comment` (`Search::Comment` / `Search::CommentSerializer`)
//! - `GET /search/feed_content?class_name=Organization` (`Search::Organization` / `Search::OrganizationSerializer`)
//! - `GET /search/feed_content?class_name=PodcastEpisode` (`Search::PodcastEpisode` / `Search::PodcastEpisodeSerializer`)
//! - `GET /search/tags` & `GET /search/feed_content?class_name=Tag` (`Search::Tag` / `Search::TagSerializer`)
//! - `GET /search/feed_content?class_name=User` (`Search::User` / `Search::SimpleUserSerializer`)
//! - `GET /search/usernames` (`Search::Username` / `Search::NestedUserSerializer`)
//!
//! Replaces `JSONAPI::Serializer` wrapper hashes (`{ data: [{ id:, type:, attributes: ... }] }`),
//! `.pluck(:attributes)` array copies, `cached_tag_list.to_s.split(", ")` allocations, and
//! `ActiveSupport::JSON.encode` hash walks with single-pass Rust streaming serializers writing
//! directly into a single pre-sized UTF-8 buffer.

use std::fmt::Write;

use crate::api_articles::{
    format_readable_publish_date, format_utc_iso8601_millis, write_opt_i64, write_opt_str,
};
use crate::api_comments::encode_base26_id;
use crate::feed::iter_cached_tag_list;
use crate::json::write_json_string;

/// Minimal user tuple shared by `Search::ReadingList` and `Search::Comment`.
#[derive(Debug, Clone, Copy)]
pub struct SearchNestedUser<'a> {
    pub name: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
    pub username: Option<&'a str>,
}

/// Flat representation of a reading list row for `GET /search/reactions`.
#[derive(Debug, Clone, Copy)]
pub struct SearchReadingListItem<'a> {
    pub reaction_id: i64,
    pub reaction_user_id: i64,
    pub path: Option<&'a str>,
    pub published_at_sec: Option<i64>,
    pub crossposted_at_sec: Option<i64>,
    pub reading_time: Option<i64>,
    pub cached_tag_list: Option<&'a str>,
    pub title: Option<&'a str>,
    pub user_idx: usize,
}

/// Flat representation of a comment search row for `GET /search/feed_content?class_name=Comment`.
#[derive(Debug, Clone, Copy)]
pub struct SearchCommentItem<'a> {
    pub id: i64,
    pub public_reactions_count: i64,
    pub body_text: Option<&'a str>,
    pub has_highlight: bool,
    pub highlight_body_text: Option<&'a str>,
    pub hotness_score: Option<i64>,
    pub created_at_sec: i64,
    pub created_at_millis: u32,
    pub title: Option<&'a str>,
    pub user_idx: Option<usize>,
}

/// Flat representation of an organization search row for `GET /search/feed_content?class_name=Organization`.
#[derive(Debug, Clone, Copy)]
pub struct SearchOrganizationItem<'a> {
    pub id: i64,
    pub name: Option<&'a str>,
    pub summary: Option<&'a str>,
    pub profile_image_url: Option<&'a str>,
    pub twitter_username: Option<&'a str>,
    pub slug: Option<&'a str>,
}

/// Flat representation of a podcast episode search row for `GET /search/feed_content?class_name=PodcastEpisode`.
#[derive(Debug, Clone, Copy)]
pub struct SearchPodcastEpisodeItem<'a> {
    pub id: i64,
    pub body_text: Option<&'a str>,
    pub comments_count: Option<i64>,
    pub slug: Option<&'a str>,
    pub podcast_slug: Option<&'a str>,
    pub published_at_sec: Option<i64>,
    pub published_at_millis: u32,
    pub quote: Option<&'a str>,
    pub reactions_count: Option<i64>,
    pub subtitle: Option<&'a str>,
    pub summary: Option<&'a str>,
    pub title: Option<&'a str>,
    pub website_url: Option<&'a str>,
    pub podcast_image_url: Option<&'a str>,
}

/// Flat representation of a tag search row for `GET /search/tags` and `GET /search/feed_content?class_name=Tag`.
#[derive(Debug, Clone, Copy)]
pub struct SearchTagItem<'a> {
    pub id: i64,
    pub name: Option<&'a str>,
    pub hotness_score: Option<i64>,
    pub supported: Option<bool>,
    pub short_summary: Option<&'a str>,
    pub rules_html: Option<&'a str>,
    pub bg_color_hex: Option<&'a str>,
    pub has_badge: bool,
    pub badge_image_url: Option<&'a str>,
}

/// Flat representation of a user search row for `Search::User` and `Search::Username`.
#[derive(Debug, Clone, Copy)]
pub struct SearchUserItem<'a> {
    pub id: i64,
    pub name: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
    pub username: Option<&'a str>,
}

fn write_opt_bool(out: &mut String, value: Option<bool>) {
    match value {
        Some(true) => out.push_str("true"),
        Some(false) => out.push_str("false"),
        None => out.push_str("null"),
    }
}

fn write_prefixed_slash_str(out: &mut String, segment: Option<&str>, escape_html: bool) {
    out.push('"');
    out.push('/');
    if let Some(s) = segment {
        let start = out.len();
        write_json_string(out, s, escape_html);
        // Remove the opening quote emitted by `write_json_string` while preserving its closing quote.
        out.remove(start);
    } else {
        out.push('"');
    }
}

/// Streams `{"result":[...],"total":N}` for `Search::ReadingList` / `SearchController#reactions`.
///
/// Matches `Search::ReadingListArticleSerializer` + `{ result: items, total: total }.to_json`
/// byte-for-byte. Returns `None` if any `user_idx` is out of bounds or a timestamp falls outside
/// the supported UTC date formatting range.
pub fn serialize_search_reading_list_json(
    items: &[SearchReadingListItem<'_>],
    users: &[SearchNestedUser<'_>],
    total: i64,
    current_year: i64,
    escape_html: bool,
) -> Option<String> {
    let mut out = String::with_capacity(items.len().saturating_mul(320) + 32);
    out.push_str("{\"result\":[");

    for (idx, item) in items.iter().enumerate() {
        let user = users.get(item.user_idx)?;
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"id\":");
        let _ = write!(out, "{}", item.reaction_id);
        out.push_str(",\"user_id\":");
        let _ = write!(out, "{}", item.reaction_user_id);
        out.push_str(",\"reactable\":{\"path\":");
        write_opt_str(&mut out, item.path, escape_html);
        out.push_str(",\"readable_publish_date_string\":");
        match item.crossposted_at_sec.or(item.published_at_sec) {
            Some(ts) => {
                let formatted = format_readable_publish_date(ts, current_year)?;
                write_json_string(&mut out, &formatted, escape_html);
            }
            None => out.push_str("null"),
        }
        out.push_str(",\"reading_time\":");
        write_opt_i64(&mut out, item.reading_time);
        out.push_str(",\"tag_list\":[");
        if let Some(raw_tags) = item.cached_tag_list {
            for (tag_idx, tag) in iter_cached_tag_list(raw_tags).enumerate() {
                if tag_idx > 0 {
                    out.push(',');
                }
                write_json_string(&mut out, tag, escape_html);
            }
        }
        out.push_str("],\"tags\":[");
        if let Some(raw_tags) = item.cached_tag_list {
            for (tag_idx, tag) in iter_cached_tag_list(raw_tags).enumerate() {
                if tag_idx > 0 {
                    out.push(',');
                }
                out.push_str("{\"name\":");
                write_json_string(&mut out, tag, escape_html);
                out.push('}');
            }
        }
        out.push_str("],\"title\":");
        write_opt_str(&mut out, item.title, escape_html);
        out.push_str(",\"user\":{\"name\":");
        write_opt_str(&mut out, user.name, escape_html);
        out.push_str(",\"profile_image_90\":");
        write_opt_str(&mut out, user.profile_image_90, escape_html);
        out.push_str(",\"username\":");
        write_opt_str(&mut out, user.username, escape_html);
        out.push_str("}}}");
    }

    out.push_str("],\"total\":");
    let _ = write!(out, "{total}");
    out.push('}');
    Some(out)
}

/// Streams `{"result":[...]}` for `Search::Comment` / `SearchController#feed_content`.
///
/// Matches `Search::CommentSerializer` + `{ result: ... }.to_json` byte-for-byte.
/// Returns `None` if `id < 0`, a `user_idx` is out of bounds, or a timestamp is out of range.
pub fn serialize_search_comments_json(
    comments: &[SearchCommentItem<'_>],
    users: &[SearchNestedUser<'_>],
    current_year: i64,
    escape_html: bool,
) -> Option<String> {
    let mut out = String::with_capacity(comments.len().saturating_mul(384) + 16);
    out.push_str("{\"result\":[");

    for (idx, comment) in comments.iter().enumerate() {
        if comment.id < 0 {
            return None;
        }
        let user = match comment.user_idx {
            Some(uidx) => Some(users.get(uidx)?),
            None => None,
        };
        let published_at =
            format_utc_iso8601_millis(comment.created_at_sec, comment.created_at_millis)?;
        let readable_date = format_readable_publish_date(comment.created_at_sec, current_year)?;

        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"id\":\"comment_");
        let _ = write!(out, "{}", comment.id);
        out.push_str("\",\"path\":");
        match user {
            Some(u) => {
                let id_code = encode_base26_id(comment.id);
                out.push('"');
                out.push('/');
                if let Some(username) = u.username {
                    let start = out.len();
                    write_json_string(&mut out, username, escape_html);
                    out.remove(start);
                    out.pop();
                }
                out.push_str("/comment/");
                out.push_str(&id_code);
                out.push('"');
            }
            None => out.push_str("\"/404.html\""),
        }
        out.push_str(",\"public_reactions_count\":");
        let _ = write!(out, "{}", comment.public_reactions_count);
        out.push_str(",\"body_text\":");
        write_opt_str(&mut out, comment.body_text, escape_html);
        out.push_str(",\"class_name\":\"Comment\",\"highlight\":{\"body_text\":[");
        if comment.has_highlight {
            write_opt_str(&mut out, comment.highlight_body_text, escape_html);
        }
        out.push_str("]},\"hotness_score\":");
        write_opt_i64(&mut out, comment.hotness_score);
        out.push_str(",\"published\":true,\"published_at\":");
        write_json_string(&mut out, &published_at, escape_html);
        out.push_str(",\"readable_publish_date_string\":");
        write_json_string(&mut out, &readable_date, escape_html);
        out.push_str(",\"title\":");
        write_opt_str(&mut out, comment.title, escape_html);
        out.push_str(",\"user\":");
        match user {
            Some(u) => {
                out.push_str("{\"name\":");
                write_opt_str(&mut out, u.name, escape_html);
                out.push_str(",\"profile_image_90\":");
                write_opt_str(&mut out, u.profile_image_90, escape_html);
                out.push_str(",\"username\":");
                write_opt_str(&mut out, u.username, escape_html);
                out.push('}');
            }
            None => out.push_str("{}"),
        }
        out.push('}');
    }

    out.push_str("]}");
    Some(out)
}

/// Streams `{"result":[...]}` for `Search::Organization` / `SearchController#feed_content`.
///
/// Matches `Search::OrganizationSerializer` + `{ result: ... }.to_json` byte-for-byte.
pub fn serialize_search_organizations_json(
    orgs: &[SearchOrganizationItem<'_>],
    escape_html: bool,
) -> String {
    let mut out = String::with_capacity(orgs.len().saturating_mul(220) + 16);
    out.push_str("{\"result\":[");

    for (idx, org) in orgs.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"class_name\":\"Organization\",\"id\":");
        let _ = write!(out, "{}", org.id);
        out.push_str(",\"name\":");
        write_opt_str(&mut out, org.name, escape_html);
        out.push_str(",\"summary\":");
        write_opt_str(&mut out, org.summary, escape_html);
        out.push_str(",\"profile_image\":{\"url\":");
        write_opt_str(&mut out, org.profile_image_url, escape_html);
        out.push_str("},\"twitter_username\":");
        write_opt_str(&mut out, org.twitter_username, escape_html);
        out.push_str(",\"slug\":");
        write_opt_str(&mut out, org.slug, escape_html);
        out.push('}');
    }

    out.push_str("]}");
    out
}

/// Streams `{"result":[...]}` for `Search::PodcastEpisode` / `SearchController#feed_content`.
///
/// Matches `Search::PodcastEpisodeSerializer` + `{ result: ... }.to_json` byte-for-byte.
/// Returns `None` if a timestamp falls outside the supported UTC ISO-8601 range.
pub fn serialize_search_podcast_episodes_json(
    episodes: &[SearchPodcastEpisodeItem<'_>],
    escape_html: bool,
) -> Option<String> {
    let mut out = String::with_capacity(episodes.len().saturating_mul(512) + 16);
    out.push_str("{\"result\":[");

    for (idx, ep) in episodes.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"id\":\"podcast_episode_");
        let _ = write!(out, "{}", ep.id);
        out.push_str("\",\"body_text\":");
        write_opt_str(&mut out, ep.body_text, escape_html);
        out.push_str(",\"comments_count\":");
        write_opt_i64(&mut out, ep.comments_count);
        out.push_str(",\"path\":");
        match ep.podcast_slug {
            Some(ps) => {
                out.push('"');
                out.push('/');
                let start = out.len();
                write_json_string(&mut out, ps, escape_html);
                out.remove(start);
                out.pop();
                out.push('/');
                if let Some(slug) = ep.slug {
                    let s_start = out.len();
                    write_json_string(&mut out, slug, escape_html);
                    out.remove(s_start);
                } else {
                    out.push('"');
                }
            }
            None => out.push_str("null"),
        }
        out.push_str(",\"published_at\":");
        match ep.published_at_sec {
            Some(sec) => {
                let ts = format_utc_iso8601_millis(sec, ep.published_at_millis)?;
                write_json_string(&mut out, &ts, escape_html);
            }
            None => out.push_str("null"),
        }
        out.push_str(",\"quote\":");
        write_opt_str(&mut out, ep.quote, escape_html);
        out.push_str(",\"reactions_count\":");
        write_opt_i64(&mut out, ep.reactions_count);
        out.push_str(",\"subtitle\":");
        write_opt_str(&mut out, ep.subtitle, escape_html);
        out.push_str(",\"summary\":");
        write_opt_str(&mut out, ep.summary, escape_html);
        out.push_str(",\"title\":");
        write_opt_str(&mut out, ep.title, escape_html);
        out.push_str(",\"website_url\":");
        write_opt_str(&mut out, ep.website_url, escape_html);
        out.push_str(
            ",\"class_name\":\"PodcastEpisode\",\"highlight\":{\"body_text\":[]},\"hotness_score\":0,\"main_image\":",
        );
        write_opt_str(&mut out, ep.podcast_image_url, escape_html);
        out.push_str(",\"podcast\":{\"slug\":");
        write_opt_str(&mut out, ep.podcast_slug, escape_html);
        out.push_str(",\"image_url\":");
        write_opt_str(&mut out, ep.podcast_image_url, escape_html);
        out.push_str(",\"title\":");
        write_opt_str(&mut out, ep.title, escape_html);
        out.push_str(
            "},\"public_reactions_count\":0,\"published\":true,\"search_score\":0,\"slug\":",
        );
        write_opt_str(&mut out, ep.podcast_slug, escape_html);
        out.push_str(",\"user\":{}}");
    }

    out.push_str("]}");
    Some(out)
}

/// Streams `{"result":[...]}` for `Search::Tag` / `SearchController#tags` & `feed_content`.
///
/// Matches `Search::TagSerializer` + `{ result: ... }.to_json` byte-for-byte.
pub fn serialize_search_tags_json(tags: &[SearchTagItem<'_>], escape_html: bool) -> String {
    let mut out = String::with_capacity(tags.len().saturating_mul(240) + 16);
    out.push_str("{\"result\":[");

    for (idx, tag) in tags.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"class_name\":\"Tag\",\"id\":");
        let _ = write!(out, "{}", tag.id);
        out.push_str(",\"name\":");
        write_opt_str(&mut out, tag.name, escape_html);
        out.push_str(",\"hotness_score\":");
        write_opt_i64(&mut out, tag.hotness_score);
        out.push_str(",\"supported\":");
        write_opt_bool(&mut out, tag.supported);
        out.push_str(",\"short_summary\":");
        write_opt_str(&mut out, tag.short_summary, escape_html);
        out.push_str(",\"rules_html\":");
        write_opt_str(&mut out, tag.rules_html, escape_html);
        out.push_str(",\"bg_color_hex\":");
        write_opt_str(&mut out, tag.bg_color_hex, escape_html);
        out.push_str(",\"badge\":");
        if tag.has_badge {
            out.push_str("{\"badge_image\":{\"url\":");
            write_opt_str(&mut out, tag.badge_image_url, escape_html);
            out.push_str("}}");
        } else {
            out.push_str("null");
        }
        out.push('}');
    }

    out.push_str("]}");
    out
}

/// Streams `{"result":[...]}` for `Search::User` / `Search::SimpleUserSerializer`.
///
/// Matches `Search::SimpleUserSerializer` + `{ result: ... }.to_json` byte-for-byte.
pub fn serialize_search_users_json(users: &[SearchUserItem<'_>], escape_html: bool) -> String {
    let mut out = String::with_capacity(users.len().saturating_mul(180) + 16);
    out.push_str("{\"result\":[");

    for (idx, user) in users.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"class_name\":\"User\",\"id\":");
        let _ = write!(out, "{}", user.id);
        out.push_str(",\"path\":");
        write_prefixed_slash_str(&mut out, user.username, escape_html);
        out.push_str(",\"title\":");
        write_opt_str(&mut out, user.name, escape_html);
        out.push_str(",\"user\":{\"name\":");
        write_opt_str(&mut out, user.username, escape_html);
        out.push_str(",\"profile_image_90\":");
        write_opt_str(&mut out, user.profile_image_90, escape_html);
        out.push_str(",\"username\":");
        write_opt_str(&mut out, user.username, escape_html);
        out.push_str("}}");
    }

    out.push_str("]}");
    out
}

/// Streams `{"result":[...]}` for `Search::Username` / `Search::NestedUserSerializer`.
///
/// Matches `Search::NestedUserSerializer` + `{ result: ... }.to_json` byte-for-byte.
pub fn serialize_search_usernames_json(users: &[SearchUserItem<'_>], escape_html: bool) -> String {
    let mut out = String::with_capacity(users.len().saturating_mul(140) + 16);
    out.push_str("{\"result\":[");

    for (idx, user) in users.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"id\":");
        let _ = write!(out, "{}", user.id);
        out.push_str(",\"name\":");
        write_opt_str(&mut out, user.name, escape_html);
        out.push_str(",\"profile_image_90\":");
        write_opt_str(&mut out, user.profile_image_90, escape_html);
        out.push_str(",\"username\":");
        write_opt_str(&mut out, user.username, escape_html);
        out.push('}');
    }

    out.push_str("]}");
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reading_list_serializes_items_tags_and_total() {
        let users = [SearchNestedUser {
            name: Some("Ben <Halpern>"),
            profile_image_90: Some("https://cdn.example.com/ben_90.png"),
            username: Some("ben"),
        }];
        let items = [
            SearchReadingListItem {
                reaction_id: 10,
                reaction_user_id: 2,
                path: Some("/ben/rust-123"),
                published_at_sec: Some(1_736_000_000), // 2025-01-04
                crossposted_at_sec: None,
                reading_time: Some(5),
                cached_tag_list: Some("rust, ruby, "),
                title: Some("Rust & Rails"),
                user_idx: 0,
            },
            SearchReadingListItem {
                reaction_id: 11,
                reaction_user_id: 2,
                path: Some("/ben/empty"),
                published_at_sec: None,
                crossposted_at_sec: None,
                reading_time: None,
                cached_tag_list: None,
                title: None,
                user_idx: 0,
            },
        ];

        let json = serialize_search_reading_list_json(&items, &users, 42, 2025, true).unwrap();
        assert_eq!(
            json,
            r#"{"result":[{"id":10,"user_id":2,"reactable":{"path":"/ben/rust-123","readable_publish_date_string":"Jan 4","reading_time":5,"tag_list":["rust","ruby"],"tags":[{"name":"rust"},{"name":"ruby"}],"title":"Rust \u0026 Rails","user":{"name":"Ben \u003cHalpern\u003e","profile_image_90":"https://cdn.example.com/ben_90.png","username":"ben"}}},{"id":11,"user_id":2,"reactable":{"path":"/ben/empty","readable_publish_date_string":null,"reading_time":null,"tag_list":[],"tags":[],"title":null,"user":{"name":"Ben \u003cHalpern\u003e","profile_image_90":"https://cdn.example.com/ben_90.png","username":"ben"}}}],"total":42}"#
        );
    }

    #[test]
    fn reading_list_returns_none_on_invalid_user_idx() {
        let items = [SearchReadingListItem {
            reaction_id: 1,
            reaction_user_id: 1,
            path: None,
            published_at_sec: None,
            crossposted_at_sec: None,
            reading_time: None,
            cached_tag_list: None,
            title: None,
            user_idx: 3,
        }];
        assert!(serialize_search_reading_list_json(&items, &[], 1, 2025, true).is_none());
    }

    #[test]
    fn comments_serializes_with_and_without_user_and_highlight() {
        let users = [SearchNestedUser {
            name: Some("Alice"),
            profile_image_90: Some("https://cdn.example.com/alice.png"),
            username: Some("alice"),
        }];
        let comments = [
            SearchCommentItem {
                id: 1000,
                public_reactions_count: 7,
                body_text: Some("Great post!"),
                has_highlight: true,
                highlight_body_text: Some("<b>Great</b> post!"),
                hotness_score: Some(15),
                created_at_sec: 1_736_000_000,
                created_at_millis: 123,
                title: Some("My Article"),
                user_idx: Some(0),
            },
            SearchCommentItem {
                id: 1001,
                public_reactions_count: 0,
                body_text: Some("Orphan"),
                has_highlight: false,
                highlight_body_text: None,
                hotness_score: Some(0),
                created_at_sec: 1_704_067_200, // 2024-01-01
                created_at_millis: 0,
                title: Some(""),
                user_idx: None,
            },
        ];

        let json = serialize_search_comments_json(&comments, &users, 2025, true).unwrap();
        assert_eq!(
            json,
            r#"{"result":[{"id":"comment_1000","path":"/alice/comment/1cc","public_reactions_count":7,"body_text":"Great post!","class_name":"Comment","highlight":{"body_text":["\u003cb\u003eGreat\u003c/b\u003e post!"]},"hotness_score":15,"published":true,"published_at":"2025-01-04T14:13:20.123Z","readable_publish_date_string":"Jan 4","title":"My Article","user":{"name":"Alice","profile_image_90":"https://cdn.example.com/alice.png","username":"alice"}},{"id":"comment_1001","path":"/404.html","public_reactions_count":0,"body_text":"Orphan","class_name":"Comment","highlight":{"body_text":[]},"hotness_score":0,"published":true,"published_at":"2024-01-01T00:00:00.000Z","readable_publish_date_string":"Jan 1 '24","title":"","user":{}}]}"#
        );
    }

    #[test]
    fn organizations_serializes_uploader_url() {
        let orgs = [SearchOrganizationItem {
            id: 5,
            name: Some("Forem"),
            summary: Some("Open source"),
            profile_image_url: Some("/uploads/org/5.png"),
            twitter_username: Some("forem"),
            slug: Some("forem"),
        }];
        let json = serialize_search_organizations_json(&orgs, true);
        assert_eq!(
            json,
            r#"{"result":[{"class_name":"Organization","id":5,"name":"Forem","summary":"Open source","profile_image":{"url":"/uploads/org/5.png"},"twitter_username":"forem","slug":"forem"}]}"#
        );
    }

    #[test]
    fn podcast_episodes_serializes_path_and_nested_podcast() {
        let eps = [SearchPodcastEpisodeItem {
            id: 9,
            body_text: Some("Episode body"),
            comments_count: Some(3),
            slug: Some("ep-1"),
            podcast_slug: Some("dev-pod"),
            published_at_sec: Some(1_736_000_000),
            published_at_millis: 45,
            quote: Some("A quote"),
            reactions_count: Some(12),
            subtitle: Some("Sub"),
            summary: Some("Sum"),
            title: Some("Ep 1"),
            website_url: Some("https://pod.example.com/1"),
            podcast_image_url: Some("https://cdn.example.com/pod_90.png"),
        }];
        let json = serialize_search_podcast_episodes_json(&eps, true).unwrap();
        assert_eq!(
            json,
            r#"{"result":[{"id":"podcast_episode_9","body_text":"Episode body","comments_count":3,"path":"/dev-pod/ep-1","published_at":"2025-01-04T14:13:20.045Z","quote":"A quote","reactions_count":12,"subtitle":"Sub","summary":"Sum","title":"Ep 1","website_url":"https://pod.example.com/1","class_name":"PodcastEpisode","highlight":{"body_text":[]},"hotness_score":0,"main_image":"https://cdn.example.com/pod_90.png","podcast":{"slug":"dev-pod","image_url":"https://cdn.example.com/pod_90.png","title":"Ep 1"},"public_reactions_count":0,"published":true,"search_score":0,"slug":"dev-pod","user":{}}]}"#
        );
    }

    #[test]
    fn tags_serializes_with_and_without_badge() {
        let tags = [
            SearchTagItem {
                id: 1,
                name: Some("rust"),
                hotness_score: Some(500),
                supported: Some(true),
                short_summary: Some("Systems programming"),
                rules_html: Some("<p>Be nice</p>"),
                bg_color_hex: Some("#dea584"),
                has_badge: true,
                badge_image_url: Some("/uploads/badge/1.png"),
            },
            SearchTagItem {
                id: 2,
                name: Some("ruby"),
                hotness_score: Some(400),
                supported: Some(false),
                short_summary: None,
                rules_html: None,
                bg_color_hex: None,
                has_badge: false,
                badge_image_url: None,
            },
        ];
        let json = serialize_search_tags_json(&tags, true);
        assert_eq!(
            json,
            r##"{"result":[{"class_name":"Tag","id":1,"name":"rust","hotness_score":500,"supported":true,"short_summary":"Systems programming","rules_html":"\u003cp\u003eBe nice\u003c/p\u003e","bg_color_hex":"#dea584","badge":{"badge_image":{"url":"/uploads/badge/1.png"}}},{"class_name":"Tag","id":2,"name":"ruby","hotness_score":400,"supported":false,"short_summary":null,"rules_html":null,"bg_color_hex":null,"badge":null}]}"##
        );
    }

    #[test]
    fn users_and_usernames_serialize_expected_shapes() {
        let users = [SearchUserItem {
            id: 7,
            name: Some("Sloan"),
            profile_image_90: Some("https://cdn.example.com/sloan.png"),
            username: Some("sloan"),
        }];
        assert_eq!(
            serialize_search_users_json(&users, false),
            r#"{"result":[{"class_name":"User","id":7,"path":"/sloan","title":"Sloan","user":{"name":"sloan","profile_image_90":"https://cdn.example.com/sloan.png","username":"sloan"}}]}"#
        );
        assert_eq!(
            serialize_search_usernames_json(&users, false),
            r#"{"result":[{"id":7,"name":"Sloan","profile_image_90":"https://cdn.example.com/sloan.png","username":"sloan"}]}"#
        );
    }
}
