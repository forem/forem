//! Native Comment-Tree HTML renderer for `CommentsHelper#nested_comments` and its partial hierarchy:
//! - `app/views/comments/_comment.html.erb`
//! - `app/views/comments/_comment_avatar.html.erb`
//! - `app/views/comments/_comment_proper.html.erb`
//! - `app/views/comments/_comment_quality_marker.html.erb`
//! - `app/views/comments/_comment_header.html.erb`
//! - `app/views/comments/_comment_date.erb`
//! - `app/views/comments/_comment_footer.html.erb`
//! - `app/views/shared/_profile_preview_card.html.erb`
//! - `app/views/shared/_profile_card_content.html.erb`
//!
//! This module has **zero** Ruby or `magnus` dependencies so it can be unit-tested standalone
//! with `cargo test -p forem_core` and reused across targets.

use crate::feed::civil_from_days;

/// `Comment::LOW_QUALITY_THRESHOLD`.
pub const LOW_QUALITY_THRESHOLD: i64 = -75;
/// `Comment::HIDE_THRESHOLD`.
pub const HIDE_THRESHOLD: i64 = -400;

/// Placeholder sentinel used in pre-fetched I18n user templates.
pub const USER_PLACEHOLDER: &str = "__FOREM_USER__";
/// Placeholder sentinel used in `views.comments.edited.text_html`.
pub const DATE_PLACEHOLDER: &str = "__FOREM_DATE__";
/// Placeholder sentinels used in `views.comments.footer.heart.count_html`.
pub const NUM_PLACEHOLDER: &str = "__FOREM_NUM__";
pub const LIKES_PLACEHOLDER: &str = "__FOREM_LIKES__";
/// Placeholder sentinel used in `helpers.comments_helper.nbsp_likes_html`.
pub const COUNT_PLACEHOLDER: &str = "__FOREM_COUNT__";

/// `PodcastTag::SCRIPT` embedded when `comment.processed_html` contains `"podcastliquidtag"`.
pub const PODCAST_TAG_SCRIPT: &str = "\
var waitingOnPodcast = setInterval(function() {
  if (typeof initializePodcastPlayback !== 'undefined') {
    initializePodcastPlayback();
    clearInterval(waitingOnPodcast);
  }
}, 1);\n";

/// `TweetTag::SCRIPT` embedded when `comment.processed_html` contains `"tweet-embed"`.
pub const TWEET_TAG_SCRIPT: &str = "  // Listen for resize events and match them to the iframe
  window.addEventListener('message', function(event) {
    if (event.origin.startsWith('https://platform.twitter.com')) {
        var iframes = document.getElementsByTagName('iframe');
        for (var i = 0; i < iframes.length; i++) {
          if (event.source === iframes[i].contentWindow) { // iframes which match the event
            var iframe = iframes[i];
            var data = event.data['twttr.embed'];
            if (data && data['method'] === 'twttr.private.resize' && data['params'] && data['params']['0']) {
              iframe.style.height = data['params']['0']['height'] + 0.5 + 'px';
              iframe.style.minHeight = data['params']['0']['height'] + 0.5 + 'px';
              iframe.style.width = data['params']['0']['width'] + 'px !important';
            }
            break;
          }
        }
    }
}, false);

// Legacy support: We have shifted up how we render tweets, but still need to render
// the old way for old embed. This could eventually be removed.
var videoPreviews = document.getElementsByClassName(\"ltag__twitter-tweet__media__video-wrapper\");
[].forEach.call(videoPreviews, function(el) {
  el.onclick = function(e) {
    var divHeight = el.offsetHeight;
    el.style.maxHeight = divHeight + \"px\";
    el.getElementsByClassName(\"ltag__twitter-tweet__media--video-preview\")[0].style.display = \"none\";
    el.getElementsByClassName(\"ltag__twitter-tweet__video\")[0].style.display = \"block\";
    el.getElementsByTagName(\"video\")[0].play();
  }
});
var tweets = document.getElementsByClassName(\"ltag__twitter-tweet__main\");
[].forEach.call(tweets, function(tweet){
  tweet.onclick = function(e) {
    if (e.target.nodeName == \"A\" || e.target.parentElement.nodeName == \"A\") {
      return;
    }
    window.open(tweet.dataset.url,\"_blank\");
  }
});\n";

const ENGLISH_ABBR_MONTHS: [&str; 12] = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

const BASE26_DIGITS: &[u8; 26] = b"0123456789abcdefghijklmnop";

/// Static locale strings, pre-rendered icons, and feature-flag fragments shared across the
/// comment tree render.
#[derive(Debug, Clone)]
pub struct CommentStaticContext<'a> {
    pub icon_collapse: &'a str,
    pub icon_expand: &'a str,
    pub icon_info: &'a str,
    pub icon_small_medal: &'a str,
    pub icon_small_overflow_horizontal: &'a str,
    pub icon_small_heart: &'a str,
    pub icon_small_heart_filled: &'a str,
    pub icon_small_comment: &'a str,
    pub icon_small_thread: &'a str,
    pub subscription_icon_html: &'a str,
    pub subscription_icon_no_link_html: &'a str,
    pub community_leader_icon_html: &'a str,
    pub favorites_enabled: bool,
    pub favorite_static_data_attrs: &'a str,
    pub favorite_favorited_inner_html: &'a str,
    pub t_comment_deleted: &'a str,
    pub t_comment_hidden: &'a str,
    pub t_quality_low: &'a str,
    pub t_quality_conduct: &'a str,
    pub t_quality_superlow: &'a str,
    pub t_quality_hidden_visible: &'a str,
    pub t_quality_hidden_accessible: &'a str,
    pub t_users_details_template: &'a str,
    pub t_edited_text_html_template: &'a str,
    pub t_edited_short_html: &'a str,
    pub t_ai_some_description: &'a str,
    pub t_ai_some_label: &'a str,
    pub t_ai_auto_description: &'a str,
    pub t_ai_auto_label: &'a str,
    pub t_menu_aria_label: &'a str,
    pub t_menu_copy_aria_template: &'a str,
    pub t_menu_copy_text: &'a str,
    pub t_menu_settings_aria_template: &'a str,
    pub t_menu_unhide_aria_template: &'a str,
    pub t_menu_unhide_text: &'a str,
    pub t_menu_hide_aria_template: &'a str,
    pub t_menu_hide_text: &'a str,
    pub t_menu_admin_profile_text: &'a str,
    pub t_menu_admin_profile_aria_template: &'a str,
    pub t_menu_moderate_aria_template: &'a str,
    pub t_menu_report_aria_template: &'a str,
    pub t_heart_aria_label: &'a str,
    pub t_heart_count_html_template: &'a str,
    pub t_nbsp_likes_one_template: &'a str,
    pub t_nbsp_likes_other_template: &'a str,
    pub t_heart_title: &'a str,
    pub t_reply_text: &'a str,
    pub t_thread_text: &'a str,
    pub t_follow_user_text: &'a str,
    pub t_follow_user_aria_template: &'a str,
    pub t_sticky_email: &'a str,
    pub t_sticky_location: &'a str,
    pub t_sticky_joined: &'a str,
    pub time_format_short: &'a str,
    pub time_format_short_with_yy: &'a str,
    pub time_format_short_with_year: &'a str,
    pub abbr_month_names: [&'a str; 12],
    pub prior_cloudflare_domain: Option<&'a str>,
    pub current_cloudflare_domain: Option<&'a str>,
}

/// Per-invocation view state and commentable metadata for `CommentsHelper#nested_comments`.
#[derive(Debug, Clone)]
pub struct CommentViewContext<'a> {
    pub has_commentable: bool,
    pub commentable_path: &'a str,
    pub commentable_user_id_str: &'a str,
    pub ama_or_op_banner: &'a str,
    pub app_base_url: &'a str,
    pub comment_base_url: &'a str,
    pub contextual_use_permalink: bool,
    pub article_path: Option<&'a str>,
    pub mascot_image_tag_html: &'a str,
    pub billboard_async_url: &'a str,
    pub has_root_comment: bool,
    pub root_comment_hidden: bool,
    pub discussion_lock: bool,
    pub is_admin: bool,
    pub is_view_root: bool,
    pub current_year: i32,
    pub current_comment_index: Option<i64>,
    pub shown_billboard: bool,
}

/// Distinct comment author (`comment.user`) metadata within a comment tree.
#[derive(Debug, Clone)]
pub struct CommentAuthorInput<'a> {
    pub user_id: i64,
    pub name: &'a str,
    pub username: &'a str,
    pub user_url: &'a str,
    pub profile_image_50: &'a str,
    pub profile_image_90: &'a str,
    pub org_name: Option<&'a str>,
    pub is_op: bool,
    pub by_staff_account: bool,
    pub is_subscriber: bool,
    pub is_community_leader: bool,
    pub smallest_color_hex: &'a str,
    pub card_color_fallback: Option<&'a str>,
    pub tag_line: Option<&'a str>,
    pub displayed_email: Option<&'a str>,
    pub location: Option<&'a str>,
    pub header_fields: Vec<(&'a str, &'a str)>,
    pub created_at: Option<(i64, i64)>,
}

/// Single comment node in pre-order DFS sequence.
#[derive(Debug, Clone)]
pub struct CommentNodeInput<'a> {
    pub id: i64,
    pub author_idx: usize,
    pub depth: usize,
    pub is_root: bool,
    pub score: i64,
    pub deleted: bool,
    pub hidden_by_commentable_user: bool,
    pub is_root_comment: bool,
    pub public_reactions_count: i64,
    pub favorited_by_user_id: Option<i64>,
    pub id_code: &'a str,
    pub processed_html: &'a str,
    /// `0 = not_disclosed`, `1 = no_ai`, `3 = some_ai`, `5 = fully_autonomous`.
    pub ai_disclosure_level: u8,
    pub created_at: Option<(i64, i64)>,
    pub edited_at: Option<(i64, i64)>,
    pub child_count: usize,
}

/// Output of `render_comment_tree`, including updated view state variables.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommentTreeOutput {
    pub html: String,
    pub current_comment_index: Option<i64>,
    pub shown_billboard: bool,
}

/// Pre-rendered per-author fragments reused across all comments by the same author.
struct PreparedAuthor {
    user_id_str: String,
    admin_user_path: String,
    escaped_name: String,
    escaped_username: String,
    escaped_user_url: String,
    escaped_profile_image_50: String,
    escaped_org_badge_html: String,
    escaped_details_aria_label: String,
    escaped_copy_aria_label: String,
    escaped_settings_aria_label: String,
    escaped_unhide_aria_label: String,
    escaped_hide_aria_label: String,
    escaped_admin_profile_aria_label: String,
    escaped_moderate_aria_label: String,
    escaped_report_aria_label: String,
    profile_card_tail_html: String,
}

struct MutableRenderState {
    current_comment_index: Option<i64>,
    shown_billboard: bool,
}

/// Appends `s` to `out` with `ERB::Util.html_escape` / `CGI.escapeHTML` rules (`&`, `<`, `>`, `"`, `'`).
#[inline]
pub fn push_html_escaped(out: &mut String, s: &str) {
    let bytes = s.as_bytes();
    let mut start = 0;
    for (i, &b) in bytes.iter().enumerate() {
        let replacement = match b {
            b'&' => "&amp;",
            b'<' => "&lt;",
            b'>' => "&gt;",
            b'"' => "&quot;",
            b'\'' => "&#39;",
            _ => continue,
        };
        if start < i {
            out.push_str(&s[start..i]);
        }
        out.push_str(replacement);
        start = i + 1;
    }
    if start < bytes.len() {
        out.push_str(&s[start..]);
    }
}

#[inline]
fn html_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 8);
    push_html_escaped(&mut out, s);
    out
}

#[inline]
fn escape_template_with_user(template: &str, escaped_user_name: &str) -> String {
    let mut out = String::with_capacity(template.len() + escaped_user_name.len());
    let mut rest = template;
    while let Some(pos) = rest.find(USER_PLACEHOLDER) {
        push_html_escaped(&mut out, &rest[..pos]);
        out.push_str(escaped_user_name);
        rest = &rest[pos + USER_PLACEHOLDER.len()..];
    }
    push_html_escaped(&mut out, rest);
    out
}

/// Formats `id` in base-26 matching Ruby's `Integer#to_s(26)` (`Comment#id_code_generated`).
#[inline]
pub fn format_id_code_base26(id: i64, buf: &mut [u8; 20]) -> &str {
    if id == 0 {
        buf[19] = b'0';
        return std::str::from_utf8(&buf[19..20]).unwrap();
    }
    let negative = id < 0;
    let mut n: u64 = id.unsigned_abs();
    let mut pos = 20;
    while n > 0 {
        pos -= 1;
        buf[pos] = BASE26_DIGITS[(n % 26) as usize];
        n /= 26;
    }
    if negative {
        pos -= 1;
        buf[pos] = b'-';
    }
    std::str::from_utf8(&buf[pos..20]).unwrap()
}

/// Computes `(depth, is_root)` from an Ancestry path string (`nil` -> `(0, true)`, `"1"` -> `(1, false)`, `"1/2"` -> `(2, false)`).
#[inline]
pub fn depth_and_root_from_ancestry(ancestry: Option<&str>) -> (usize, bool) {
    match ancestry {
        None => (0, true),
        Some("") => (0, false),
        Some(s) => {
            let slashes = s.bytes().filter(|&b| b == b'/').count();
            (slashes + 1, false)
        }
    }
}

#[inline]
fn push_two_digits(out: &mut String, value: u32) {
    out.push(char::from(b'0' + (value / 10) as u8));
    out.push(char::from(b'0' + (value % 10) as u8));
}

#[inline]
fn push_four_digits(out: &mut String, value: u32) {
    out.push(char::from(b'0' + ((value / 1000) % 10) as u8));
    out.push(char::from(b'0' + ((value / 100) % 10) as u8));
    out.push(char::from(b'0' + ((value / 10) % 10) as u8));
    out.push(char::from(b'0' + (value % 10) as u8));
}

#[inline]
fn push_u32_decimal(out: &mut String, mut value: u32) {
    if value >= 10 {
        let mut buf = [0u8; 10];
        let mut pos = 10;
        while value > 0 {
            pos -= 1;
            buf[pos] = b'0' + (value % 10) as u8;
            value /= 10;
        }
        out.push_str(std::str::from_utf8(&buf[pos..10]).unwrap());
    } else {
        out.push(char::from(b'0' + value as u8));
    }
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

/// Appends `Time#utc.iso8601` (`YYYY-MM-DDTHH:MM:SSZ`) for years `0..=9999`.
#[inline]
pub fn push_utc_iso8601(out: &mut String, epoch_secs: i64) -> Option<()> {
    let days = epoch_secs.div_euclid(86_400);
    let secs_of_day = epoch_secs.rem_euclid(86_400) as u32;
    let (year, month, day) = civil_from_days(days);
    if !(0..=9999).contains(&year) {
        return None;
    }
    let hour = secs_of_day / 3600;
    let minute = (secs_of_day % 3600) / 60;
    let second = secs_of_day % 60;

    push_four_digits(out, year as u32);
    out.push('-');
    push_two_digits(out, month);
    out.push('-');
    push_two_digits(out, day);
    out.push('T');
    push_two_digits(out, hour);
    out.push(':');
    push_two_digits(out, minute);
    out.push(':');
    push_two_digits(out, second);
    out.push('Z');
    Some(())
}

/// Returns `(year, month, day)` in the timestamp's local time zone (`epoch_secs + utc_offset_secs`).
#[inline]
pub fn local_civil_date(epoch_secs: i64, utc_offset_secs: i64) -> Option<(i32, u32, u32)> {
    let local_secs = epoch_secs.checked_add(utc_offset_secs)?;
    let days = local_secs.div_euclid(86_400);
    let (year, month, day) = civil_from_days(days);
    if !(0..=9999).contains(&year) || !(1..=12).contains(&month) {
        return None;
    }
    Some((year, month, day))
}

/// Formats `(year, month, day)` according to a `strftime` date pattern (`%b`, `%d`, `%-d`,
/// `%e`, `%-e`, `%y`, `%Y`, `%%`). Returns `None` if the pattern contains any other directive.
pub fn format_strftime_date(
    pattern: &str,
    year: i32,
    month: u32,
    day: u32,
    abbr_months: &[&str; 12],
) -> Option<String> {
    if !(0..=9999).contains(&year) || !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }
    let mut out = String::with_capacity(pattern.len() + 8);
    let bytes = pattern.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] != b'%' {
            let start = i;
            i += 1;
            while i < bytes.len() && bytes[i] != b'%' {
                i += 1;
            }
            out.push_str(&pattern[start..i]);
            continue;
        }
        i += 1;
        if i >= bytes.len() {
            return None;
        }
        match bytes[i] {
            b'%' => {
                out.push('%');
                i += 1;
            }
            b'b' => {
                out.push_str(abbr_months[(month - 1) as usize]);
                i += 1;
            }
            b'd' => {
                push_two_digits(&mut out, day);
                i += 1;
            }
            b'e' => {
                if day < 10 {
                    out.push(' ');
                    out.push(char::from(b'0' + day as u8));
                } else {
                    push_two_digits(&mut out, day);
                }
                i += 1;
            }
            b'y' => {
                push_two_digits(&mut out, (year as u32) % 100);
                i += 1;
            }
            b'Y' => {
                push_four_digits(&mut out, year as u32);
                i += 1;
            }
            b'-' => {
                i += 1;
                if i >= bytes.len() {
                    return None;
                }
                match bytes[i] {
                    b'd' | b'e' => {
                        push_u32_decimal(&mut out, day);
                        i += 1;
                    }
                    _ => return None,
                }
            }
            _ => return None,
        }
    }
    Some(out)
}

/// Truncates `text` to at most `max_chars` Unicode scalar values, replacing the tail with `"..."`
/// when longer (matching ActionView's `truncate(text, length: max_chars)`).
fn push_truncated_escaped(out: &mut String, text: &str, max_chars: usize) {
    let mut char_iter = text.char_indices();
    let keep_chars = max_chars.saturating_sub(3);
    let mut cut_byte = text.len();
    for idx in 0..=max_chars {
        match char_iter.next() {
            Some((byte_pos, _)) => {
                if idx == keep_chars {
                    cut_byte = byte_pos;
                }
            }
            None => {
                push_html_escaped(out, text);
                return;
            }
        }
    }
    push_html_escaped(out, &text[..cut_byte]);
    out.push_str("...");
}

/// Appends `processed_html` to `out`, applying Cloudflare domain replacement if configured.
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

fn prepare_author(
    author: &CommentAuthorInput<'_>,
    static_ctx: &CommentStaticContext<'_>,
) -> Option<PreparedAuthor> {
    let card_color = crate::color::brightness(author.smallest_color_hex.as_bytes(), 0.88, false)
        .or_else(|| author.card_color_fallback.map(str::to_owned))?;

    let mut user_id_str = String::with_capacity(12);
    push_i64_decimal(&mut user_id_str, author.user_id);

    let mut admin_user_path = String::with_capacity(28 + user_id_str.len());
    admin_user_path.push_str("/admin/member_manager/users/");
    admin_user_path.push_str(&user_id_str);

    let escaped_name = html_escape(author.name);
    let escaped_username = html_escape(author.username);
    let escaped_user_url = html_escape(author.user_url);
    let escaped_profile_image_50 = html_escape(author.profile_image_50);

    let escaped_org_badge_html = if let Some(org_name) = author.org_name {
        let escaped_org = html_escape(org_name);
        let mut badge = String::with_capacity(140 + escaped_org.len() * 2);
        badge.push_str("        <span class=\"c-indicator c-indicator--subtle c-indicator--round c-indicator--relaxed p-1 px-2\" title=\"Member of ");
        badge.push_str(&escaped_org);
        badge.push_str("\">\n          ");
        badge.push_str(&escaped_org);
        badge.push_str("\n        </span>\n");
        badge
    } else {
        String::new()
    };

    let escaped_details_aria_label =
        escape_template_with_user(static_ctx.t_users_details_template, &escaped_name);
    let escaped_copy_aria_label =
        escape_template_with_user(static_ctx.t_menu_copy_aria_template, &escaped_name);
    let escaped_settings_aria_label =
        escape_template_with_user(static_ctx.t_menu_settings_aria_template, &escaped_name);
    let escaped_unhide_aria_label =
        escape_template_with_user(static_ctx.t_menu_unhide_aria_template, &escaped_name);
    let escaped_hide_aria_label =
        escape_template_with_user(static_ctx.t_menu_hide_aria_template, &escaped_name);
    let escaped_admin_profile_aria_label =
        escape_template_with_user(static_ctx.t_menu_admin_profile_aria_template, &escaped_name);
    let escaped_moderate_aria_label =
        escape_template_with_user(static_ctx.t_menu_moderate_aria_template, &escaped_name);
    let escaped_report_aria_label =
        escape_template_with_user(static_ctx.t_menu_report_aria_template, &escaped_name);

    // Build `shared/_profile_preview_card.html.erb` + `shared/_profile_card_content.html.erb` tail
    // (everything after `<div id="comment-profile-preview-content-{comment.id}"`).
    let mut tail = String::with_capacity(1400);
    tail.push_str("\" class=\"profile-preview-card__content p-4 pt-0 branded-7 crayons-dropdown\" style=\"--card-color: ");
    push_html_escaped(&mut tail, &card_color);
    tail.push_str("; border-top-color: var(--card-color);\" data-testid=\"profile-preview-card\" data-repositioning-dropdown=\"true\">\n    <div class=\"gap-4 grid\">\n        <div class=\"-mt-4\">\n  <a href=\"/");
    tail.push_str(&escaped_username);
    tail.push_str("\" class=\"flex\">\n    <span class=\"crayons-avatar crayons-avatar--xl  mr-2 shrink-0\">\n      <img src=\"");
    push_html_escaped(&mut tail, author.profile_image_90);
    tail.push_str("\" class=\"crayons-avatar__image\" alt=\"\" loading=\"lazy\" />\n    </span>\n    <span class=\"crayons-link crayons-subtitle-2 mt-5\">\n      ");
    tail.push_str(&escaped_name);
    tail.push_str("\n      ");
    if author.is_subscriber {
        tail.push_str(static_ctx.subscription_icon_no_link_html);
    }
    tail.push_str("\n      ");
    if author.is_community_leader {
        tail.push_str(static_ctx.community_leader_icon_html);
    }
    tail.push_str("\n    </span>\n  </a>\n</div>\n\n<div class=\"print-hidden\">\n  ");

    // `follow_button(actor, style = "", classes = "w-100")`
    let mut data_info_json = String::with_capacity(64 + author.name.len());
    data_info_json.push_str("{\"className\":\"User\",\"style\":\"\",\"id\":");
    data_info_json.push_str(&user_id_str);
    data_info_json.push_str(",\"name\":");
    crate::json::write_json_string(&mut data_info_json, author.name, true);
    data_info_json.push('}');

    let escaped_follow_aria =
        escape_template_with_user(static_ctx.t_follow_user_aria_template, &escaped_name);
    tail.push_str("<button name=\"button\" type=\"button\" data-info=\"");
    push_html_escaped(&mut tail, &data_info_json);
    tail.push_str("\" class=\"crayons-btn follow-action-button whitespace-nowrap w-100 follow-user\" aria-label=\"");
    tail.push_str(&escaped_follow_aria);
    tail.push_str("\" aria-pressed=\"false\">");
    push_html_escaped(&mut tail, static_ctx.t_follow_user_text);
    tail.push_str("</button>\n</div>\n");

    if let Some(tag_line) = author.tag_line {
        if !tag_line.is_empty() {
            tail.push_str("  <div class=\"color-base-70\">\n    ");
            push_truncated_escaped(&mut tail, tag_line, 200);
            tail.push_str("\n  </div>\n");
        }
    }

    tail.push_str("\n  <div class=\"user-metadata-details\">\n    <ul class=\"user-metadata-details-inner\">\n");

    if let Some(email) = author.displayed_email {
        let escaped_email = html_escape(email);
        tail.push_str("        <li>\n          <div class=\"key\">\n            ");
        push_html_escaped(&mut tail, static_ctx.t_sticky_email);
        tail.push_str(
            "\n          </div>\n          <div class=\"value\">\n            <a href=\"mailto:",
        );
        tail.push_str(&escaped_email);
        tail.push_str("\">");
        tail.push_str(&escaped_email);
        tail.push_str("</a>\n          </div>\n        </li>\n");
    }

    if let Some(location) = author.location {
        if !location.is_empty() {
            tail.push_str("        <li>\n          <div class=\"key\">\n            ");
            push_html_escaped(&mut tail, static_ctx.t_sticky_location);
            tail.push_str("\n          </div>\n          <div class=\"value\">\n            ");
            push_html_escaped(&mut tail, location);
            tail.push_str("\n          </div>\n        </li>\n");
        }
    }

    for &(label, value) in &author.header_fields {
        tail.push_str("          <li>\n            <div class=\"key\">\n              ");
        push_html_escaped(&mut tail, label);
        tail.push_str("\n            </div>\n            <div class=\"value\">\n              ");
        push_html_escaped(&mut tail, value);
        tail.push_str("\n            </div>\n          </li>\n");
    }

    tail.push_str("      <li>\n        <div class=\"key\">\n          ");
    push_html_escaped(&mut tail, static_ctx.t_sticky_joined);
    tail.push_str("\n        </div>\n        <div class=\"value\">\n          ");
    if let Some((tv_sec, utc_offset)) = author.created_at {
        let (year, month, day) = local_civil_date(tv_sec, utc_offset)?;
        let joined_date_str = format_strftime_date(
            static_ctx.time_format_short_with_year,
            year,
            month,
            day,
            &static_ctx.abbr_month_names,
        )?;
        tail.push_str("<time datetime=\"");
        push_utc_iso8601(&mut tail, tv_sec)?;
        tail.push_str("\" class=\"date\">");
        push_html_escaped(&mut tail, &joined_date_str);
        tail.push_str("</time>");
    }
    tail.push_str("\n        </div>\n      </li>\n    </ul>\n  </div>\n\n    </div>\n</div>\n");

    Some(PreparedAuthor {
        user_id_str,
        admin_user_path,
        escaped_name,
        escaped_username,
        escaped_user_url,
        escaped_profile_image_50,
        escaped_org_badge_html,
        escaped_details_aria_label,
        escaped_copy_aria_label,
        escaped_settings_aria_label,
        escaped_unhide_aria_label,
        escaped_hide_aria_label,
        escaped_admin_profile_aria_label,
        escaped_moderate_aria_label,
        escaped_report_aria_label,
        profile_card_tail_html: tail,
    })
}

#[allow(clippy::too_many_arguments)]
fn render_single_comment(
    out: &mut String,
    static_ctx: &CommentStaticContext<'_>,
    view_ctx: &CommentViewContext<'_>,
    authors: &[CommentAuthorInput<'_>],
    prepared_authors: &[PreparedAuthor],
    node: &CommentNodeInput<'_>,
    is_view_root: bool,
    is_childless: bool,
    low_quality: bool,
    super_low_quality: bool,
    subtree_html: &str,
    state: &mut MutableRenderState,
) -> Option<()> {
    let author = authors.get(node.author_idx)?;
    let prep = prepared_authors.get(node.author_idx)?;

    let mut id_buf = [0u8; 20];
    let id_code_generated = format_id_code_base26(node.id, &mut id_buf);
    let mut node_id_str = String::with_capacity(12);
    push_i64_decimal(&mut node_id_str, node.id);

    let comment_class = if node.is_root || is_view_root {
        "root"
    } else {
        "child"
    };
    let should_be_hidden =
        node.hidden_by_commentable_user && !node.is_root_comment && !view_ctx.root_comment_hidden;

    // 1. Mid-comments billboard (`_comment.html.erb:3-6`)
    if state.current_comment_index.unwrap_or(0) > 6 && !state.shown_billboard && node.depth == 0 {
        out.push_str(
            "    <div class=\"js-billboard-container mid-comments-billboard-container pb-6\" data-async-url=\"",
        );
        push_html_escaped(out, view_ctx.billboard_async_url);
        out.push_str("\"></div>\n");
        state.shown_billboard = true;
    }

    // 2. `<details>` wrapper (`_comment.html.erb:7-18`)
    if node.depth < 3 {
        out.push_str(
            "    <details class=\"comment-wrapper js-comment-wrapper comment-wrapper--deep-",
        );
        push_u32_decimal(out, node.depth as u32);
        out.push_str("\n                    ");
        out.push_str(comment_class);
        out.push_str("\n                    ");
        if should_be_hidden {
            out.push_str("details-comment-hidden-by-commentable-user");
        }
        out.push_str("\" open>\n      <summary aria-label=\"Toggle this comment (and replies)\" data-tracking-name=\"expand_comment_toggle\">\n        <span class=\"");
        if node.depth > 0 {
            out.push_str("mx-0");
        } else {
            out.push_str("m:mx-1");
        }
        out.push_str(" inline-block align-middle\">\n          ");
        out.push_str(static_ctx.icon_collapse);
        out.push_str("\n          ");
        out.push_str(static_ctx.icon_expand);
        out.push_str("\n        </span>\n        <span class=\"js-collapse-comment-content inline-block align-middle\"></span>\n      </summary>\n");
    }

    // 3. `<div id="comment-node-...">` (`_comment.html.erb:19-33`)
    out.push_str("  <div\n    id=\"comment-node-");
    out.push_str(&node_id_str);
    out.push_str("\"\n    class=\"\n      comment single-comment-node\n      ");
    if low_quality {
        out.push_str("low-quality-comment");
    }
    out.push_str("\n      ");
    out.push_str(comment_class);
    out.push_str("\n      comment--deep-");
    push_u32_decimal(out, node.depth as u32);
    out.push_str("\n      ");
    if node.depth > 3 {
        out.push_str("comment--too-deep");
    }
    out.push_str("\n    \"\n    data-comment-id=\"");
    out.push_str(&node_id_str);
    out.push_str("\"\n    data-path=\"");
    push_html_escaped(out, view_ctx.commentable_path);
    out.push_str("/comments/");
    out.push_str(id_code_generated);
    out.push_str("\"\n    data-comment-author-id=\"");
    let author_id_unless_deleted = if node.deleted { "0" } else { &prep.user_id_str };
    out.push_str(author_id_unless_deleted);
    out.push_str("\"\n    data-content-user-id=\"");
    out.push_str(author_id_unless_deleted);
    out.push_str("\">\n    <a name=\"comment-");
    push_html_escaped(out, node.id_code);
    out.push_str("\" style=\"position: absolute; top: -8px;\">&nbsp;</a>\n    ");

    // 4. `_comment_proper.html.erb` + `_comment_avatar.html.erb`
    out.push_str("<div class=\"comment__inner\">\n  ");
    if node.deleted {
        out.push_str("  <span class=\"shrink-0 crayons-avatar ");
        if node.depth == 0 {
            out.push_str("m:crayons-avatar--l mt-4 m:mt-3");
        } else {
            out.push_str("mt-4");
        }
        out.push_str("\">\n    ");
        out.push_str(view_ctx.mascot_image_tag_html);
        out.push_str("\n  </span>\n");
    } else {
        out.push_str("  <a href=\"");
        out.push_str(&prep.escaped_user_url);
        out.push_str("\" class=\"shrink-0 crayons-avatar ");
        if node.depth == 0 {
            out.push_str("m:crayons-avatar--l mt-4 m:mt-3");
        } else {
            out.push_str("mt-4");
        }
        out.push_str(
            "\">\n    <img class=\"crayons-avatar__image\" width=\"32\" height=\"32\" src=\"",
        );
        out.push_str(&prep.escaped_profile_image_50);
        out.push_str("\" alt=\"");
        out.push_str(&prep.escaped_username);
        out.push_str(" profile image\" loading=\"lazy\" />\n  </a>\n");
    }

    out.push_str("\n\n  <div class=\"inner-comment comment__details\">\n    <div class=\"comment__content crayons-card\">\n");

    let show_deleted_placeholder = node.deleted || (super_low_quality && !view_ctx.is_admin);
    if show_deleted_placeholder {
        out.push_str("        <div class=\"p-6 align-center opacity-50 fs-s\">\n          <span class=\"js-comment-username\">\n            ");
        push_html_escaped(out, static_ctx.t_comment_deleted);
        out.push_str("\n          </span>\n        </div>\n");
    } else {
        // 5. `_comment_quality_marker.html.erb`
        out.push_str("        ");
        if low_quality {
            out.push_str("  <div class=\"crayons-notice crayons-notice--warning low-quality-comment-marker\">\n    ");
            push_html_escaped(out, static_ctx.t_quality_low);
            out.push_str(" <a href=\"/code-of-conduct\"><strong>");
            push_html_escaped(out, static_ctx.t_quality_conduct);
            out.push_str("</strong></a>\n");
            if super_low_quality {
                out.push_str("      <p><strong>(");
                push_html_escaped(out, static_ctx.t_quality_superlow);
                out.push_str(")</strong></p>\n");
            }
            out.push_str("  </div>\n");
        }
        out.push('\n');
        if node.hidden_by_commentable_user {
            out.push_str("  <div class=\"low-quality-comment-marker comment__quality-marker ");
            if should_be_hidden {
                out.push_str("element-hidden-by-commentable-user");
            }
            out.push_str("\">\n    ");
            out.push_str(static_ctx.icon_info);
            out.push_str("\n      ");
            if view_ctx.has_root_comment {
                push_html_escaped(out, static_ctx.t_quality_hidden_visible);
            } else {
                push_html_escaped(out, static_ctx.t_quality_hidden_accessible);
            }
            out.push_str("\n  </div>\n");
        }

        // 6. `_comment_header.html.erb`
        out.push_str("\n\n        <div class=\"comment__header\">\n  <a href=\"");
        out.push_str(&prep.escaped_user_url);
        out.push_str("\" class=\"crayons-link crayons-link--secondary flex items-center fw-medium m:hidden\">\n    <span class=\"js-comment-username\">\n      ");
        out.push_str(&prep.escaped_name);
        out.push('\n');
        out.push_str(&prep.escaped_org_badge_html);
        out.push_str("    </span>\n");
        if author.is_op {
            out.push_str("      <span class=\"crayons-hover-tooltip inline-block spec-op-author -mr-2\" data-tooltip=\"");
            push_html_escaped(out, view_ctx.ama_or_op_banner);
            out.push_str("\">\n        ");
            out.push_str(static_ctx.icon_small_medal);
            out.push_str("\n      </span>\n");
        }
        out.push_str("  </a>\n  <div class=\"profile-preview-card relative mb-4 s:mb-0 fw-medium hidden m:block\">\n    <button id=\"comment-profile-preview-trigger-");
        out.push_str(&node_id_str);
        out.push_str("\" aria-controls=\"comment-profile-preview-content-");
        out.push_str(&node_id_str);
        out.push_str("\" class=\"profile-preview-card__trigger p-1 -my-1 -ml-1 crayons-btn crayons-btn--ghost\" aria-label=\"");
        out.push_str(&prep.escaped_details_aria_label);
        out.push_str("\">\n      ");
        out.push_str(&prep.escaped_name);
        out.push('\n');
        out.push_str(&prep.escaped_org_badge_html);
        out.push_str("      ");
        if author.is_subscriber {
            out.push_str(static_ctx.subscription_icon_html);
        }
        out.push_str("\n      ");
        if author.is_community_leader {
            out.push_str(static_ctx.community_leader_icon_html);
        }
        out.push_str("\n    </button>\n    <div id=\"comment-profile-preview-content-");
        out.push_str(&node_id_str);
        out.push_str(&prep.profile_card_tail_html);
        out.push('\n');
        if author.is_op {
            out.push_str("      <span class=\"crayons-hover-tooltip inline-block spec-op-author -ml-2\" data-tooltip=\"");
            push_html_escaped(out, view_ctx.ama_or_op_banner);
            out.push_str("\">\n        ");
            out.push_str(static_ctx.icon_small_medal);
            out.push_str("\n      </span>\n");
        }
        out.push_str("\n  </div>\n\n  ");

        // Precompute `comment.path`, `URL.comment(comment)`, and `contextual_comment_url`
        let mut comment_path =
            String::with_capacity(author.username.len() + id_code_generated.len() + 10);
        comment_path.push('/');
        comment_path.push_str(author.username);
        comment_path.push_str("/comment/");
        comment_path.push_str(id_code_generated);

        let comment_permalink_url = crate::url::join_url(view_ctx.comment_base_url, &comment_path)?;
        let contextual_url = if view_ctx.contextual_use_permalink {
            comment_permalink_url.clone()
        } else if let Some(article_path) = view_ctx.article_path {
            let mut frag_ref = String::with_capacity(article_path.len() + node.id_code.len() + 9);
            frag_ref.push_str(article_path);
            frag_ref.push_str("#comment-");
            frag_ref.push_str(node.id_code);
            crate::url::join_url(view_ctx.app_base_url, &frag_ref)?
        } else {
            comment_permalink_url.clone()
        };

        // 7. `_comment_date.erb`
        let (created_tv_sec, created_utc_offset) = node.created_at?;
        let (created_year, created_month, created_day) =
            local_civil_date(created_tv_sec, created_utc_offset)?;
        let readable_publish_date = if created_year == view_ctx.current_year {
            format_strftime_date(
                static_ctx.time_format_short,
                created_year,
                created_month,
                created_day,
                &static_ctx.abbr_month_names,
            )?
        } else {
            format_strftime_date(
                static_ctx.time_format_short_with_yy,
                created_year,
                created_month,
                created_day,
                &static_ctx.abbr_month_names,
            )?
        };

        out.push_str("<span class=\"color-base-30 px-2 m:pl-0\" role=\"presentation\">&bull;</span>\n\n<a href=\"");
        push_html_escaped(out, &contextual_url);
        out.push_str("\" class=\"comment-date crayons-link crayons-link--secondary fs-s\">\n  <time datetime=\"");
        push_utc_iso8601(out, created_tv_sec)?;
        out.push_str("\" class=");
        if created_year == view_ctx.current_year {
            out.push_str("date-no-year");
        } else {
            out.push_str("date-short-year");
        }
        out.push_str(">\n    ");
        push_html_escaped(out, &readable_publish_date);
        out.push_str("\n  </time>\n\n");

        if let Some((edited_tv_sec, edited_utc_offset)) = node.edited_at {
            let (edited_year, edited_month, edited_day) =
                local_civil_date(edited_tv_sec, edited_utc_offset)?;
            // `decorated_comment.edited_at.strftime(t("time.formats.short"))` uses Ruby's `strftime`
            // (English month abbreviations).
            let edited_short_str = format_strftime_date(
                static_ctx.time_format_short,
                edited_year,
                edited_month,
                edited_day,
                &ENGLISH_ABBR_MONTHS,
            )?;
            let mut time_tag = String::with_capacity(64 + edited_short_str.len());
            time_tag.push_str("<time datetime=\"");
            push_utc_iso8601(&mut time_tag, edited_tv_sec)?;
            time_tag.push_str("\" class=\"date-no-year\">");
            push_html_escaped(&mut time_tag, &edited_short_str);
            time_tag.push_str("</time>");

            out.push_str("    <span class=\"hidden m:inline-block\">");
            if let Some(pos) = static_ctx
                .t_edited_text_html_template
                .find(DATE_PLACEHOLDER)
            {
                out.push_str(&static_ctx.t_edited_text_html_template[..pos]);
                out.push_str(&time_tag);
                out.push_str(
                    &static_ctx.t_edited_text_html_template[pos + DATE_PLACEHOLDER.len()..],
                );
            } else {
                out.push_str(static_ctx.t_edited_text_html_template);
            }
            out.push_str("</span>\n    <span class=\"m:hidden\">");
            out.push_str(static_ctx.t_edited_short_html);
            out.push_str("</span>\n");
        }
        out.push_str("</a>\n\n\n");

        // 8. AI disclosure badge (`_comment_header.html.erb:41-47`)
        if node.ai_disclosure_level == 3 || node.ai_disclosure_level == 5 {
            let (desc, label) = if node.ai_disclosure_level == 3 {
                (static_ctx.t_ai_some_description, static_ctx.t_ai_some_label)
            } else {
                (static_ctx.t_ai_auto_description, static_ctx.t_ai_auto_label)
            };
            out.push_str("    <span class=\"crayons-hover-tooltip inline-flex items-center ai-disclosure-tag fs-xs color-base-60 ml-2\" data-tooltip=\"");
            push_html_escaped(out, desc);
            out.push_str("\">\n      <span class=\"c-indicator c-indicator--subtle c-indicator--round c-indicator--relaxed p-1 px-2\">\n        ");
            push_html_escaped(out, label);
            out.push_str("\n      </span>\n    </span>\n");
        }

        // 9. Dropdown menu (`_comment_header.html.erb:49-83`)
        out.push_str("\n  <div class=\"comment__dropdown\" data-tracking-name=\"comment_dropdown\">\n    <button id=\"comment-dropdown-trigger-");
        out.push_str(&node_id_str);
        out.push_str("\" aria-controls=\"comment-dropdown-");
        out.push_str(&node_id_str);
        out.push_str("\" aria-expanded=\"false\"\n      class=\"dropbtn comment__dropdown-trigger crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon ");
        if should_be_hidden {
            out.push_str("element-hidden-by-commentable-user");
        }
        out.push_str("\"\n      aria-label=\"");
        push_html_escaped(out, static_ctx.t_menu_aria_label);
        out.push_str("\" aria-haspopup=\"true\">\n      ");
        out.push_str(static_ctx.icon_small_overflow_horizontal);
        out.push_str("\n    </button>\n    <div id=\"comment-dropdown-");
        out.push_str(&node_id_str);
        out.push_str("\" class=\"crayons-dropdown right-1 s:right-0 s:left-auto fs-base dropdown\">\n      <ul class=\"m-0\">\n        <li><a href=\"");
        push_html_escaped(out, &contextual_url);
        out.push_str(
            "\" class=\"crayons-link crayons-link--block permalink-copybtn\" aria-label=\"",
        );
        out.push_str(&prep.escaped_copy_aria_label);
        out.push_str("\" data-no-instant>");
        push_html_escaped(out, static_ctx.t_menu_copy_text);
        out.push_str("</a></li>\n        <li class=\"comment-actions hidden\" data-user-id=\"");
        out.push_str(&prep.user_id_str);
        out.push_str("\" data-action=\"settings-button\" data-path=\"");
        push_html_escaped(out, &comment_permalink_url);
        out.push_str("/settings\" aria-label=\"");
        out.push_str(&prep.escaped_settings_aria_label);
        out.push_str("\"></li>\n");

        if !author.by_staff_account {
            out.push_str("          <li class=\"comment-actions hidden\" data-action=\"hide-button\" data-commentable-user-id=\"");
            push_html_escaped(out, view_ctx.commentable_user_id_str);
            out.push_str("\" data-user-id=\"");
            out.push_str(&prep.user_id_str);
            out.push_str("\">\n");
            if node.hidden_by_commentable_user {
                out.push_str("              <a href=\"#\" class=\"crayons-link crayons-link--block unhide-comment\" data-hide-type=\"unhide\" data-comment-id=\"");
                out.push_str(&node_id_str);
                out.push_str("\" aria-label=\"");
                out.push_str(&prep.escaped_unhide_aria_label);
                out.push_str("\">\n                ");
                push_html_escaped(out, static_ctx.t_menu_unhide_text);
                out.push_str("\n              </a>\n");
            } else {
                let comment_app_url = if view_ctx.app_base_url == view_ctx.comment_base_url {
                    comment_permalink_url.clone()
                } else {
                    crate::url::join_url(view_ctx.app_base_url, &comment_path)?
                };
                out.push_str("              <button\n                class=\"flex justify-between crayons-link crayons-link--block w-100 bg-transparent border-0 hide-comment\"\n                data-hide-type=\"hide\"\n                data-comment-id=\"");
                out.push_str(&node_id_str);
                out.push_str("\"\n                data-comment-url=\"");
                push_html_escaped(out, &comment_app_url);
                out.push_str("\"\n                aria-label=\"");
                out.push_str(&prep.escaped_hide_aria_label);
                out.push_str("\">\n                ");
                push_html_escaped(out, static_ctx.t_menu_hide_text);
                out.push_str("\n              </button>\n");
            }
            out.push_str("          </li>\n");
        }

        out.push_str("        <li class=\"admin-actions hidden\" data-path=\"");
        push_html_escaped(out, &prep.admin_user_path);
        out.push_str("\" data-text=\"");
        push_html_escaped(out, static_ctx.t_menu_admin_profile_text);
        out.push_str("\" aria-label=\"");
        out.push_str(&prep.escaped_admin_profile_aria_label);
        out.push_str("\"></li>\n        <li class=\"mod-actions hidden mod-actions-comment-button\" data-path=\"");
        push_html_escaped(out, &comment_permalink_url);
        out.push_str("/mod\" aria-label=\"");
        out.push_str(&prep.escaped_moderate_aria_label);
        out.push_str("\"></li>\n        <li class=\"report-abuse-link-wrapper\" data-path=\"/report-abuse?url=");
        push_html_escaped(out, &comment_permalink_url);
        out.push_str("\" aria-label=\"");
        out.push_str(&prep.escaped_report_aria_label);
        out.push_str("\"></li>\n        <li class=\"current-user-actions\"></li>\n      </ul>\n    </div>\n  </div>\n</div>\n\n\n        <div\n          class=\"\n            comment__body\n            text-styles\n            text-styles--secondary\n            body\n            ");
        if low_quality {
            out.push_str("color-base-60");
        }
        out.push_str("\n            ");
        if should_be_hidden {
            out.push_str("element-hidden-by-commentable-user");
        }
        out.push_str("\n          \">\n          ");
        push_processed_html_final(
            out,
            node.processed_html,
            static_ctx.prior_cloudflare_domain,
            static_ctx.current_cloudflare_domain,
        );
        out.push_str("\n        </div>\n\n");
        if should_be_hidden {
            out.push_str("          <div class=\"p-6 align-center opacity-50 fs-s hidden comment-hidden-by-author-text\">\n            ");
            push_html_escaped(out, static_ctx.t_comment_hidden);
            out.push_str("\n          </div>\n");
        }
    }

    // 10. Closing `.comment__content` and `<script>` block (`_comment_proper.html.erb:42-53`)
    out.push_str("    </div>\n\n    <script>\n");
    if node.processed_html.contains("podcastliquidtag") {
        out.push_str("        ");
        out.push_str(PODCAST_TAG_SCRIPT);
        out.push('\n');
    }
    if node.processed_html.contains("tweet-embed") {
        out.push_str("        ");
        out.push_str(TWEET_TAG_SCRIPT);
        out.push('\n');
    }
    out.push_str("    </script>\n\n    ");

    // 11. `_comment_footer.html.erb` (`_comment_proper.html.erb:54-60`)
    if !(node.deleted || !view_ctx.has_commentable || should_be_hidden) {
        out.push_str("<footer class=\"comment__footer print-hidden\">\n  <button\n    class=\"crayons-tooltip__activator relative crayons-btn crayons-btn--ghost crayons-btn--icon");
        if node.public_reactions_count != 0 {
            out.push_str("-left");
        }
        out.push_str(" crayons-btn--s mr-1 reaction-like inline-flex reaction-button\"\n    id=\"button-for-comment-");
        out.push_str(&node_id_str);
        out.push_str("\"\n    data-comment-id=\"");
        out.push_str(&node_id_str);
        out.push_str("\"\n    aria-label=\"");
        push_html_escaped(out, static_ctx.t_heart_aria_label);
        out.push_str("\"\n    data-tracking-name=\"comment_heart_button\">\n    ");
        out.push_str(static_ctx.icon_small_heart);
        out.push_str("\n    ");
        out.push_str(static_ctx.icon_small_heart_filled);
        out.push_str("\n    ");

        // `t("views.comments.footer.heart.count_html", num: ..., likes: ...)`
        let mut num_span = String::with_capacity(48);
        num_span.push_str("<span class=\"reactions-count\">");
        if node.public_reactions_count > 0 {
            push_i64_decimal(&mut num_span, node.public_reactions_count);
        }
        num_span.push_str("</span>");

        let mut likes_span = String::with_capacity(80);
        likes_span.push_str("<span class=\"reactions-label hidden m:inline-block\">");
        if node.public_reactions_count != 0 {
            let tmpl = if node.public_reactions_count == 1 {
                static_ctx.t_nbsp_likes_one_template
            } else {
                static_ctx.t_nbsp_likes_other_template
            };
            if let Some(pos) = tmpl.find(COUNT_PLACEHOLDER) {
                likes_span.push_str(&tmpl[..pos]);
                push_i64_decimal(&mut likes_span, node.public_reactions_count);
                likes_span.push_str(&tmpl[pos + COUNT_PLACEHOLDER.len()..]);
            } else {
                likes_span.push_str(tmpl);
            }
        }
        likes_span.push_str("</span>");

        let mut rest = static_ctx.t_heart_count_html_template;
        while !rest.is_empty() {
            let next_num = rest.find(NUM_PLACEHOLDER);
            let next_likes = rest.find(LIKES_PLACEHOLDER);
            match (next_num, next_likes) {
                (Some(n), Some(l)) if n < l => {
                    out.push_str(&rest[..n]);
                    out.push_str(&num_span);
                    rest = &rest[n + NUM_PLACEHOLDER.len()..];
                }
                (_, Some(l)) => {
                    out.push_str(&rest[..l]);
                    out.push_str(&likes_span);
                    rest = &rest[l + LIKES_PLACEHOLDER.len()..];
                }
                (Some(n), None) => {
                    out.push_str(&rest[..n]);
                    out.push_str(&num_span);
                    rest = &rest[n + NUM_PLACEHOLDER.len()..];
                }
                (None, None) => {
                    out.push_str(rest);
                    break;
                }
            }
        }

        out.push_str(
            "\n    <span data-testid=\"tooltip\" class=\"crayons-tooltip__content\">\n      ",
        );
        push_html_escaped(out, static_ctx.t_heart_title);
        out.push_str("\n    </span>\n  </button>\n\n  ");

        // `favorite_control_tag(comment, variant: :comment)`
        if static_ctx.favorites_enabled {
            out.push_str("<span class=\"favorite-control-root\" data-favorite-control=\"true\" data-variant=\"comment\" data-favoritable-type=\"Comment\" data-favoritable-id=\"");
            out.push_str(&node_id_str);
            out.push_str("\" data-favoritable-user-id=\"");
            out.push_str(&prep.user_id_str);
            if let Some(fav_user_id) = node.favorited_by_user_id {
                out.push_str("\" data-favorited=\"true\" data-favorited-by-user-id=\"");
                push_i64_decimal(out, fav_user_id);
                out.push_str("\" ");
                out.push_str(static_ctx.favorite_static_data_attrs);
                out.push('>');
                out.push_str(static_ctx.favorite_favorited_inner_html);
                out.push_str("</span>");
            } else {
                out.push_str("\" data-favorited=\"false\" ");
                out.push_str(static_ctx.favorite_static_data_attrs);
                out.push_str("></span>");
            }
        }

        out.push_str("\n\n");
        if !view_ctx.discussion_lock {
            if node.depth < 2 || is_childless {
                out.push_str("      <button\n        class=\"actions crayons-btn crayons-btn--ghost crayons-btn--s crayons-btn--icon-left toggle-reply-form mr-1 inline-flex\"\n        data-comment-id=\"");
                out.push_str(&node_id_str);
                out.push_str("\"\n        data-path=\"");
                push_html_escaped(out, view_ctx.commentable_path);
                out.push_str("/comments/");
                out.push_str(id_code_generated);
                out.push_str("\"\n        data-tracking-name=\"comment_reply_button\"\n        data-testid=\"reply-button-");
                out.push_str(&node_id_str);
                out.push_str("\"\n        rel=\"nofollow\">\n        ");
                out.push_str(static_ctx.icon_small_comment);
                out.push_str("\n        <span class=\"hidden m:inline-block\">");
                push_html_escaped(out, static_ctx.t_reply_text);
                out.push_str("</span>\n      </button>\n");
            } else {
                out.push_str("      <span class=\"fs-s inline-flex items-center fs-italic color-base-50 pl-1\">\n        ");
                out.push_str(static_ctx.icon_small_thread);
                out.push_str("\n        ");
                push_html_escaped(out, static_ctx.t_thread_text);
                out.push_str("\n      </span>\n");
            }
        }
        out.push_str("\n</footer>\n");
    }

    // 12. Closing `.inner-comment`, `.comment__inner`, `subtree_html`, `.comment`, and `</details>`
    out.push_str("\n  </div>\n</div>\n");
    out.push_str(subtree_html);
    out.push_str("\n\n  </div>\n");
    if node.depth < 3 {
        out.push_str("    </details>\n");
    }

    if let Some(idx) = state.current_comment_index.as_mut() {
        *idx += 1;
    }

    Some(())
}

#[allow(clippy::too_many_arguments)]
fn render_siblings(
    out: &mut String,
    static_ctx: &CommentStaticContext<'_>,
    view_ctx: &CommentViewContext<'_>,
    authors: &[CommentAuthorInput<'_>],
    prepared_authors: &[PreparedAuthor],
    nodes: &[CommentNodeInput<'_>],
    cursor: &mut usize,
    sibling_count: usize,
    is_view_root: bool,
    state: &mut MutableRenderState,
) -> Option<()> {
    for _ in 0..sibling_count {
        let idx = *cursor;
        let node = nodes.get(idx)?;
        *cursor += 1;

        let subtree_html = if node.child_count > 0 {
            let mut sub_buf = String::with_capacity(node.child_count * 3200);
            render_siblings(
                &mut sub_buf,
                static_ctx,
                view_ctx,
                authors,
                prepared_authors,
                nodes,
                cursor,
                node.child_count,
                false,
                state,
            )?;
            sub_buf
        } else {
            String::new()
        };

        let is_childless = subtree_html.bytes().all(|b| b.is_ascii_whitespace());
        let low_quality = node.score < LOW_QUALITY_THRESHOLD;
        let super_low_quality =
            node.score < HIDE_THRESHOLD || (low_quality && node.processed_html.contains("<a"));
        let hide = is_childless && (super_low_quality || node.deleted);

        if view_ctx.is_admin || !hide {
            render_single_comment(
                out,
                static_ctx,
                view_ctx,
                authors,
                prepared_authors,
                node,
                is_view_root,
                is_childless,
                low_quality,
                super_low_quality,
                &subtree_html,
                state,
            )?;
        }
    }
    Some(())
}

/// Renders an entire nested comment tree into a single HTML buffer and returns the updated
/// `@current_comment_index` and `@shown_billboard` values.
///
/// Returns `None` if any timestamp, date format, color hex, or URL falls outside the supported
/// domain so the caller can fall back to `CommentsHelper#legacy_nested_comments`.
pub fn render_comment_tree(
    static_ctx: &CommentStaticContext<'_>,
    view_ctx: &CommentViewContext<'_>,
    authors: &[CommentAuthorInput<'_>],
    nodes: &[CommentNodeInput<'_>],
    root_count: usize,
) -> Option<CommentTreeOutput> {
    if nodes.is_empty() || root_count == 0 {
        return Some(CommentTreeOutput {
            html: String::new(),
            current_comment_index: view_ctx.current_comment_index,
            shown_billboard: view_ctx.shown_billboard,
        });
    }

    let mut prepared_authors = Vec::with_capacity(authors.len());
    for author in authors {
        prepared_authors.push(prepare_author(author, static_ctx)?);
    }

    let mut state = MutableRenderState {
        current_comment_index: view_ctx.current_comment_index,
        shown_billboard: view_ctx.shown_billboard,
    };

    let mut html = String::with_capacity(nodes.len() * 3500);
    let mut cursor = 0;
    render_siblings(
        &mut html,
        static_ctx,
        view_ctx,
        authors,
        &prepared_authors,
        nodes,
        &mut cursor,
        root_count,
        view_ctx.is_view_root,
        &mut state,
    )?;

    if cursor != nodes.len() {
        return None;
    }

    Some(CommentTreeOutput {
        html,
        current_comment_index: state.current_comment_index,
        shown_billboard: state.shown_billboard,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_static_ctx() -> CommentStaticContext<'static> {
        CommentStaticContext {
            icon_collapse: "<svg class=\"crayons-icon expanded\"></svg>",
            icon_expand: "<svg class=\"crayons-icon collapsed\"></svg>",
            icon_info: "<svg class=\"crayons-icon mr-2\"></svg>",
            icon_small_medal: "<svg class=\"crayons-icon\"></svg>",
            icon_small_overflow_horizontal: "<svg class=\"crayons-icon pointer-events-none\"></svg>",
            icon_small_heart: "<svg class=\"crayons-icon reaction-icon not-reacted\"></svg>",
            icon_small_heart_filled: "<svg class=\"crayons-icon crayons-icon reaction-icon--like reaction-icon reacted\"></svg>",
            icon_small_comment: "<svg class=\"crayons-icon reaction-icon not-reacted\"></svg>",
            icon_small_thread: "<svg class=\"crayons-icon\"></svg>",
            subscription_icon_html: "<a href=\"/++\"><img class=\"subscription-icon\" /></a>",
            subscription_icon_no_link_html: "<img class=\"subscription-icon\" />",
            community_leader_icon_html: "<img class=\"community-leader-icon\" />",
            favorites_enabled: true,
            favorite_static_data_attrs: "data-label-favorite=\"Pick as gem\"",
            favorite_favorited_inner_html: "<span class=\"favorite-control--favorited\"></span>",
            t_comment_deleted: "Comment deleted",
            t_comment_hidden: "Comment hidden by post author",
            t_quality_low: "Comment marked as low quality/non-constructive by the community.",
            t_quality_conduct: "View Code of Conduct",
            t_quality_superlow: "Comment score below hiding threshold, displayed only for admins",
            t_quality_hidden_visible: "Comment hidden by post author - thread only visible in this permalink",
            t_quality_hidden_accessible: "Comment hidden by post author - thread only accessible via permalink",
            t_users_details_template: "__FOREM_USER__ profile details",
            t_edited_text_html_template: "&bull; Edited on __FOREM_DATE__",
            t_edited_short_html: "&bull; Edited",
            t_ai_some_description: "The commenter has disclosed using AI tooling to assist this comment.",
            t_ai_some_label: "AI-assisted",
            t_ai_auto_description: "The commenter has disclosed that this comment was generated autonomously by AI.",
            t_ai_auto_label: "AI-generated",
            t_menu_aria_label: "Toggle dropdown menu",
            t_menu_copy_aria_template: "Copy link to __FOREM_USER__'s comment",
            t_menu_copy_text: "Copy link",
            t_menu_settings_aria_template: "Go to __FOREM_USER__'s comment settings",
            t_menu_unhide_aria_template: "Unhide __FOREM_USER__'s comment",
            t_menu_unhide_text: "Unhide",
            t_menu_hide_aria_template: "Hide __FOREM_USER__'s comment",
            t_menu_hide_text: "Hide",
            t_menu_admin_profile_text: "View Admin Profile",
            t_menu_admin_profile_aria_template: "View __FOREM_USER__'s admin profile",
            t_menu_moderate_aria_template: "Moderate __FOREM_USER__'s comment",
            t_menu_report_aria_template: "Report __FOREM_USER__'s comment",
            t_heart_aria_label: "like",
            t_heart_count_html_template: "__FOREM_NUM____FOREM_LIKES__",
            t_nbsp_likes_one_template: "&nbsp;like",
            t_nbsp_likes_other_template: "&nbsp;likes",
            t_heart_title: "Like",
            t_reply_text: "Reply",
            t_thread_text: "Thread",
            t_follow_user_text: "Follow",
            t_follow_user_aria_template: "Follow user: __FOREM_USER__",
            t_sticky_email: "Email",
            t_sticky_location: "Location",
            t_sticky_joined: "Joined",
            time_format_short: "%b %-e",
            time_format_short_with_yy: "%b %-d '%y",
            time_format_short_with_year: "%b %-e, %Y",
            abbr_month_names: ENGLISH_ABBR_MONTHS,
            prior_cloudflare_domain: None,
            current_cloudflare_domain: None,
        }
    }

    fn sample_view_ctx() -> CommentViewContext<'static> {
        CommentViewContext {
            has_commentable: true,
            commentable_path: "/ben/my-post-123",
            commentable_user_id_str: "10",
            ama_or_op_banner: "Author",
            app_base_url: "https://dev.to",
            comment_base_url: "https://dev.to",
            contextual_use_permalink: true,
            article_path: Some("/ben/my-post-123"),
            mascot_image_tag_html: "<img alt=\"Sloan, the sloth mascot\" />",
            billboard_async_url: "/billboards/post_comments_mid",
            has_root_comment: false,
            root_comment_hidden: false,
            discussion_lock: false,
            is_admin: false,
            is_view_root: true,
            current_year: 2026,
            current_comment_index: Some(0),
            shown_billboard: false,
        }
    }

    fn sample_author() -> CommentAuthorInput<'static> {
        CommentAuthorInput {
            user_id: 42,
            name: "Ada \"Lovelace\" & Co",
            username: "ada",
            user_url: "https://dev.to/ada",
            profile_image_50: "https://dev.to/img50.png",
            profile_image_90: "https://dev.to/img90.png",
            org_name: Some("Analytical Engine"),
            is_op: true,
            by_staff_account: false,
            is_subscriber: true,
            is_community_leader: true,
            smallest_color_hex: "#093656",
            card_color_fallback: None,
            tag_line: Some("First programmer & mathematician"),
            displayed_email: Some("ada@example.com"),
            location: Some("London, UK"),
            header_fields: vec![("Education", "University of London")],
            created_at: Some((1_700_000_000, 0)),
        }
    }

    fn sample_node(
        id: i64,
        depth: usize,
        is_root: bool,
        child_count: usize,
    ) -> CommentNodeInput<'static> {
        CommentNodeInput {
            id,
            author_idx: 0,
            depth,
            is_root,
            score: 10,
            deleted: false,
            hidden_by_commentable_user: false,
            is_root_comment: false,
            public_reactions_count: 3,
            favorited_by_user_id: Some(99),
            id_code: "1cc",
            processed_html: "<p>Hello world</p>",
            ai_disclosure_level: 3,
            created_at: Some((1_762_000_000, 0)),
            edited_at: Some((1_762_003_600, 0)),
            child_count,
        }
    }

    #[test]
    fn formats_base26_id_codes() {
        let mut buf = [0u8; 20];
        assert_eq!(format_id_code_base26(0, &mut buf), "0");
        assert_eq!(format_id_code_base26(25, &mut buf), "p");
        assert_eq!(format_id_code_base26(26, &mut buf), "10");
        assert_eq!(format_id_code_base26(1000, &mut buf), "1cc");
    }

    #[test]
    fn computes_depth_and_root_from_ancestry() {
        assert_eq!(depth_and_root_from_ancestry(None), (0, true));
        assert_eq!(depth_and_root_from_ancestry(Some("42")), (1, false));
        assert_eq!(depth_and_root_from_ancestry(Some("42/99/105")), (3, false));
    }

    #[test]
    fn formats_iso8601_and_strftime_dates() {
        let mut iso = String::new();
        push_utc_iso8601(&mut iso, 0).unwrap();
        assert_eq!(iso, "1970-01-01T00:00:00Z");

        assert_eq!(
            format_strftime_date("%b %-e", 2026, 3, 5, &ENGLISH_ABBR_MONTHS).as_deref(),
            Some("Mar 5")
        );
        assert_eq!(
            format_strftime_date("%b %-d '%y", 2024, 11, 19, &ENGLISH_ABBR_MONTHS).as_deref(),
            Some("Nov 19 '24")
        );
        assert_eq!(
            format_strftime_date("%d de %b '%y", 2024, 2, 7, &ENGLISH_ABBR_MONTHS).as_deref(),
            Some("07 de Feb '24")
        );
    }

    #[test]
    fn hides_childless_deleted_or_super_low_quality_comments_unless_admin() {
        let static_ctx = sample_static_ctx();
        let mut view_ctx = sample_view_ctx();
        let authors = [sample_author()];

        let mut deleted_leaf = sample_node(1000, 0, true, 0);
        deleted_leaf.deleted = true;
        let out = render_comment_tree(&static_ctx, &view_ctx, &authors, &[deleted_leaf.clone()], 1)
            .unwrap();
        assert_eq!(out.html, "");
        assert_eq!(out.current_comment_index, Some(0));

        // Admin still sees childless deleted comments
        view_ctx.is_admin = true;
        let admin_out =
            render_comment_tree(&static_ctx, &view_ctx, &authors, &[deleted_leaf], 1).unwrap();
        assert!(admin_out.html.contains("Comment deleted"));
        assert_eq!(admin_out.current_comment_index, Some(1));
    }

    #[test]
    fn renders_nested_tree_and_updates_billboard_in_post_order() {
        let static_ctx = sample_static_ctx();
        let mut view_ctx = sample_view_ctx();
        view_ctx.current_comment_index = Some(6);
        let authors = [sample_author()];

        // Parent (depth 0) has 1 child (depth 1). Because child renders first in post-order,
        // child increments `current_comment_index` from 6 to 7 before parent checks `> 6`!
        let parent = sample_node(1000, 0, true, 1);
        let child = sample_node(1001, 1, false, 0);
        let out =
            render_comment_tree(&static_ctx, &view_ctx, &authors, &[parent, child], 1).unwrap();
        assert!(out.shown_billboard);
        assert_eq!(out.current_comment_index, Some(8));
        assert!(out.html.contains("mid-comments-billboard-container"));
        assert!(out.html.contains("id=\"comment-node-1000\""));
        assert!(out.html.contains("id=\"comment-node-1001\""));
    }
}
