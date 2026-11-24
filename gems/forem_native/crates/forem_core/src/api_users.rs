//! Single-pass streaming JSON serializers for the Forem Users & Organizations APIs
//! (`Api::V0::UsersController`, `Api::V1::UsersController`,
//! `Api::V0::OrganizationsController`, and `Api::V1::OrganizationsController`).
//!
//! Replaces `Profile.instantiate` / `Users::Setting.instantiate` ActiveRecord churn,
//! `Api::OrganizationsController#users` N+1 profile lookups, `I18n.l(..., format: :json)`,
//! and ActionView/Jbuilder partial rendering with single-pass Rust streaming serializers:
//!
//! - **Tier 1 composable primitives**:
//!   - [`format_joined_at_date`] / [`write_joined_at_date`]: zero-allocation UTC English
//!     date formatter matching `I18n.l(time, format: :json)` (`"%b %e, %Y"`, e.g.
//!     `"Jan  5, 2026"` / `"Nov 24, 2026"`).
//! - **Tier 2 single-pass pipeline kernels**:
//!   - [`serialize_api_user_json`]: streams a single user JSON object for
//!     `GET /api/users/:id`, `GET /api/users/by_username`, `GET /api/users/me`,
//!     and `GET /api/users/search` (both v0 basic and v1 extended/me schemas).
//!   - [`serialize_api_users_json`]: streams a JSON array of basic user objects for
//!     `GET /api/organizations/:id_or_slug/users` in a single FFI call.
//!   - [`serialize_api_organization_json`]: streams a single organization JSON object for
//!     `GET /api/organizations/:id_or_slug` (v0 and v1).

use std::fmt::Write;

use crate::api_comments::{civil_from_days, write_utc_iso8601};
use crate::json::write_json_string;

const SHORT_MONTHS: [&str; 12] = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

/// Flat representation of a user row for `/api/users/*` and `/api/organizations/:id/users`.
#[derive(Debug, Clone, Copy)]
pub struct ApiUserRow<'a> {
    pub id: i64,
    pub username: Option<&'a str>,
    pub name: Option<&'a str>,
    pub twitter_username: Option<&'a str>,
    pub github_username: Option<&'a str>,
    pub summary: Option<&'a str>,
    pub location: Option<&'a str>,
    pub website_url: Option<&'a str>,
    /// UTC epoch seconds (`Time#tv_sec`).
    pub created_at_sec: i64,
    pub profile_image: Option<&'a str>,
}

/// Flat representation of an organization row for `/api/organizations/:id_or_slug`.
#[derive(Debug, Clone, Copy)]
pub struct ApiOrganizationRow<'a> {
    pub id: i64,
    pub username: Option<&'a str>,
    pub name: Option<&'a str>,
    pub summary: Option<&'a str>,
    pub twitter_username: Option<&'a str>,
    pub github_username: Option<&'a str>,
    pub url: Option<&'a str>,
    pub location: Option<&'a str>,
    pub tech_stack: Option<&'a str>,
    pub tag_line: Option<&'a str>,
    pub story: Option<&'a str>,
    /// UTC epoch seconds (`Time#tv_sec`), or `None` when `created_at` is `nil`.
    pub created_at_sec: Option<i64>,
    pub profile_image: Option<&'a str>,
}

/// Writes `epoch_secs` formatted in UTC as `"%b %e, %Y"` (e.g. `"Jan  5, 2026"` or
/// `"Nov 24, 2026"`) directly into `out`, matching `I18n.l(time, format: :json)` in `:en`.
///
/// Returns `false` if the year falls outside `1000..=9999` (deferring cleanly to Ruby).
#[inline]
pub fn write_joined_at_date(out: &mut String, epoch_secs: i64) -> bool {
    let days = epoch_secs.div_euclid(86_400);
    let (year, month, day) = civil_from_days(days);
    if !(1000..=9999).contains(&year) || !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return false;
    }

    let y = year as u32;
    let mon = SHORT_MONTHS[(month - 1) as usize].as_bytes();
    let d1 = if day < 10 {
        b' '
    } else {
        b'0' + (day / 10) as u8
    };
    let d2 = b'0' + (day % 10) as u8;

    let buf: [u8; 12] = [
        mon[0],
        mon[1],
        mon[2],
        b' ',
        d1,
        d2,
        b',',
        b' ',
        b'0' + (y / 1000) as u8,
        b'0' + ((y / 100) % 10) as u8,
        b'0' + ((y / 10) % 10) as u8,
        b'0' + (y % 10) as u8,
    ];

    // SAFETY: `buf` contains only ASCII letters, spaces, comma, and digits.
    let s = unsafe { std::str::from_utf8_unchecked(&buf) };
    out.push_str(s);
    true
}

/// Formats UTC `epoch_secs` as `"%b %e, %Y"` (matching English `I18n.l(time, format: :json)`).
/// Returns `None` if the resulting year is outside `1000..=9999`.
pub fn format_joined_at_date(epoch_secs: i64) -> Option<String> {
    let mut out = String::with_capacity(12);
    write_joined_at_date(&mut out, epoch_secs).then_some(out)
}

#[inline]
fn write_opt_str(out: &mut String, value: Option<&str>) {
    match value {
        Some(s) => write_json_string(out, s, true),
        None => out.push_str("null"),
    }
}

/// Streams a single user JSON object directly into `out`.
///
/// Key order matches `api/v0/shared/_user_show.json.jbuilder` (when `extended == false`),
/// `api/v1/shared/_user_show_extended.json.jbuilder` (when `extended == true`), and
/// `api/v1/users/me.json.jbuilder` (when `followers_count.is_some()`).
pub fn write_api_user_object(
    out: &mut String,
    user: &ApiUserRow<'_>,
    extended: bool,
    email: Option<&str>,
    badge_ids: &[i64],
    followers_count: Option<i64>,
) -> bool {
    out.push_str("{\"type_of\":\"user\",\"id\":");
    let _ = write!(out, "{}", user.id);

    out.push_str(",\"username\":");
    write_opt_str(out, user.username);

    out.push_str(",\"name\":");
    write_opt_str(out, user.name);

    out.push_str(",\"twitter_username\":");
    write_opt_str(out, user.twitter_username);

    out.push_str(",\"github_username\":");
    write_opt_str(out, user.github_username);

    if extended {
        out.push_str(",\"email\":");
        write_opt_str(out, email);
    }

    out.push_str(",\"summary\":");
    write_opt_str(out, user.summary);

    out.push_str(",\"location\":");
    write_opt_str(out, user.location);

    out.push_str(",\"website_url\":");
    write_opt_str(out, user.website_url);

    out.push_str(",\"joined_at\":\"");
    if !write_joined_at_date(out, user.created_at_sec) {
        return false;
    }
    out.push('"');

    out.push_str(",\"profile_image\":");
    write_opt_str(out, user.profile_image);

    if extended {
        out.push_str(",\"badge_ids\":[");
        for (idx, badge_id) in badge_ids.iter().enumerate() {
            if idx > 0 {
                out.push(',');
            }
            let _ = write!(out, "{badge_id}");
        }
        out.push(']');
    }

    if let Some(count) = followers_count {
        out.push_str(",\"followers_count\":");
        let _ = write!(out, "{count}");
    }

    out.push('}');
    true
}

#[inline]
fn estimate_user_capacity(user: &ApiUserRow<'_>, extended: bool, badge_count: usize) -> usize {
    let str_len = user.username.map_or(0, str::len)
        + user.name.map_or(0, str::len)
        + user.twitter_username.map_or(0, str::len)
        + user.github_username.map_or(0, str::len)
        + user.summary.map_or(0, str::len)
        + user.location.map_or(0, str::len)
        + user.website_url.map_or(0, str::len)
        + user.profile_image.map_or(0, str::len);
    240 + str_len + if extended { 48 + badge_count * 6 } else { 0 }
}

/// Single-pass streaming JSON serializer for a single user (`GET /api/users/:id`,
/// `GET /api/users/by_username`, `GET /api/users/me`, `GET /api/users/search`).
pub fn serialize_api_user_json(
    user: &ApiUserRow<'_>,
    extended: bool,
    email: Option<&str>,
    badge_ids: &[i64],
    followers_count: Option<i64>,
) -> Option<String> {
    let cap = estimate_user_capacity(user, extended, badge_ids.len())
        + email.map_or(0, str::len)
        + if followers_count.is_some() { 24 } else { 0 };
    let mut out = String::with_capacity(cap);
    write_api_user_object(&mut out, user, extended, email, badge_ids, followers_count)
        .then_some(out)
}

/// Single-pass streaming JSON serializer for a list of basic user objects
/// (`GET /api/organizations/:id_or_slug/users`).
pub fn serialize_api_users_json(users: &[ApiUserRow<'_>]) -> Option<String> {
    if users.is_empty() {
        return Some("[]".to_string());
    }

    let cap: usize = 2 + users
        .iter()
        .map(|u| estimate_user_capacity(u, false, 0) + 1)
        .sum::<usize>();
    let mut out = String::with_capacity(cap);
    out.push('[');
    for (idx, user) in users.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        if !write_api_user_object(&mut out, user, false, None, &[], None) {
            return None;
        }
    }
    out.push(']');
    Some(out)
}

/// Single-pass streaming JSON serializer for `GET /api/organizations/:id_or_slug` (v0 & v1).
///
/// Key order matches `api/v0/organizations/show.json.jbuilder` and
/// `api/v1/organizations/show.json.jbuilder`.
pub fn serialize_api_organization_json(org: &ApiOrganizationRow<'_>) -> Option<String> {
    let str_len = org.username.map_or(0, str::len)
        + org.name.map_or(0, str::len)
        + org.summary.map_or(0, str::len)
        + org.twitter_username.map_or(0, str::len)
        + org.github_username.map_or(0, str::len)
        + org.url.map_or(0, str::len)
        + org.location.map_or(0, str::len)
        + org.tech_stack.map_or(0, str::len)
        + org.tag_line.map_or(0, str::len)
        + org.story.map_or(0, str::len)
        + org.profile_image.map_or(0, str::len);
    let mut out = String::with_capacity(280 + str_len);

    out.push_str("{\"type_of\":\"organization\",\"id\":");
    let _ = write!(out, "{}", org.id);

    out.push_str(",\"username\":");
    write_opt_str(&mut out, org.username);

    out.push_str(",\"name\":");
    write_opt_str(&mut out, org.name);

    out.push_str(",\"summary\":");
    write_opt_str(&mut out, org.summary);

    out.push_str(",\"twitter_username\":");
    write_opt_str(&mut out, org.twitter_username);

    out.push_str(",\"github_username\":");
    write_opt_str(&mut out, org.github_username);

    out.push_str(",\"url\":");
    write_opt_str(&mut out, org.url);

    out.push_str(",\"location\":");
    write_opt_str(&mut out, org.location);

    out.push_str(",\"tech_stack\":");
    write_opt_str(&mut out, org.tech_stack);

    out.push_str(",\"tag_line\":");
    write_opt_str(&mut out, org.tag_line);

    out.push_str(",\"story\":");
    write_opt_str(&mut out, org.story);

    out.push_str(",\"joined_at\":");
    match org.created_at_sec {
        Some(secs) => {
            out.push('"');
            if !write_utc_iso8601(&mut out, secs) {
                return None;
            }
            out.push('"');
        }
        None => out.push_str("null"),
    }

    out.push_str(",\"profile_image\":");
    write_opt_str(&mut out, org.profile_image);

    out.push('}');
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_joined_at_date_single_and_double_digit_days() {
        // 1970-01-01 00:00:00 UTC -> "Jan  1, 1970"
        assert_eq!(format_joined_at_date(0).as_deref(), Some("Jan  1, 1970"));
        // 1969-12-31 23:59:59 UTC -> "Dec 31, 1969"
        assert_eq!(format_joined_at_date(-1).as_deref(), Some("Dec 31, 1969"));
        // 2024-02-29 12:00:00 UTC (leap day) -> "Feb 29, 2024"
        assert_eq!(
            format_joined_at_date(1_709_208_000).as_deref(),
            Some("Feb 29, 2024")
        );
        // 2026-01-05 08:30:00 UTC -> "Jan  5, 2026"
        assert_eq!(
            format_joined_at_date(1_767_601_800).as_deref(),
            Some("Jan  5, 2026")
        );
        // 2026-11-24 19:00:00 UTC -> "Nov 24, 2026"
        assert_eq!(
            format_joined_at_date(1_795_546_800).as_deref(),
            Some("Nov 24, 2026")
        );
    }

    #[test]
    fn rejects_out_of_range_years_for_joined_at_date() {
        // Year 999
        assert_eq!(format_joined_at_date(-30_610_224_001), None);
        // Year 10000
        assert_eq!(format_joined_at_date(253_402_300_800), None);
    }

    #[test]
    fn serializes_basic_v0_user_json() {
        let user = ApiUserRow {
            id: 42,
            username: Some("ada"),
            name: Some("Ada <Lovelace> & Co."),
            twitter_username: Some("ada_dev"),
            github_username: None,
            summary: Some("Line 1\nLine 2 🚀"),
            location: Some("London"),
            website_url: Some("https://ada.example.com"),
            created_at_sec: 1_767_601_800,
            profile_image: Some("https://cdn.example.com/ada.png"),
        };

        let json = serialize_api_user_json(&user, false, None, &[], None).unwrap();
        assert_eq!(
            json,
            concat!(
                r#"{"type_of":"user","id":42,"username":"ada","#,
                r#""name":"Ada \u003cLovelace\u003e \u0026 Co.","#,
                r#""twitter_username":"ada_dev","github_username":null,"#,
                r#""summary":"Line 1\nLine 2 🚀","location":"London","#,
                r#""website_url":"https://ada.example.com","#,
                r#""joined_at":"Jan  5, 2026","#,
                r#""profile_image":"https://cdn.example.com/ada.png"}"#
            )
        );
    }

    #[test]
    fn serializes_extended_v1_user_and_me_json() {
        let user = ApiUserRow {
            id: 7,
            username: Some("grace"),
            name: Some("Grace Hopper"),
            twitter_username: None,
            github_username: Some("ghopper"),
            summary: None,
            location: None,
            website_url: None,
            created_at_sec: 1_795_546_800,
            profile_image: Some("https://cdn.example.com/grace.png"),
        };

        let show_json =
            serialize_api_user_json(&user, true, Some("grace@example.com"), &[1, 9, 42], None)
                .unwrap();
        assert_eq!(
            show_json,
            concat!(
                r#"{"type_of":"user","id":7,"username":"grace","name":"Grace Hopper","#,
                r#""twitter_username":null,"github_username":"ghopper","#,
                r#""email":"grace@example.com","summary":null,"location":null,"#,
                r#""website_url":null,"joined_at":"Nov 24, 2026","#,
                r#""profile_image":"https://cdn.example.com/grace.png","#,
                r#""badge_ids":[1,9,42]}"#
            )
        );

        let me_json = serialize_api_user_json(&user, true, None, &[], Some(128)).unwrap();
        assert_eq!(
            me_json,
            concat!(
                r#"{"type_of":"user","id":7,"username":"grace","name":"Grace Hopper","#,
                r#""twitter_username":null,"github_username":"ghopper","#,
                r#""email":null,"summary":null,"location":null,"#,
                r#""website_url":null,"joined_at":"Nov 24, 2026","#,
                r#""profile_image":"https://cdn.example.com/grace.png","#,
                r#""badge_ids":[],"followers_count":128}"#
            )
        );
    }

    #[test]
    fn serializes_users_array_including_empty() {
        assert_eq!(serialize_api_users_json(&[]).as_deref(), Some("[]"));

        let rows = [
            ApiUserRow {
                id: 1,
                username: Some("u1"),
                name: Some("User One"),
                twitter_username: None,
                github_username: None,
                summary: Some("Bio 1"),
                location: None,
                website_url: None,
                created_at_sec: 0,
                profile_image: Some("https://example.com/1.png"),
            },
            ApiUserRow {
                id: 2,
                username: Some("u2"),
                name: Some("User Two"),
                twitter_username: Some("u2tw"),
                github_username: Some("u2gh"),
                summary: None,
                location: Some("NYC"),
                website_url: Some("https://u2.dev"),
                created_at_sec: 1_709_208_000,
                profile_image: Some("https://example.com/2.png"),
            },
        ];

        let json = serialize_api_users_json(&rows).unwrap();
        assert!(json.starts_with(r#"[{"type_of":"user","id":1,"#));
        assert!(json.contains(r#""joined_at":"Jan  1, 1970""#));
        assert!(json.contains(r#",{"type_of":"user","id":2,"#));
        assert!(json.contains(r#""joined_at":"Feb 29, 2024""#));
        assert!(json.ends_with("}]"));
    }

    #[test]
    fn serializes_organization_json_with_and_without_created_at() {
        let org = ApiOrganizationRow {
            id: 10,
            username: Some("forem"),
            name: Some("Forem & Friends"),
            summary: Some("Open source <community>"),
            twitter_username: Some("forem"),
            github_username: Some("forem"),
            url: Some("https://forem.com"),
            location: Some("Remote"),
            tech_stack: Some("Ruby, Rust"),
            tag_line: Some("Where communities thrive"),
            story: Some("Started in 2016"),
            created_at_sec: Some(1_795_546_800),
            profile_image: Some("https://cdn.example.com/forem.png"),
        };

        let json = serialize_api_organization_json(&org).unwrap();
        assert_eq!(
            json,
            concat!(
                r#"{"type_of":"organization","id":10,"username":"forem","#,
                r#""name":"Forem \u0026 Friends","summary":"Open source \u003ccommunity\u003e","#,
                r#""twitter_username":"forem","github_username":"forem","#,
                r#""url":"https://forem.com","location":"Remote","#,
                r#""tech_stack":"Ruby, Rust","tag_line":"Where communities thrive","#,
                r#""story":"Started in 2016","joined_at":"2026-11-24T19:00:00Z","#,
                r#""profile_image":"https://cdn.example.com/forem.png"}"#
            )
        );

        let org_nil_time = ApiOrganizationRow {
            created_at_sec: None,
            ..org
        };
        let json_nil = serialize_api_organization_json(&org_nil_time).unwrap();
        assert!(json_nil.contains(r#""joined_at":null"#));
    }
}
