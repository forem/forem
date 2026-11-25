//! Pure-Rust kernels for Forem's Notification JSON payload serialization and
//! single-statement bulk `INSERT ... SELECT ... FROM unnest(...) ON CONFLICT DO UPDATE`
//! SQL generation (`Notifications::NotifiableAction::Send` and `Notifications::CoAuthor::Send`).
//!
//! - **Tier 1 composable primitives**:
//!   - [`serialize_article_notification_json`]: single-pass streaming JSON serializer
//!     matching `Notifications.user_data` + `Notifications.article_data` + optional
//!     `Notifications.organization_data` (`ActiveSupport::JSON.encode` parity).
//!   - [`build_notification_bulk_upsert_sql`]: single-statement PostgreSQL `unnest`
//!     bulk upsert SQL builder that embeds `json_data` **once** (instead of `N` copies)
//!     and deduplicates `user_ids` in-place to prevent `PG::CardinalityViolation`.
//! - **Tier 2 single-pass fused kernel**:
//!   - [`build_article_notification_bulk_upsert_sql`]: crosses the Ruby <-> Rust FFI
//!     boundary once, streaming the article notification JSON directly into the bulk
//!     upsert SQL buffer with zero intermediate Ruby `Hash` or `String` allocations.

use std::collections::HashSet;
use std::fmt::Write as _;

use crate::api_articles::write_utc_iso8601_millis;
use crate::json::write_json_string;
use crate::metal::{push_quoted_nullable_sql_str, push_quoted_utc_timestamp};

/// Flat representation of `Notifications.user_data(user)`.
#[derive(Debug, Clone, Copy)]
pub struct NotificationUserData<'a> {
    pub id: Option<i64>,
    pub name: Option<&'a str>,
    pub username: Option<&'a str>,
    pub path: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
    pub comments_count: Option<i64>,
    pub created_at: Option<(i64, u32)>,
}

/// Flat representation of `Notifications.article_data(article)`.
#[derive(Debug, Clone, Copy)]
pub struct NotificationArticleData<'a> {
    pub id: Option<i64>,
    pub cached_tag_list: Option<&'a str>,
    pub title: Option<&'a str>,
    pub path: Option<&'a str>,
    pub updated_at: Option<(i64, u32)>,
    pub published_at: Option<(i64, u32)>,
    pub readable_publish_date: Option<&'a str>,
    pub reading_time: Option<i64>,
}

/// Flat representation of `Notifications.organization_data(organization)`.
#[derive(Debug, Clone, Copy)]
pub struct NotificationOrganizationData<'a> {
    pub id: Option<i64>,
    pub name: Option<&'a str>,
    pub slug: Option<&'a str>,
    pub path: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
}

/// Combined payload for article follower & co-author notifications.
#[derive(Debug, Clone, Copy)]
pub struct ArticleNotificationPayload<'a> {
    pub user: NotificationUserData<'a>,
    pub article: NotificationArticleData<'a>,
    pub organization: Option<NotificationOrganizationData<'a>>,
}

/// Parameters for [`build_notification_bulk_upsert_sql`].
#[derive(Debug, Clone, Copy)]
pub struct NotificationBulkUpsert<'a> {
    pub user_ids: &'a [i64],
    pub notifiable_id: i64,
    pub notifiable_type: &'a str,
    pub subforem_id: Option<i64>,
    pub action: Option<&'a str>,
    pub json_data: &'a str,
    pub now_sec: i64,
    pub now_usec: u32,
    pub returning_id: bool,
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
fn write_opt_str(out: &mut String, val: Option<&str>) {
    match val {
        Some(s) => write_json_string(out, s, true),
        None => out.push_str("null"),
    }
}

#[inline]
fn write_opt_utc_millis(out: &mut String, ts: Option<(i64, u32)>) -> bool {
    match ts {
        Some((sec, millis)) => {
            out.push('"');
            if !write_utc_iso8601_millis(out, sec, millis) {
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

/// Writes `ArticleDecorator#cached_tag_list_array` (`(cached_tag_list || "").split(", ")`)
/// as a JSON array of strings, matching Ruby's `String#split(", ")` trailing-empty trimming.
fn write_cached_tag_list_json_array(out: &mut String, cached_tag_list: Option<&str>) {
    out.push('[');
    if let Some(raw) = cached_tag_list {
        if !raw.is_empty() {
            // Ruby's `String#split(", ")` with default limit 0 drops trailing empty fields.
            let mut parts: Vec<&str> = raw.split(", ").collect();
            while parts.last() == Some(&"") {
                parts.pop();
            }
            for (idx, tag) in parts.iter().enumerate() {
                if idx > 0 {
                    out.push(',');
                }
                write_json_string(out, tag, true);
            }
        }
    }
    out.push(']');
}

/// Streams the article notification `json_data` object into `out`.
///
/// Returns `false` if any timestamp is outside the supported UTC millisecond domain.
pub fn write_article_notification_json(
    out: &mut String,
    payload: &ArticleNotificationPayload<'_>,
) -> bool {
    let u = &payload.user;
    let a = &payload.article;

    out.push_str("{\"user\":{\"id\":");
    write_opt_i64(out, u.id);
    out.push_str(",\"class\":{\"name\":\"User\"},\"name\":");
    write_opt_str(out, u.name);
    out.push_str(",\"username\":");
    write_opt_str(out, u.username);
    out.push_str(",\"path\":");
    write_opt_str(out, u.path);
    out.push_str(",\"profile_image_90\":");
    write_opt_str(out, u.profile_image_90);
    out.push_str(",\"comments_count\":");
    write_opt_i64(out, u.comments_count);
    out.push_str(",\"created_at\":");
    if !write_opt_utc_millis(out, u.created_at) {
        return false;
    }

    out.push_str("},\"article\":{\"id\":");
    write_opt_i64(out, a.id);
    out.push_str(",\"cached_tag_list_array\":");
    write_cached_tag_list_json_array(out, a.cached_tag_list);
    out.push_str(",\"class\":{\"name\":\"Article\"},\"title\":");
    write_opt_str(out, a.title);
    out.push_str(",\"path\":");
    write_opt_str(out, a.path);
    out.push_str(",\"updated_at\":");
    if !write_opt_utc_millis(out, a.updated_at) {
        return false;
    }
    out.push_str(",\"published_at\":");
    if !write_opt_utc_millis(out, a.published_at) {
        return false;
    }
    out.push_str(",\"readable_publish_date\":");
    write_opt_str(out, a.readable_publish_date);
    out.push_str(",\"reading_time\":");
    write_opt_i64(out, a.reading_time);
    out.push('}');

    if let Some(org) = &payload.organization {
        out.push_str(",\"organization\":{\"id\":");
        write_opt_i64(out, org.id);
        out.push_str(",\"class\":{\"name\":\"Organization\"},\"name\":");
        write_opt_str(out, org.name);
        out.push_str(",\"slug\":");
        write_opt_str(out, org.slug);
        out.push_str(",\"path\":");
        write_opt_str(out, org.path);
        out.push_str(",\"profile_image_90\":");
        write_opt_str(out, org.profile_image_90);
        out.push('}');
    }

    out.push('}');
    true
}

/// Tier 1 primitive: serializes `{ user: ..., article: ..., organization?: ... }`
/// into a single pre-sized JSON `String` matching `ActiveSupport::JSON.encode`.
pub fn serialize_article_notification_json(
    payload: &ArticleNotificationPayload<'_>,
) -> Option<String> {
    let mut out = String::with_capacity(512);
    if !write_article_notification_json(&mut out, payload) {
        return None;
    }
    Some(out)
}

#[inline]
fn is_ruby_blank(s: &str) -> bool {
    s.chars().all(char::is_whitespace)
}

/// Tier 1 primitive: builds a single-statement PostgreSQL `INSERT INTO "notifications" ...
/// SELECT u_id, ... FROM unnest(ARRAY[...]::bigint[]) AS u_id ON CONFLICT (...) DO UPDATE SET ...`
/// query that embeds `json_data` once instead of repeating it `N` times.
///
/// Strict fast-path domain guards (returning `None` to defer to Ruby):
/// - `user_ids` is empty or contains any ID `<= 0`
/// - `notifiable_id <= 0` or `notifiable_type` is empty
/// - `action` is `Some(s)` where `s` is blank (Ruby treats `""` as blank, while PG treats `'' IS NOT NULL`)
/// - any string contains a NUL (`\0`) byte
/// - `now_sec`/`now_usec` is outside the valid UTC timestamp range
pub fn build_notification_bulk_upsert_sql(params: &NotificationBulkUpsert<'_>) -> Option<String> {
    if params.user_ids.is_empty() || params.notifiable_id <= 0 || params.notifiable_type.is_empty()
    {
        return None;
    }

    if let Some(action_str) = params.action {
        if is_ruby_blank(action_str) {
            return None;
        }
    }

    if let Some(subforem_id) = params.subforem_id {
        if subforem_id < 0 {
            return None;
        }
    }

    // Validate all user_ids up front so we never emit partial SQL on invalid input.
    for &uid in params.user_ids {
        if uid <= 0 {
            return None;
        }
    }

    // Format the shared timestamp once into a tiny stack/small String.
    let mut ts_buf = String::with_capacity(30);
    push_quoted_utc_timestamp(&mut ts_buf, params.now_sec, params.now_usec)?;

    // Estimate capacity: fixed SQL ~480 bytes + json_data + ~11 bytes per user_id.
    let estimated_cap = 512 + params.json_data.len() + params.user_ids.len() * 11;
    let mut out = String::with_capacity(estimated_cap);

    out.push_str(
        "INSERT INTO \"notifications\" (\"user_id\",\"notifiable_id\",\"notifiable_type\",\"subforem_id\",\"action\",\"json_data\",\"created_at\",\"notified_at\",\"updated_at\") SELECT u_id, ",
    );
    let _ = write!(out, "{}, ", params.notifiable_id);
    push_quoted_nullable_sql_str(&mut out, Some(params.notifiable_type))?;
    out.push_str(", ");
    match params.subforem_id {
        Some(sid) => {
            let _ = write!(out, "{sid}");
        }
        None => out.push_str("NULL"),
    }
    out.push_str(", ");
    push_quoted_nullable_sql_str(&mut out, params.action)?;
    out.push_str(", ");
    push_quoted_nullable_sql_str(&mut out, Some(params.json_data))?;
    out.push_str("::jsonb, ");
    out.push_str(&ts_buf);
    out.push_str(", ");
    out.push_str(&ts_buf);
    out.push_str(", ");
    out.push_str(&ts_buf);
    out.push_str(" FROM unnest(ARRAY[");

    // Deduplicate user_ids in first-seen order so PostgreSQL `ON CONFLICT DO UPDATE`
    // can never raise `PG::CardinalityViolation`.
    if params.user_ids.len() == 1 {
        let _ = write!(out, "{}", params.user_ids[0]);
    } else {
        let mut seen: HashSet<i64> = HashSet::with_capacity(params.user_ids.len());
        let mut first = true;
        for &uid in params.user_ids {
            if !seen.insert(uid) {
                continue;
            }
            if !first {
                out.push(',');
            }
            first = false;
            let _ = write!(out, "{uid}");
        }
    }

    if params.action.is_some() {
        out.push_str(
            "]::bigint[]) AS u_id ON CONFLICT (\"user_id\",\"notifiable_id\",\"notifiable_type\",\"action\") WHERE (action IS NOT NULL) DO UPDATE SET \"subforem_id\"=excluded.\"subforem_id\",\"json_data\"=excluded.\"json_data\",\"created_at\"=excluded.\"created_at\",\"notified_at\"=excluded.\"notified_at\",\"updated_at\"=excluded.\"updated_at\"",
        );
    } else {
        out.push_str(
            "]::bigint[]) AS u_id ON CONFLICT (\"user_id\",\"notifiable_id\",\"notifiable_type\") WHERE (action IS NULL) DO UPDATE SET \"subforem_id\"=excluded.\"subforem_id\",\"action\"=excluded.\"action\",\"json_data\"=excluded.\"json_data\",\"created_at\"=excluded.\"created_at\",\"notified_at\"=excluded.\"notified_at\",\"updated_at\"=excluded.\"updated_at\"",
        );
    }

    if params.returning_id {
        out.push_str(" RETURNING \"id\"");
    }

    Some(out)
}

/// Tier 2 fused single-pass kernel: serializes the article notification JSON payload
/// and constructs the complete PostgreSQL `unnest` bulk-upsert SQL in a single FFI call.
#[allow(clippy::too_many_arguments)]
pub fn build_article_notification_bulk_upsert_sql(
    user_ids: &[i64],
    notifiable_type: &str,
    subforem_id: Option<i64>,
    action: Option<&str>,
    payload: &ArticleNotificationPayload<'_>,
    now_sec: i64,
    now_usec: u32,
    returning_id: bool,
) -> Option<String> {
    let notifiable_id = payload.article.id?;
    if user_ids.is_empty() || notifiable_id <= 0 || notifiable_type.is_empty() {
        return None;
    }

    let json_data = serialize_article_notification_json(payload)?;
    build_notification_bulk_upsert_sql(&NotificationBulkUpsert {
        user_ids,
        notifiable_id,
        notifiable_type,
        subforem_id,
        action,
        json_data: &json_data,
        now_sec,
        now_usec,
        returning_id,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_payload() -> ArticleNotificationPayload<'static> {
        ArticleNotificationPayload {
            user: NotificationUserData {
                id: Some(42),
                name: Some("Ada Lovelace"),
                username: Some("ada"),
                path: Some("/ada"),
                profile_image_90: Some("https://cdn.example.com/ada-90.png"),
                comments_count: Some(17),
                created_at: Some((1_700_000_000, 123)),
            },
            article: NotificationArticleData {
                id: Some(9001),
                cached_tag_list: Some("rust, ruby, performance"),
                title: Some("It's <fast> & \"clean\""),
                path: Some("/ada/fast-and-clean"),
                updated_at: Some((1_700_000_500, 45)),
                published_at: Some((1_700_000_400, 0)),
                readable_publish_date: Some("Nov 14"),
                reading_time: Some(5),
            },
            organization: Some(NotificationOrganizationData {
                id: Some(7),
                name: Some("Forem Core"),
                slug: Some("forem"),
                path: Some("/forem"),
                profile_image_90: Some("https://cdn.example.com/forem-90.png"),
            }),
        }
    }

    #[test]
    fn serializes_article_notification_json_with_org() {
        let json = serialize_article_notification_json(&sample_payload()).unwrap();
        assert_eq!(
            json,
            concat!(
                "{\"user\":{\"id\":42,\"class\":{\"name\":\"User\"},\"name\":\"Ada Lovelace\",",
                "\"username\":\"ada\",\"path\":\"/ada\",",
                "\"profile_image_90\":\"https://cdn.example.com/ada-90.png\",",
                "\"comments_count\":17,\"created_at\":\"2023-11-14T22:13:20.123Z\"},",
                "\"article\":{\"id\":9001,\"cached_tag_list_array\":[\"rust\",\"ruby\",\"performance\"],",
                "\"class\":{\"name\":\"Article\"},",
                "\"title\":\"It's \\u003cfast\\u003e \\u0026 \\\"clean\\\"\",",
                "\"path\":\"/ada/fast-and-clean\",",
                "\"updated_at\":\"2023-11-14T22:21:40.045Z\",",
                "\"published_at\":\"2023-11-14T22:20:00.000Z\",",
                "\"readable_publish_date\":\"Nov 14\",\"reading_time\":5},",
                "\"organization\":{\"id\":7,\"class\":{\"name\":\"Organization\"},",
                "\"name\":\"Forem Core\",\"slug\":\"forem\",\"path\":\"/forem\",",
                "\"profile_image_90\":\"https://cdn.example.com/forem-90.png\"}}"
            )
        );
    }

    #[test]
    fn serializes_article_notification_json_without_org_and_edge_tag_lists() {
        let mut p = sample_payload();
        p.organization = None;
        p.article.cached_tag_list = Some(", ruby, ");
        p.article.published_at = None;
        let json = serialize_article_notification_json(&p).unwrap();
        assert!(json.contains("\"cached_tag_list_array\":[\"\",\"ruby\"]"));
        assert!(json.contains("\"published_at\":null"));
        assert!(!json.contains("\"organization\""));
    }

    #[test]
    fn builds_bulk_upsert_sql_with_action_and_deduplicates_user_ids() {
        let sql = build_article_notification_bulk_upsert_sql(
            &[10, 20, 10, 30, 20],
            "Article",
            Some(1),
            Some("Published"),
            &sample_payload(),
            1_700_000_600,
            654_321,
            false,
        )
        .unwrap();

        assert!(sql.starts_with(
            "INSERT INTO \"notifications\" (\"user_id\",\"notifiable_id\",\"notifiable_type\",\"subforem_id\",\"action\",\"json_data\",\"created_at\",\"notified_at\",\"updated_at\") SELECT u_id, 9001, 'Article', 1, 'Published', '{"
        ));
        assert!(sql.contains("It''s \\u003cfast\\u003e"));
        assert!(sql.contains("::jsonb, '2023-11-14 22:23:20.654321', '2023-11-14 22:23:20.654321', '2023-11-14 22:23:20.654321' FROM unnest(ARRAY[10,20,30]::bigint[]) AS u_id ON CONFLICT (\"user_id\",\"notifiable_id\",\"notifiable_type\",\"action\") WHERE (action IS NOT NULL) DO UPDATE SET"));
        assert!(!sql.ends_with("RETURNING \"id\""));
    }

    #[test]
    fn builds_bulk_upsert_sql_with_null_action_and_returning() {
        let sql = build_notification_bulk_upsert_sql(&NotificationBulkUpsert {
            user_ids: &[5],
            notifiable_id: 99,
            notifiable_type: "Article",
            subforem_id: None,
            action: None,
            json_data: "{\"ok\":true}",
            now_sec: 1_700_000_000,
            now_usec: 0,
            returning_id: true,
        })
        .unwrap();

        assert!(sql.contains(
            "SELECT u_id, 99, 'Article', NULL, NULL, '{\"ok\":true}'::jsonb, '2023-11-14 22:13:20'"
        ));
        assert!(sql.contains("FROM unnest(ARRAY[5]::bigint[]) AS u_id ON CONFLICT (\"user_id\",\"notifiable_id\",\"notifiable_type\") WHERE (action IS NULL) DO UPDATE SET \"subforem_id\"=excluded.\"subforem_id\",\"action\"=excluded.\"action\","));
        assert!(sql.ends_with(" RETURNING \"id\""));
    }

    #[test]
    fn returns_none_for_out_of_domain_inputs() {
        let p = sample_payload();
        // Empty user_ids
        assert!(build_article_notification_bulk_upsert_sql(
            &[],
            "Article",
            Some(1),
            Some("Published"),
            &p,
            1_700_000_000,
            0,
            false,
        )
        .is_none());
        // Non-positive user_id
        assert!(build_article_notification_bulk_upsert_sql(
            &[1, 0],
            "Article",
            Some(1),
            Some("Published"),
            &p,
            1_700_000_000,
            0,
            false,
        )
        .is_none());
        // Blank action string (ASCII and Unicode whitespace)
        for blank in ["", "   ", "\u{00A0}", "\u{3000}", "\t\u{00A0}\n"] {
            assert!(build_article_notification_bulk_upsert_sql(
                &[1],
                "Article",
                Some(1),
                Some(blank),
                &p,
                1_700_000_000,
                0,
                false,
            )
            .is_none());
        }
        // NUL byte in json_data
        assert!(build_notification_bulk_upsert_sql(&NotificationBulkUpsert {
            user_ids: &[1],
            notifiable_id: 99,
            notifiable_type: "Article",
            subforem_id: None,
            action: Some("Published"),
            json_data: "{\"bad\":\"\0\"}",
            now_sec: 1_700_000_000,
            now_usec: 0,
            returning_id: false,
        })
        .is_none());
    }
}
