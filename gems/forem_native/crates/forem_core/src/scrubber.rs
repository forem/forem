//! Sensitive data and secret scrubbing for coding agent session transcripts, matching
//! `AgentSessionParsers::SensitiveDataScrubber` and `AgentSessionParsers::RedactionMetadata`.
//!
//! Exposes both:
//! - **Tier 1 Composable Primitives**: `scrub_sensitive_text`, `scrub_sensitive_text_with_counts`,
//!   and `scrub_sensitive_text_into_accumulator` for single-string secret redaction and counting.
//! - **Tier 2 Pipeline Support**: `RedactionAccumulator` for single-pass transcript-wide redaction
//!   aggregation with deterministic insertion-order tie-breaking matching Ruby's `Hash#sort_by`.

use std::borrow::Cow;

pub const REDACTED_LABEL: &str = "[REDACTED]";
pub const NUM_PATTERNS: usize = 51;

/// Exact pattern names in `AgentSessionParsers::SensitiveDataScrubber::PATTERNS` order.
pub const PATTERN_NAMES: [&str; NUM_PATTERNS] = [
    // === Cloud provider keys ===
    "AWS Access Key",      // 0
    "AWS Secret Key",      // 1
    "AWS MWS Key",         // 2
    "AWS AppSync Key",     // 3
    "Google API Key",      // 4
    "Google OAuth Token",  // 5
    "GCP Service Account", // 6
    // === Code hosting & CI/CD ===
    "GitHub Token",              // 7
    "GitHub Fine-Grained Token", // 8
    "GitLab Token",              // 9
    "Bitbucket Token",           // 10
    "CircleCI Token",            // 11
    "Travis CI Token",           // 12
    "Heroku API Key",            // 13
    "Vercel Token",              // 14
    "Netlify Token",             // 15
    // === Payment & SaaS ===
    "Stripe Secret Key",      // 16
    "Stripe Publishable Key", // 17
    "Stripe Restricted Key",  // 18
    "PayPal Token",           // 19
    "Square Access Token",    // 20
    "Square OAuth Secret",    // 21
    // === Communication ===
    "Slack Token",      // 22
    "Slack Webhook",    // 23
    "Discord Token",    // 24
    "Twilio API Key",   // 25
    "SendGrid API Key", // 26
    "Mailgun API Key",  // 27
    // === AI/ML ===
    "OpenAI API Key",     // 28
    "OpenAI Project Key", // 29
    "Anthropic API Key",  // 30
    "HuggingFace Token",  // 31
    // === Database & infrastructure ===
    "Database URL",    // 32
    "JDBC Connection", // 33
    "Firebase URL",    // 34
    "Firebase Key",    // 35
    // === Private keys ===
    "RSA Private Key",     // 36
    "DSA Private Key",     // 37
    "EC Private Key",      // 38
    "OpenSSH Private Key", // 39
    "PGP Private Key",     // 40
    "Generic Private Key", // 41
    // === Generic secret patterns ===
    "Bearer Token",      // 42
    "Basic Auth Header", // 43
    "JWT Token",         // 44
    "Hex Secret (32+)",  // 45
    "Base64 Secret",     // 46
    // === PII & paths ===
    "Home Directory", // 47
    "Email Address",  // 48
    "IPv4 Address",   // 49
    "SSH Connection", // 50
];

const REQ_UNDERSCORE: u16 = 1 << 0;
const REQ_HYPHEN: u16 = 1 << 1;
const REQ_COLON: u16 = 1 << 2;
const REQ_COLON_OR_EQ: u16 = 1 << 3;
const REQ_AT: u16 = 1 << 4;
const REQ_DOT: u16 = 1 << 5;
const REQ_SLASH: u16 = 1 << 6;
const REQ_DOLLAR: u16 = 1 << 7;
const REQ_QUOTE: u16 = 1 << 8;
const REQ_UPPER: u16 = 1 << 9;
const REQ_DIGIT: u16 = 1 << 10;
const REQ_AWS_DELIM: u16 = 1 << 11;

#[derive(Clone, Copy)]
struct PatternMeta {
    min_len: usize,
    req_flags: u16,
    skip_in_tool_output: bool,
}

const PATTERN_META: [PatternMeta; NUM_PATTERNS] = [
    // 0: AWS Access Key
    PatternMeta {
        min_len: 20,
        req_flags: REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 1: AWS Secret Key (40 chars + 1 lookahead from match start)
    PatternMeta {
        min_len: 41,
        req_flags: REQ_AWS_DELIM,
        skip_in_tool_output: false,
    },
    // 2: AWS MWS Key
    PatternMeta {
        min_len: 45,
        req_flags: REQ_DOT | REQ_HYPHEN,
        skip_in_tool_output: false,
    },
    // 3: AWS AppSync Key (`da2-` + 26)
    PatternMeta {
        min_len: 30,
        req_flags: REQ_HYPHEN | REQ_DIGIT,
        skip_in_tool_output: false,
    },
    // 4: Google API Key (`AIza` + 35)
    PatternMeta {
        min_len: 39,
        req_flags: REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 5: Google OAuth Token (`ya29.` + 1+)
    PatternMeta {
        min_len: 6,
        req_flags: REQ_DOT | REQ_DIGIT,
        skip_in_tool_output: false,
    },
    // 6: GCP Service Account (`"type"\s*:\s*"service_account"`)
    PatternMeta {
        min_len: 24,
        req_flags: REQ_QUOTE | REQ_COLON | REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 7: GitHub Token (`gh[pousr]_` + 36+)
    PatternMeta {
        min_len: 40,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 8: GitHub Fine-Grained Token (`github_pat_` + 22 + `_` + 59+)
    PatternMeta {
        min_len: 93,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 9: GitLab Token (`glpat-` + 20+)
    PatternMeta {
        min_len: 26,
        req_flags: REQ_HYPHEN,
        skip_in_tool_output: false,
    },
    // 10: Bitbucket Token (`ATBB` + 32+)
    PatternMeta {
        min_len: 36,
        req_flags: REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 11: CircleCI Token (`circle-token` + `[=:]` + 40)
    PatternMeta {
        min_len: 53,
        req_flags: REQ_HYPHEN | REQ_COLON_OR_EQ,
        skip_in_tool_output: false,
    },
    // 12: Travis CI Token (`travis-token` + `[=:]` + 22)
    PatternMeta {
        min_len: 35,
        req_flags: REQ_HYPHEN | REQ_COLON_OR_EQ,
        skip_in_tool_output: false,
    },
    // 13: Heroku API Key (`heroku...key=` + 36)
    PatternMeta {
        min_len: 46,
        req_flags: REQ_HYPHEN | REQ_COLON_OR_EQ,
        skip_in_tool_output: false,
    },
    // 14: Vercel Token (`vercel_` + 24)
    PatternMeta {
        min_len: 31,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 15: Netlify Token (`netlify_` + 40+)
    PatternMeta {
        min_len: 48,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 16: Stripe Secret Key (`[sr]k_live_` + 20+)
    PatternMeta {
        min_len: 28,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 17: Stripe Publishable Key (`pk_live_` + 20+)
    PatternMeta {
        min_len: 28,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 18: Stripe Restricted Key (`rk_live_` + 20+)
    PatternMeta {
        min_len: 28,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 19: PayPal Token (`access_token$production$` + 16 + `$` + 32)
    PatternMeta {
        min_len: 73,
        req_flags: REQ_UNDERSCORE | REQ_DOLLAR,
        skip_in_tool_output: false,
    },
    // 20: Square Access Token (`sq0atp-` + 22)
    PatternMeta {
        min_len: 29,
        req_flags: REQ_HYPHEN | REQ_DIGIT,
        skip_in_tool_output: false,
    },
    // 21: Square OAuth Secret (`sq0csp-` + 43)
    PatternMeta {
        min_len: 50,
        req_flags: REQ_HYPHEN | REQ_DIGIT,
        skip_in_tool_output: false,
    },
    // 22: Slack Token (`xox[bpas]-` + 10+ digits + `-` + 1+)
    PatternMeta {
        min_len: 17,
        req_flags: REQ_HYPHEN | REQ_DIGIT,
        skip_in_tool_output: false,
    },
    // 23: Slack Webhook (`https://hooks.slack.com/services/T.../B.../...`)
    PatternMeta {
        min_len: 39,
        req_flags: REQ_COLON | REQ_SLASH | REQ_DOT | REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 24: Discord Token (`[MN]` + 23+ + `.` + 6 + `.` + 27+)
    PatternMeta {
        min_len: 59,
        req_flags: REQ_UPPER | REQ_DOT,
        skip_in_tool_output: false,
    },
    // 25: Twilio API Key (`SK` + 32)
    PatternMeta {
        min_len: 34,
        req_flags: REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 26: SendGrid API Key (`SG.` + 22 + `.` + 43)
    PatternMeta {
        min_len: 69,
        req_flags: REQ_UPPER | REQ_DOT,
        skip_in_tool_output: false,
    },
    // 27: Mailgun API Key (`key-` + 32, context `mailgun`)
    PatternMeta {
        min_len: 36,
        req_flags: REQ_HYPHEN,
        skip_in_tool_output: false,
    },
    // 28: OpenAI API Key (`sk-` + 20 + `T3BlbkFJ` + 20)
    PatternMeta {
        min_len: 51,
        req_flags: REQ_HYPHEN | REQ_UPPER | REQ_DIGIT,
        skip_in_tool_output: false,
    },
    // 29: OpenAI Project Key (`sk-proj-` + 40+)
    PatternMeta {
        min_len: 48,
        req_flags: REQ_HYPHEN,
        skip_in_tool_output: false,
    },
    // 30: Anthropic API Key (`sk-ant-` + 40+)
    PatternMeta {
        min_len: 47,
        req_flags: REQ_HYPHEN,
        skip_in_tool_output: false,
    },
    // 31: HuggingFace Token (`hf_` + 34)
    PatternMeta {
        min_len: 37,
        req_flags: REQ_UNDERSCORE,
        skip_in_tool_output: false,
    },
    // 32: Database URL (`(postgres|mysql|mongodb|redis|amqp)://...@...`)
    PatternMeta {
        min_len: 10,
        req_flags: REQ_COLON | REQ_SLASH | REQ_AT,
        skip_in_tool_output: false,
    },
    // 33: JDBC Connection (`jdbc:[a-z]+://...`)
    PatternMeta {
        min_len: 10,
        req_flags: REQ_COLON | REQ_SLASH,
        skip_in_tool_output: false,
    },
    // 34: Firebase URL (`https://[a-z0-9-]+\.firebaseio\.com`)
    PatternMeta {
        min_len: 24,
        req_flags: REQ_COLON | REQ_SLASH | REQ_DOT,
        skip_in_tool_output: false,
    },
    // 35: Firebase Key (`AAAA` + 7 + `:` + 140)
    PatternMeta {
        min_len: 152,
        req_flags: REQ_UPPER | REQ_COLON,
        skip_in_tool_output: false,
    },
    // 36: RSA Private Key
    PatternMeta {
        min_len: 31,
        req_flags: REQ_HYPHEN | REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 37: DSA Private Key
    PatternMeta {
        min_len: 31,
        req_flags: REQ_HYPHEN | REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 38: EC Private Key
    PatternMeta {
        min_len: 30,
        req_flags: REQ_HYPHEN | REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 39: OpenSSH Private Key
    PatternMeta {
        min_len: 35,
        req_flags: REQ_HYPHEN | REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 40: PGP Private Key
    PatternMeta {
        min_len: 37,
        req_flags: REQ_HYPHEN | REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 41: Generic Private Key
    PatternMeta {
        min_len: 27,
        req_flags: REQ_HYPHEN | REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 42: Bearer Token (`Bearer\s+` + 20+)
    PatternMeta {
        min_len: 27,
        req_flags: REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 43: Basic Auth Header (`Basic\s+` + 20+)
    PatternMeta {
        min_len: 26,
        req_flags: REQ_UPPER,
        skip_in_tool_output: false,
    },
    // 44: JWT Token (`eyJ` + 10+ + `.eyJ` + 10+ + `.` + 10+)
    PatternMeta {
        min_len: 38,
        req_flags: REQ_UPPER | REQ_DOT,
        skip_in_tool_output: false,
    },
    // 45: Hex Secret (32+) (`pwd=` + 32+)
    PatternMeta {
        min_len: 36,
        req_flags: REQ_COLON_OR_EQ,
        skip_in_tool_output: false,
    },
    // 46: Base64 Secret (`pwd=` + 40+)
    PatternMeta {
        min_len: 44,
        req_flags: REQ_COLON_OR_EQ,
        skip_in_tool_output: false,
    },
    // 47: Home Directory (`/home/` + 1+)
    PatternMeta {
        min_len: 7,
        req_flags: REQ_SLASH,
        skip_in_tool_output: true,
    },
    // 48: Email Address (min 6 bytes)
    PatternMeta {
        min_len: 6,
        req_flags: REQ_AT | REQ_DOT,
        skip_in_tool_output: true,
    },
    // 49: IPv4 Address (`0.0.0.0`)
    PatternMeta {
        min_len: 7,
        req_flags: REQ_DIGIT | REQ_DOT,
        skip_in_tool_output: true,
    },
    // 50: SSH Connection (`ssh a@b`)
    PatternMeta {
        min_len: 7,
        req_flags: REQ_AT,
        skip_in_tool_output: false,
    },
];

/// Accumulates redaction match counts across one or more strings while preserving first-seen
/// pattern insertion order so `into_sorted_redactions()` matches Ruby's
/// `@redaction_counts.sort_by { |_, count| -count }` tie-breaking semantics.
#[derive(Clone, Debug)]
pub struct RedactionAccumulator {
    counts: [usize; NUM_PATTERNS],
    insertion_order: Vec<usize>,
}

impl Default for RedactionAccumulator {
    fn default() -> Self {
        Self::new()
    }
}

impl RedactionAccumulator {
    #[inline]
    pub fn new() -> Self {
        Self {
            counts: [0; NUM_PATTERNS],
            insertion_order: Vec::new(),
        }
    }

    #[inline]
    pub fn record(&mut self, pattern_idx: usize, match_count: usize) {
        if match_count == 0 {
            return;
        }
        if self.counts[pattern_idx] == 0 {
            self.insertion_order.push(pattern_idx);
        }
        self.counts[pattern_idx] += match_count;
    }

    #[inline]
    pub fn is_empty(&self) -> bool {
        self.insertion_order.is_empty()
    }

    /// Returns `(pattern_name, match_count)` pairs in exact first-seen insertion order.
    pub fn into_counts(self) -> Vec<(&'static str, usize)> {
        self.insertion_order
            .into_iter()
            .map(|idx| (PATTERN_NAMES[idx], self.counts[idx]))
            .collect()
    }

    /// Returns `(pattern_name, match_count)` pairs sorted descending by `match_count`,
    /// preserving first-seen insertion order for ties.
    pub fn into_sorted_redactions(mut self) -> Vec<(&'static str, usize)> {
        self.insertion_order
            .sort_by_key(|&idx| std::cmp::Reverse(self.counts[idx]));
        self.insertion_order
            .into_iter()
            .map(|idx| (PATTERN_NAMES[idx], self.counts[idx]))
            .collect()
    }
}

/// A `(pattern_name, match_count)` pair returned by redaction primitives.
pub type RedactionCount = (&'static str, usize);

/// Scrubs a single string across all 51 `SensitiveDataScrubber::PATTERNS`, returning the
/// scrubbed string (or `Cow::Borrowed(text)` when nothing matched), or `None` if an input
/// encounters a non-ASCII boundary that should defer to Ruby's Onigmo engine.
pub fn scrub_sensitive_text(text: &str, tool_output: bool) -> Option<Cow<'_, str>> {
    let mut acc = RedactionAccumulator::new();
    scrub_sensitive_text_into_accumulator(text, tool_output, &mut acc)
}

/// Scrubs a single string and returns `(scrubbed_text, redaction_counts)` where `redaction_counts`
/// lists `(pattern_name, count)` in the exact `PATTERNS` execution order for patterns that matched.
pub fn scrub_sensitive_text_with_counts(
    text: &str,
    tool_output: bool,
) -> Option<(Cow<'_, str>, Vec<RedactionCount>)> {
    let mut acc = RedactionAccumulator::new();
    let scrubbed = scrub_sensitive_text_into_accumulator(text, tool_output, &mut acc)?;
    let counts = acc
        .insertion_order
        .into_iter()
        .map(|idx| (PATTERN_NAMES[idx], acc.counts[idx]))
        .collect();
    Some((scrubbed, counts))
}

/// Scrubs `text` and records any redaction counts into `acc` in pattern execution order.
pub fn scrub_sensitive_text_into_accumulator<'a>(
    text: &'a str,
    tool_output: bool,
    acc: &mut RedactionAccumulator,
) -> Option<Cow<'a, str>> {
    if text.len() < 6 {
        return Some(Cow::Borrowed(text));
    }

    let mut current: Cow<'a, str> = Cow::Borrowed(text);
    let mut flags = compute_text_flags(current.as_bytes());
    if flags == 0 {
        return Some(current);
    }

    for (idx, meta) in PATTERN_META.iter().enumerate() {
        if tool_output && meta.skip_in_tool_output {
            continue;
        }
        let bytes = current.as_bytes();
        if bytes.len() < meta.min_len || (flags & meta.req_flags) != meta.req_flags {
            continue;
        }

        if let Some((replaced, count)) = apply_pattern(idx, &current)? {
            acc.record(idx, count);
            current = Cow::Owned(replaced);
            flags = compute_text_flags(current.as_bytes());
        }
    }

    Some(current)
}

#[inline]
fn compute_text_flags(bytes: &[u8]) -> u16 {
    let mut flags = 0u16;
    for &b in bytes {
        match b {
            b'_' => flags |= REQ_UNDERSCORE,
            b'-' => flags |= REQ_HYPHEN,
            b':' => flags |= REQ_COLON | REQ_COLON_OR_EQ | REQ_AWS_DELIM,
            b'=' => flags |= REQ_COLON_OR_EQ | REQ_AWS_DELIM,
            b'@' => flags |= REQ_AT,
            b'.' => flags |= REQ_DOT,
            b'/' | b'\\' => flags |= REQ_SLASH,
            b'$' => flags |= REQ_DOLLAR,
            b'"' => flags |= REQ_QUOTE | REQ_AWS_DELIM,
            b'\'' | b'\t'..=b'\r' | b' ' => flags |= REQ_AWS_DELIM,
            b'A'..=b'Z' => flags |= REQ_UPPER,
            b'0'..=b'9' => flags |= REQ_DIGIT,
            _ => {}
        }
    }
    flags
}

#[inline]
fn is_ascii_space(b: u8) -> bool {
    matches!(b, b'\t' | b'\n' | 0x0b | 0x0c | b'\r' | b' ')
}

#[inline]
fn is_upper_or_digit(b: u8) -> bool {
    b.is_ascii_uppercase() || b.is_ascii_digit()
}

#[inline]
fn is_lower_or_digit(b: u8) -> bool {
    b.is_ascii_lowercase() || b.is_ascii_digit()
}

#[inline]
fn is_lower_hex(b: u8) -> bool {
    b.is_ascii_digit() || matches!(b, b'a'..=b'f')
}

#[inline]
fn is_ascii_word(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'_'
}

#[inline]
fn is_alnum_dash_underscore(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'-' | b'_')
}

#[inline]
fn is_db_url_char(b: u8) -> bool {
    !is_ascii_space(b) && !matches!(b, b'"' | b'\'' | b'`' | b'<' | b'>')
}

#[inline]
fn count_while<F: Fn(u8) -> bool>(bytes: &[u8], start: usize, pred: F) -> usize {
    bytes[start..].iter().take_while(|&&b| pred(b)).count()
}

#[inline]
fn check_exact<F: Fn(u8) -> bool>(bytes: &[u8], start: usize, len: usize, pred: F) -> bool {
    bytes
        .get(start..start + len)
        .is_some_and(|slice| slice.iter().all(|&b| pred(b)))
}

/// Checks `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` (36 bytes).
fn match_uuid(bytes: &[u8], start: usize, allow_uppercase: bool) -> bool {
    let Some(s) = bytes.get(start..start + 36) else {
        return false;
    };
    if s[8] != b'-' || s[13] != b'-' || s[18] != b'-' || s[23] != b'-' {
        return false;
    }
    let is_hex = |b: u8| {
        if allow_uppercase {
            b.is_ascii_hexdigit()
        } else {
            is_lower_hex(b)
        }
    };
    s[0..8].iter().all(|&b| is_hex(b))
        && s[9..13].iter().all(|&b| is_hex(b))
        && s[14..18].iter().all(|&b| is_hex(b))
        && s[19..23].iter().all(|&b| is_hex(b))
        && s[24..36].iter().all(|&b| is_hex(b))
}

/// Context check `/aws[_\s]?secret/i` for Pattern 1 ("AWS Secret Key").
fn has_aws_secret_context(bytes: &[u8]) -> bool {
    if bytes.len() < 9 {
        return false;
    }
    let mut i = 0;
    while i + 9 <= bytes.len() {
        if bytes[i..i + 3].eq_ignore_ascii_case(b"aws") {
            if bytes[i + 3..i + 9].eq_ignore_ascii_case(b"secret") {
                return true;
            }
            if i + 10 <= bytes.len()
                && (bytes[i + 3] == b'_' || is_ascii_space(bytes[i + 3]))
                && bytes[i + 4..i + 10].eq_ignore_ascii_case(b"secret")
            {
                return true;
            }
        }
        i += 1;
    }
    false
}

/// Context check `/mailgun/i` for Pattern 27 ("Mailgun API Key").
fn has_mailgun_context(bytes: &[u8]) -> bool {
    bytes.windows(7).any(|w| w.eq_ignore_ascii_case(b"mailgun"))
}

/// Applies a single pattern across `text`, returning:
/// - `Some(None)` if the pattern did not match anywhere in `text`
/// - `Some(Some((replaced_string, match_count)))` if the pattern matched 1+ times
/// - `None` if an out-of-domain non-ASCII word boundary was encountered (defer to Ruby).
fn apply_pattern(pattern_idx: usize, text: &str) -> Option<Option<(String, usize)>> {
    let bytes = text.as_bytes();

    if pattern_idx == 1 && !has_aws_secret_context(bytes) {
        return Some(None);
    }
    if pattern_idx == 27 && !has_mailgun_context(bytes) {
        return Some(None);
    }

    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut count = 0usize;
    let mut pos = 0usize;

    while let Some((match_start, match_end)) = find_next_match(pattern_idx, bytes, pos)? {
        let buf = out.get_or_insert_with(|| String::with_capacity(text.len()));
        buf.push_str(&text[last_copied..match_start]);
        buf.push_str(REDACTED_LABEL);
        count += 1;
        last_copied = match_end;
        pos = match_end;
    }

    match out {
        None => Some(None),
        Some(mut s) => {
            s.push_str(&text[last_copied..]);
            Some(Some((s, count)))
        }
    }
}

/// Finds the leftmost match `(match_start, match_end)` of `pattern_idx` in `bytes` with
/// `match_start >= pos`. Returns `None` at the outer `Option` only when deferring to Ruby.
fn find_next_match(
    pattern_idx: usize,
    bytes: &[u8],
    mut pos: usize,
) -> Option<Option<(usize, usize)>> {
    let min_len = PATTERN_META[pattern_idx].min_len;
    if pos + min_len > bytes.len() {
        return Some(None);
    }

    // Specialized `@`-driven scanner for Pattern 48 ("Email Address").
    if pattern_idx == 48 {
        return find_next_email_match(bytes, pos);
    }

    while pos + min_len <= bytes.len() {
        let Some(cand) = advance_to_candidate(pattern_idx, bytes, pos) else {
            return Some(None);
        };
        if cand + min_len > bytes.len() {
            return Some(None);
        }
        if let Some(match_end) = match_pattern_at(pattern_idx, bytes, cand)? {
            return Some(Some((cand, match_end)));
        }
        pos = cand + 1;
    }

    Some(None)
}

#[inline]
fn advance_to_candidate(pattern_idx: usize, bytes: &[u8], pos: usize) -> Option<usize> {
    let rem = &bytes[pos..];
    let rel = match pattern_idx {
        0 | 4 | 10 | 35 => rem.iter().position(|&b| b == b'A')?,
        1 => rem
            .iter()
            .position(|&b| b.is_ascii_alphanumeric() || matches!(b, b'/' | b'+' | b'='))?,
        2 | 19 => rem.iter().position(|&b| b == b'a')?,
        3 => rem.iter().position(|&b| b == b'd')?,
        5 => rem.iter().position(|&b| b == b'y')?,
        6 => rem.iter().position(|&b| b == b'"')?,
        7..=9 => rem.iter().position(|&b| b == b'g')?,
        11 => rem.iter().position(|&b| b == b'c')?,
        12 => rem.iter().position(|&b| b == b't')?,
        13 => rem.iter().position(|&b| matches!(b, b'h' | b'H'))?,
        14 => rem.iter().position(|&b| b == b'v')?,
        15 => rem.iter().position(|&b| b == b'n')?,
        16 => rem.iter().position(|&b| matches!(b, b's' | b'r'))?,
        17 => rem.iter().position(|&b| b == b'p')?,
        18 => rem.iter().position(|&b| b == b'r')?,
        20 | 21 | 28..=30 | 50 => rem.iter().position(|&b| b == b's')?,
        22 => rem.iter().position(|&b| b == b'x')?,
        23 | 31 | 34 => rem.iter().position(|&b| b == b'h')?,
        24 => rem.iter().position(|&b| matches!(b, b'M' | b'N'))?,
        25 | 26 => rem.iter().position(|&b| b == b'S')?,
        27 => rem.iter().position(|&b| b == b'k')?,
        32 => rem
            .iter()
            .position(|&b| matches!(b, b'p' | b'm' | b'r' | b'a'))?,
        33 => rem.iter().position(|&b| b == b'j')?,
        36..=41 => rem.iter().position(|&b| b == b'-')?,
        42 | 43 => rem.iter().position(|&b| b == b'B')?,
        44 => rem.iter().position(|&b| b == b'e')?,
        45 | 46 => rem.iter().position(|&b| {
            matches!(
                b,
                b's' | b'S' | b't' | b'T' | b'k' | b'K' | b'p' | b'P' | b'a' | b'A'
            )
        })?,
        47 => rem.iter().position(|&b| matches!(b, b'/' | b'c' | b'C'))?,
        49 => rem.iter().position(|&b| b.is_ascii_digit())?,
        _ => 0,
    };
    Some(pos + rel)
}

/// Checks whether `pattern_idx` matches starting at `pos`.
/// Returns:
/// - `Some(Some(end_pos))` if matched
/// - `Some(None)` if not matched at `pos`
/// - `None` if deferring to Ruby (only possible on non-ASCII boundaries in IPv4/Email).
#[inline]
fn match_pattern_at(pattern_idx: usize, bytes: &[u8], pos: usize) -> Option<Option<usize>> {
    if pattern_idx == 49 {
        return match_ipv4_at(bytes, pos);
    }
    Some(match_simple_pattern_at(pattern_idx, bytes, pos))
}

fn match_simple_pattern_at(pattern_idx: usize, bytes: &[u8], pos: usize) -> Option<usize> {
    let rem = &bytes[pos..];
    match pattern_idx {
        // 0: /(?<![A-Z0-9])(A3T[A-Z0-9]|AKIA|AGPA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])/
        0 => {
            if pos > 0 && is_upper_or_digit(bytes[pos - 1]) {
                return None;
            }
            if rem.len() < 20 {
                return None;
            }
            let prefix_ok = matches!(
                &rem[..4],
                b"AKIA" | b"AGPA" | b"AROA" | b"AIPA" | b"ANPA" | b"ANVA" | b"ASIA"
            ) || (&rem[..3] == b"A3T" && is_upper_or_digit(rem[3]));
            if !prefix_ok || !rem[4..20].iter().all(|&b| is_upper_or_digit(b)) {
                return None;
            }
            if rem.get(20).is_some_and(|&b| is_upper_or_digit(b)) {
                return None;
            }
            Some(pos + 20)
        }

        // 1: %r{(?<=[\s:='"])[A-Za-z0-9/+=]{40}(?=[\s'"&])}
        1 => {
            if pos == 0 {
                return None;
            }
            let prev = bytes[pos - 1];
            if !(is_ascii_space(prev) || matches!(prev, b':' | b'=' | b'\'' | b'"')) {
                return None;
            }
            if !check_exact(bytes, pos, 40, |b| {
                b.is_ascii_alphanumeric() || matches!(b, b'/' | b'+' | b'=')
            }) {
                return None;
            }
            let next = *bytes.get(pos + 40)?;
            if !(is_ascii_space(next) || matches!(next, b'\'' | b'"' | b'&')) {
                return None;
            }
            Some(pos + 40)
        }

        // 2: /amzn\.mws\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
        2 => {
            (rem.starts_with(b"amzn.mws.") && match_uuid(bytes, pos + 9, false)).then_some(pos + 45)
        }

        // 3: /da2-[a-z0-9]{26}/
        3 => (rem.starts_with(b"da2-") && check_exact(bytes, pos + 4, 26, is_lower_or_digit))
            .then_some(pos + 30),

        // 4: /AIza[0-9A-Za-z\-_]{35}/
        4 => (rem.starts_with(b"AIza")
            && check_exact(bytes, pos + 4, 35, is_alnum_dash_underscore))
        .then_some(pos + 39),

        // 5: /ya29\.[0-9A-Za-z\-_]+/
        5 => {
            if !rem.starts_with(b"ya29.") {
                return None;
            }
            let n = count_while(bytes, pos + 5, is_alnum_dash_underscore);
            (n >= 1).then_some(pos + 5 + n)
        }

        // 6: /"type"\s*:\s*"service_account"/
        6 => {
            if !rem.starts_with(b"\"type\"") {
                return None;
            }
            let mut cur = pos + 6;
            cur += count_while(bytes, cur, is_ascii_space);
            if bytes.get(cur) != Some(&b':') {
                return None;
            }
            cur += 1;
            cur += count_while(bytes, cur, is_ascii_space);
            bytes[cur..]
                .starts_with(b"\"service_account\"")
                .then_some(cur + 17)
        }

        // 7: /(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}/
        7 => {
            if !matches!(
                rem.get(..4),
                Some(b"ghp_" | b"gho_" | b"ghu_" | b"ghs_" | b"ghr_")
            ) {
                return None;
            }
            let n = count_while(bytes, pos + 4, is_ascii_word);
            (n >= 36).then_some(pos + 4 + n)
        }

        // 8: /github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9_]{59,}/
        8 => {
            if !rem.starts_with(b"github_pat_")
                || !check_exact(bytes, pos + 11, 22, |b| b.is_ascii_alphanumeric())
                || bytes.get(pos + 33) != Some(&b'_')
            {
                return None;
            }
            let n = count_while(bytes, pos + 34, is_ascii_word);
            (n >= 59).then_some(pos + 34 + n)
        }

        // 9: /glpat-[A-Za-z0-9\-_]{20,}/
        9 => {
            if !rem.starts_with(b"glpat-") {
                return None;
            }
            let n = count_while(bytes, pos + 6, is_alnum_dash_underscore);
            (n >= 20).then_some(pos + 6 + n)
        }

        // 10: /ATBB[A-Za-z0-9]{32,}/
        10 => {
            if !rem.starts_with(b"ATBB") {
                return None;
            }
            let n = count_while(bytes, pos + 4, |b| b.is_ascii_alphanumeric());
            (n >= 32).then_some(pos + 4 + n)
        }

        // 11: /circle-token\s*[=:]\s*[A-Za-z0-9]{40}/
        11 => {
            if !rem.starts_with(b"circle-token") {
                return None;
            }
            let cur = match_assign_sep(bytes, pos + 12)?;
            check_exact(bytes, cur, 40, |b| b.is_ascii_alphanumeric()).then_some(cur + 40)
        }

        // 12: /travis-token\s*[=:]\s*[A-Za-z0-9]{22}/
        12 => {
            if !rem.starts_with(b"travis-token") {
                return None;
            }
            let cur = match_assign_sep(bytes, pos + 12)?;
            check_exact(bytes, cur, 22, |b| b.is_ascii_alphanumeric()).then_some(cur + 22)
        }

        // 13: /(?:heroku[_\s-]*(?:api[_\s-]*)?key|heroku[_\s-]*token)\s*[=:]\s*["']?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}["']?/i
        13 => match_heroku_api_key(bytes, pos),

        // 14: /vercel_[A-Za-z0-9]{24}/
        14 => (rem.starts_with(b"vercel_")
            && check_exact(bytes, pos + 7, 24, |b| b.is_ascii_alphanumeric()))
        .then_some(pos + 31),

        // 15: /netlify_[A-Za-z0-9]{40,}/
        15 => {
            if !rem.starts_with(b"netlify_") {
                return None;
            }
            let n = count_while(bytes, pos + 8, |b| b.is_ascii_alphanumeric());
            (n >= 40).then_some(pos + 8 + n)
        }

        // 16: /[sr]k_live_[A-Za-z0-9]{20,}/
        16 => {
            if !(rem.starts_with(b"sk_live_") || rem.starts_with(b"rk_live_")) {
                return None;
            }
            let n = count_while(bytes, pos + 8, |b| b.is_ascii_alphanumeric());
            (n >= 20).then_some(pos + 8 + n)
        }

        // 17: /pk_live_[A-Za-z0-9]{20,}/
        17 => {
            if !rem.starts_with(b"pk_live_") {
                return None;
            }
            let n = count_while(bytes, pos + 8, |b| b.is_ascii_alphanumeric());
            (n >= 20).then_some(pos + 8 + n)
        }

        // 18: /rk_live_[A-Za-z0-9]{20,}/
        18 => {
            if !rem.starts_with(b"rk_live_") {
                return None;
            }
            let n = count_while(bytes, pos + 8, |b| b.is_ascii_alphanumeric());
            (n >= 20).then_some(pos + 8 + n)
        }

        // 19: /access_token\$production\$[A-Za-z0-9]{16}\$[A-Za-z0-9]{32}/
        19 => (rem.starts_with(b"access_token$production$")
            && check_exact(bytes, pos + 24, 16, |b| b.is_ascii_alphanumeric())
            && bytes.get(pos + 40) == Some(&b'$')
            && check_exact(bytes, pos + 41, 32, |b| b.is_ascii_alphanumeric()))
        .then_some(pos + 73),

        // 20: /sq0atp-[A-Za-z0-9\-_]{22}/
        20 => (rem.starts_with(b"sq0atp-")
            && check_exact(bytes, pos + 7, 22, is_alnum_dash_underscore))
        .then_some(pos + 29),

        // 21: /sq0csp-[A-Za-z0-9\-_]{43}/
        21 => (rem.starts_with(b"sq0csp-")
            && check_exact(bytes, pos + 7, 43, is_alnum_dash_underscore))
        .then_some(pos + 50),

        // 22: /xox[bpas]-[0-9]{10,}-[A-Za-z0-9\-]+/
        22 => {
            if !rem.starts_with(b"xox")
                || !matches!(rem.get(3), Some(b'b' | b'p' | b'a' | b's'))
                || rem.get(4) != Some(&b'-')
            {
                return None;
            }
            let digits = count_while(bytes, pos + 5, |b| b.is_ascii_digit());
            if digits < 10 {
                return None;
            }
            let dash_pos = pos + 5 + digits;
            if bytes.get(dash_pos) != Some(&b'-') {
                return None;
            }
            let tail = count_while(bytes, dash_pos + 1, |b| {
                b.is_ascii_alphanumeric() || b == b'-'
            });
            (tail >= 1).then_some(dash_pos + 1 + tail)
        }

        // 23: %r{https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+}
        23 => {
            const PREFIX: &[u8] = b"https://hooks.slack.com/services/T";
            if !rem.starts_with(PREFIX) {
                return None;
            }
            let mut cur = pos + PREFIX.len();
            let t_len = count_while(bytes, cur, is_upper_or_digit);
            if t_len == 0 {
                return None;
            }
            cur += t_len;
            if !bytes[cur..].starts_with(b"/B") {
                return None;
            }
            cur += 2;
            let b_len = count_while(bytes, cur, is_upper_or_digit);
            if b_len == 0 {
                return None;
            }
            cur += b_len;
            if bytes.get(cur) != Some(&b'/') {
                return None;
            }
            cur += 1;
            let s_len = count_while(bytes, cur, |b| b.is_ascii_alphanumeric());
            (s_len >= 1).then_some(cur + s_len)
        }

        // 24: /[MN][A-Za-z\d]{23,}\.[\w-]{6}\.[\w-]{27,}/
        24 => {
            if !matches!(rem.first(), Some(b'M' | b'N')) {
                return None;
            }
            let part1 = count_while(bytes, pos + 1, |b| b.is_ascii_alphanumeric());
            if part1 < 23 {
                return None;
            }
            let dot1 = pos + 1 + part1;
            if bytes.get(dot1) != Some(&b'.')
                || !check_exact(bytes, dot1 + 1, 6, is_alnum_dash_underscore)
                || bytes.get(dot1 + 7) != Some(&b'.')
            {
                return None;
            }
            let part3 = count_while(bytes, dot1 + 8, is_alnum_dash_underscore);
            (part3 >= 27).then_some(dot1 + 8 + part3)
        }

        // 25: /SK[a-f0-9]{32}/
        25 => (rem.starts_with(b"SK") && check_exact(bytes, pos + 2, 32, is_lower_hex))
            .then_some(pos + 34),

        // 26: /SG\.[A-Za-z0-9\-_]{22}\.[A-Za-z0-9\-_]{43}/
        26 => (rem.starts_with(b"SG.")
            && check_exact(bytes, pos + 3, 22, is_alnum_dash_underscore)
            && bytes.get(pos + 25) == Some(&b'.')
            && check_exact(bytes, pos + 26, 43, is_alnum_dash_underscore))
        .then_some(pos + 69),

        // 27: /key-[A-Za-z0-9]{32}/ (context checked in apply_pattern)
        27 => (rem.starts_with(b"key-")
            && check_exact(bytes, pos + 4, 32, |b| b.is_ascii_alphanumeric()))
        .then_some(pos + 36),

        // 28: /sk-[A-Za-z0-9]{20}T3BlbkFJ[A-Za-z0-9]{20}/
        28 => (rem.starts_with(b"sk-")
            && check_exact(bytes, pos + 3, 20, |b| b.is_ascii_alphanumeric())
            && bytes.get(pos + 23..pos + 31) == Some(b"T3BlbkFJ")
            && check_exact(bytes, pos + 31, 20, |b| b.is_ascii_alphanumeric()))
        .then_some(pos + 51),

        // 29: /sk-proj-[A-Za-z0-9\-_]{40,}/
        29 => {
            if !rem.starts_with(b"sk-proj-") {
                return None;
            }
            let n = count_while(bytes, pos + 8, is_alnum_dash_underscore);
            (n >= 40).then_some(pos + 8 + n)
        }

        // 30: /sk-ant-[A-Za-z0-9\-_]{40,}/
        30 => {
            if !rem.starts_with(b"sk-ant-") {
                return None;
            }
            let n = count_while(bytes, pos + 7, is_alnum_dash_underscore);
            (n >= 40).then_some(pos + 7 + n)
        }

        // 31: /hf_[A-Za-z0-9]{34}/
        31 => (rem.starts_with(b"hf_")
            && check_exact(bytes, pos + 3, 34, |b| b.is_ascii_alphanumeric()))
        .then_some(pos + 37),

        // 32: %r{(postgres|mysql|mongodb|redis|amqp)://[^\s"'`<>]+@[^\s"'`<>]+}
        32 => {
            let scheme_len = if rem.starts_with(b"postgres://") {
                11
            } else if rem.starts_with(b"mongodb://") {
                10
            } else if rem.starts_with(b"mysql://") || rem.starts_with(b"redis://") {
                8
            } else if rem.starts_with(b"amqp://") {
                7
            } else {
                return None;
            };
            let after_scheme = pos + scheme_len;
            let run_len = count_while(bytes, after_scheme, is_db_url_char);
            if run_len < 3 {
                return None;
            }
            let run = &bytes[after_scheme..after_scheme + run_len];
            run[1..run_len - 1]
                .contains(&b'@')
                .then_some(after_scheme + run_len)
        }

        // 33: %r{jdbc:[a-z]+://[^\s"'`<>]+}
        33 => {
            if !rem.starts_with(b"jdbc:") {
                return None;
            }
            let sub_len = count_while(bytes, pos + 5, |b| b.is_ascii_lowercase());
            if sub_len == 0 {
                return None;
            }
            let sep = pos + 5 + sub_len;
            if !bytes[sep..].starts_with(b"://") {
                return None;
            }
            let rest_len = count_while(bytes, sep + 3, is_db_url_char);
            (rest_len >= 1).then_some(sep + 3 + rest_len)
        }

        // 34: %r{https://[a-z0-9-]+\.firebaseio\.com}
        34 => {
            if !rem.starts_with(b"https://") {
                return None;
            }
            let sub_len = count_while(bytes, pos + 8, |b| is_lower_or_digit(b) || b == b'-');
            if sub_len == 0 {
                return None;
            }
            let end_sub = pos + 8 + sub_len;
            bytes[end_sub..]
                .starts_with(b".firebaseio.com")
                .then_some(end_sub + 15)
        }

        // 35: /AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}/
        35 => (rem.starts_with(b"AAAA")
            && check_exact(bytes, pos + 4, 7, is_alnum_dash_underscore)
            && bytes.get(pos + 11) == Some(&b':')
            && check_exact(bytes, pos + 12, 140, is_alnum_dash_underscore))
        .then_some(pos + 152),

        // 36..=41: Private key PEM headers
        36 => starts_with_pem_header(rem, b"RSA PRIVATE KEY").map(|n| pos + n),
        37 => starts_with_pem_header(rem, b"DSA PRIVATE KEY").map(|n| pos + n),
        38 => starts_with_pem_header(rem, b"EC PRIVATE KEY").map(|n| pos + n),
        39 => starts_with_pem_header(rem, b"OPENSSH PRIVATE KEY").map(|n| pos + n),
        40 => starts_with_pem_header(rem, b"PGP PRIVATE KEY BLOCK").map(|n| pos + n),
        41 => starts_with_pem_header(rem, b"PRIVATE KEY").map(|n| pos + n),

        // 42: /Bearer\s+[A-Za-z0-9\-_\.]{20,}/
        42 => {
            if !rem.starts_with(b"Bearer") {
                return None;
            }
            let ws = count_while(bytes, pos + 6, is_ascii_space);
            if ws == 0 {
                return None;
            }
            let tok_start = pos + 6 + ws;
            let tok_len = count_while(bytes, tok_start, |b| {
                is_alnum_dash_underscore(b) || b == b'.'
            });
            (tok_len >= 20).then_some(tok_start + tok_len)
        }

        // 43: %r{Basic\s+[A-Za-z0-9+/=]{20,}}
        43 => {
            if !rem.starts_with(b"Basic") {
                return None;
            }
            let ws = count_while(bytes, pos + 5, is_ascii_space);
            if ws == 0 {
                return None;
            }
            let tok_start = pos + 5 + ws;
            let tok_len = count_while(bytes, tok_start, |b| {
                b.is_ascii_alphanumeric() || matches!(b, b'+' | b'/' | b'=')
            });
            (tok_len >= 20).then_some(tok_start + tok_len)
        }

        // 44: /eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/
        44 => {
            if !rem.starts_with(b"eyJ") {
                return None;
            }
            let p1 = count_while(bytes, pos + 3, is_alnum_dash_underscore);
            if p1 < 10 {
                return None;
            }
            let dot1 = pos + 3 + p1;
            if !bytes[dot1..].starts_with(b".eyJ") {
                return None;
            }
            let p2 = count_while(bytes, dot1 + 4, is_alnum_dash_underscore);
            if p2 < 10 {
                return None;
            }
            let dot2 = dot1 + 4 + p2;
            if bytes.get(dot2) != Some(&b'.') {
                return None;
            }
            let p3 = count_while(bytes, dot2 + 1, is_alnum_dash_underscore);
            (p3 >= 10).then_some(dot2 + 1 + p3)
        }

        // 45: /(?:secret|token|key|password|passwd|pwd|api_key|apikey|auth)\s*[=:]\s*["']?[A-Fa-f0-9]{32,}["']?/i
        45 => {
            let kw_end = match_secret_keyword(bytes, pos)?;
            let val_start = match_assign_sep(bytes, kw_end)?;
            let after_open_quote = if matches!(bytes.get(val_start), Some(b'"' | b'\'')) {
                val_start + 1
            } else {
                val_start
            };
            let hex_len = count_while(bytes, after_open_quote, |b| b.is_ascii_hexdigit());
            if hex_len < 32 {
                return None;
            }
            let end_hex = after_open_quote + hex_len;
            if matches!(bytes.get(end_hex), Some(b'"' | b'\'')) {
                Some(end_hex + 1)
            } else {
                Some(end_hex)
            }
        }

        // 46: %r{(?:secret|token|key|password|passwd|pwd|api_key|apikey|auth)\s*[=:]\s*["']?[A-Za-z0-9+/]{40,}={0,2}["']?}i
        46 => {
            let kw_end = match_secret_keyword(bytes, pos)?;
            let val_start = match_assign_sep(bytes, kw_end)?;
            let after_open_quote = if matches!(bytes.get(val_start), Some(b'"' | b'\'')) {
                val_start + 1
            } else {
                val_start
            };
            let b64_len = count_while(bytes, after_open_quote, |b| {
                b.is_ascii_alphanumeric() || matches!(b, b'+' | b'/')
            });
            if b64_len < 40 {
                return None;
            }
            let mut cur = after_open_quote + b64_len;
            let eq_len = count_while(bytes, cur, |b| b == b'=').min(2);
            cur += eq_len;
            if matches!(bytes.get(cur), Some(b'"' | b'\'')) {
                Some(cur + 1)
            } else {
                Some(cur)
            }
        }

        // 47: %r{(?:/Users/|/home/|C:\\Users\\)[A-Za-z0-9._-]+}i
        47 => {
            let pfx_len = if rem.len() >= 7 && rem[..7].eq_ignore_ascii_case(b"/users/") {
                7
            } else if rem.len() >= 6 && rem[..6].eq_ignore_ascii_case(b"/home/") {
                6
            } else if rem.len() >= 9 && rem[..9].eq_ignore_ascii_case(b"c:\\users\\") {
                9
            } else {
                return None;
            };
            let user_len = count_while(bytes, pos + pfx_len, |b| {
                is_alnum_dash_underscore(b) || b == b'.'
            });
            (user_len >= 1).then_some(pos + pfx_len + user_len)
        }

        // 50: /ssh\s+[A-Za-z0-9._-]+@[A-Za-z0-9._-]+/
        50 => {
            if !rem.starts_with(b"ssh") {
                return None;
            }
            let ws = count_while(bytes, pos + 3, is_ascii_space);
            if ws == 0 {
                return None;
            }
            let u_start = pos + 3 + ws;
            let u_len = count_while(bytes, u_start, |b| is_alnum_dash_underscore(b) || b == b'.');
            if u_len == 0 || bytes.get(u_start + u_len) != Some(&b'@') {
                return None;
            }
            let h_start = u_start + u_len + 1;
            let h_len = count_while(bytes, h_start, |b| is_alnum_dash_underscore(b) || b == b'.');
            (h_len >= 1).then_some(h_start + h_len)
        }

        _ => None,
    }
}

#[inline]
fn match_assign_sep(bytes: &[u8], start: usize) -> Option<usize> {
    let mut cur = start + count_while(bytes, start, is_ascii_space);
    if !matches!(bytes.get(cur), Some(b'=' | b':')) {
        return None;
    }
    cur += 1;
    cur += count_while(bytes, cur, is_ascii_space);
    Some(cur)
}

fn match_heroku_api_key(bytes: &[u8], pos: usize) -> Option<usize> {
    let rem = &bytes[pos..];
    if rem.len() < 46 || !rem[..6].eq_ignore_ascii_case(b"heroku") {
        return None;
    }
    let is_sep = |b: u8| b == b'_' || b == b'-' || is_ascii_space(b);
    let mut cur = pos + 6 + count_while(bytes, pos + 6, is_sep);

    if bytes
        .get(cur..cur + 3)
        .is_some_and(|s| s.eq_ignore_ascii_case(b"api"))
    {
        let after_api = cur + 3 + count_while(bytes, cur + 3, is_sep);
        if bytes
            .get(after_api..after_api + 3)
            .is_some_and(|s| s.eq_ignore_ascii_case(b"key"))
        {
            cur = after_api + 3;
        } else {
            return None;
        }
    } else if bytes
        .get(cur..cur + 3)
        .is_some_and(|s| s.eq_ignore_ascii_case(b"key"))
    {
        cur += 3;
    } else if bytes
        .get(cur..cur + 5)
        .is_some_and(|s| s.eq_ignore_ascii_case(b"token"))
    {
        cur += 5;
    } else {
        return None;
    }

    let val_start = match_assign_sep(bytes, cur)?;
    let uuid_start = if matches!(bytes.get(val_start), Some(b'"' | b'\'')) {
        val_start + 1
    } else {
        val_start
    };
    if !match_uuid(bytes, uuid_start, true) {
        return None;
    }
    let after_uuid = uuid_start + 36;
    if matches!(bytes.get(after_uuid), Some(b'"' | b'\'')) {
        Some(after_uuid + 1)
    } else {
        Some(after_uuid)
    }
}

fn match_secret_keyword(bytes: &[u8], pos: usize) -> Option<usize> {
    const KEYWORDS: [&[u8]; 9] = [
        b"password",
        b"api_key",
        b"apikey",
        b"secret",
        b"passwd",
        b"token",
        b"auth",
        b"key",
        b"pwd",
    ];
    let rem = &bytes[pos..];
    for kw in KEYWORDS {
        if rem.len() >= kw.len() && rem[..kw.len()].eq_ignore_ascii_case(kw) {
            return Some(pos + kw.len());
        }
    }
    None
}

#[inline]
fn starts_with_pem_header(rem: &[u8], label: &[u8]) -> Option<usize> {
    const PREFIX: &[u8] = b"-----BEGIN ";
    const SUFFIX: &[u8] = b"-----";
    let total = PREFIX.len() + label.len() + SUFFIX.len();
    (rem.len() >= total
        && rem.starts_with(PREFIX)
        && rem[PREFIX.len()..].starts_with(label)
        && rem[PREFIX.len() + label.len()..].starts_with(SUFFIX))
    .then_some(total)
}

#[inline]
fn is_email_local_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'.' | b'_' | b'%' | b'+' | b'-')
}

#[inline]
fn is_email_domain_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'.' | b'-')
}

/// `@`-driven scanner for Pattern 48 (`/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}\b/i`).
/// Returns `None` at the outer `Option` only if a non-ASCII byte directly touches an email
/// candidate boundary (deferring to Ruby's Unicode `\b`).
fn find_next_email_match(bytes: &[u8], pos: usize) -> Option<Option<(usize, usize)>> {
    let mut search_from = pos + 1;
    while search_from < bytes.len() {
        let Some(rel_at) = bytes[search_from..].iter().position(|&b| b == b'@') else {
            return Some(None);
        };
        let at_idx = search_from + rel_at;
        search_from = at_idx + 1;

        // Walk backwards over `[A-Za-z0-9._%+-]` up to `pos`.
        let mut run_start = at_idx;
        while run_start > pos && is_email_local_byte(bytes[run_start - 1]) {
            run_start -= 1;
        }
        if run_start == at_idx {
            continue;
        }
        if run_start > 0 && bytes[run_start - 1] >= 0x80 {
            return None;
        }

        // Find the leftmost `start` in `run_start..at_idx` where `\b` holds.
        let mut match_start = None;
        for cand_start in run_start..at_idx {
            let prev_word = cand_start > 0 && is_ascii_word(bytes[cand_start - 1]);
            let curr_word = is_ascii_word(bytes[cand_start]);
            if prev_word != curr_word {
                match_start = Some(cand_start);
                break;
            }
        }
        let Some(start) = match_start else {
            continue;
        };

        // Check domain part `[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b` after `at_idx`.
        let domain_start = at_idx + 1;
        let dom_len = count_while(bytes, domain_start, is_email_domain_byte);
        if dom_len < 4 {
            continue;
        }
        let dom_end = domain_start + dom_len;
        if dom_end < bytes.len() && bytes[dom_end] >= 0x80 {
            return None;
        }

        // Because `[A-Za-z0-9.-]+` is greedy, try the rightmost `.` in `(domain_start + 1)..dom_end` first.
        let mut matched_end = None;
        for dot_idx in (domain_start + 1..dom_end).rev() {
            if bytes[dot_idx] != b'.' {
                continue;
            }
            let tld_len = count_while(bytes, dot_idx + 1, |b| b.is_ascii_alphabetic());
            if tld_len < 2 {
                continue;
            }
            let tld_end = dot_idx + 1 + tld_len;
            if tld_end < bytes.len() && bytes[tld_end] >= 0x80 {
                return None;
            }
            // Since `bytes[tld_end - 1]` is `[A-Za-z]` (a word char), `\b` at `tld_end` holds iff
            // `bytes.get(tld_end)` is not an ASCII word char.
            if !bytes.get(tld_end).is_some_and(|&b| is_ascii_word(b)) {
                matched_end = Some(tld_end);
                break;
            }
        }

        if let Some(end) = matched_end {
            return Some(Some((start, end)));
        }
    }

    Some(None)
}

#[inline]
fn is_valid_ipv4_octet(octet: &[u8]) -> bool {
    match octet.len() {
        1 | 2 => octet.iter().all(|&b| b.is_ascii_digit()),
        3 => {
            octet.iter().all(|&b| b.is_ascii_digit())
                && (matches!(octet[0], b'0' | b'1')
                    || (octet[0] == b'2'
                        && (octet[1] <= b'4' || (octet[1] == b'5' && octet[2] <= b'5'))))
        }
        _ => false,
    }
}

/// Checks Pattern 49 (`/\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b/`)
/// starting at `pos`. Returns `None` at the outer `Option` only if a non-ASCII byte directly touches
/// a candidate IPv4 boundary.
fn match_ipv4_at(bytes: &[u8], pos: usize) -> Option<Option<usize>> {
    if !bytes.get(pos).is_some_and(|&b| b.is_ascii_digit()) {
        return Some(None);
    }
    if pos > 0 {
        let prev = bytes[pos - 1];
        if is_ascii_word(prev) {
            return Some(None);
        }
    }

    let mut cur = pos;
    for _ in 0..3 {
        let d_len = count_while(bytes, cur, |b| b.is_ascii_digit());
        if !is_valid_ipv4_octet(&bytes[cur..cur + d_len]) {
            return Some(None);
        }
        cur += d_len;
        if bytes.get(cur) != Some(&b'.') {
            return Some(None);
        }
        cur += 1;
    }

    let d4_len = count_while(bytes, cur, |b| b.is_ascii_digit());
    if !is_valid_ipv4_octet(&bytes[cur..cur + d4_len]) {
        return Some(None);
    }
    let end = cur + d4_len;

    if pos > 0 && bytes[pos - 1] >= 0x80 {
        return None;
    }
    if end < bytes.len() {
        let next = bytes[end];
        if next >= 0x80 {
            return None;
        }
        if is_ascii_word(next) {
            return Some(None);
        }
    }

    Some(Some(end))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn leaves_clean_text_untouched_without_allocating() {
        let text = "Just a normal conversation about code and Ruby on Rails";
        let res = scrub_sensitive_text(text, false).unwrap();
        assert!(matches!(res, Cow::Borrowed(_)));
        assert_eq!(res, text);
    }

    #[test]
    fn scrubs_all_secret_families_and_counts_matches() {
        let aws = "My key is AKIAIOSFODNN7EXAMPLE and AKIAIOSFODNN7EXAMPL2";
        let (scrubbed, counts) = scrub_sensitive_text_with_counts(aws, false).unwrap();
        assert_eq!(scrubbed, "My key is [REDACTED] and [REDACTED]");
        assert_eq!(counts, vec![("AWS Access Key", 2)]);

        let gh = format!(
            "token: github_pat_{}_{}_{}",
            "a".repeat(22),
            "b".repeat(29),
            "c".repeat(29)
        );
        let (scrubbed, counts) = scrub_sensitive_text_with_counts(&gh, false).unwrap();
        assert_eq!(scrubbed, "token: [REDACTED]");
        assert_eq!(counts, vec![("GitHub Fine-Grained Token", 1)]);

        let masked = format!(
            "Masked token: github_pat_{}_{}",
            "a".repeat(22),
            "*".repeat(35)
        );
        let (scrubbed, counts) = scrub_sensitive_text_with_counts(&masked, false).unwrap();
        assert_eq!(scrubbed, masked);
        assert!(counts.is_empty());
    }

    #[test]
    fn respects_tool_output_skip_list() {
        let text = "Path /Users/johnsmith/.ssh with 192.168.1.1 and john@example.com plus AKIAIOSFODNN7EXAMPLE";
        let (normal_scrubbed, normal_counts) =
            scrub_sensitive_text_with_counts(text, false).unwrap();
        assert_eq!(
            normal_scrubbed,
            "Path [REDACTED]/.ssh with [REDACTED] and [REDACTED] plus [REDACTED]"
        );
        assert_eq!(
            normal_counts,
            vec![
                ("AWS Access Key", 1),
                ("Home Directory", 1),
                ("Email Address", 1),
                ("IPv4 Address", 1),
            ]
        );

        let (tool_scrubbed, tool_counts) = scrub_sensitive_text_with_counts(text, true).unwrap();
        assert_eq!(
            tool_scrubbed,
            "Path /Users/johnsmith/.ssh with 192.168.1.1 and john@example.com plus [REDACTED]"
        );
        assert_eq!(tool_counts, vec![("AWS Access Key", 1)]);
    }

    #[test]
    fn enforces_context_requirements_for_aws_secret_and_mailgun() {
        let forty = "aB3/eF6+iJ9=mN2/qR5+uV8=yZ1/cD4+gH7=kL0/";
        let without_ctx = format!("some_value='{forty}'");
        assert_eq!(
            scrub_sensitive_text(&without_ctx, false).unwrap(),
            without_ctx
        );

        let with_ctx = format!("aws_secret='{forty}'");
        assert_eq!(
            scrub_sensitive_text(&with_ctx, false).unwrap(),
            "aws_secret='[REDACTED]'"
        );

        let mg_key = format!("key-{}", "a1b2c3d4".repeat(4));
        assert_eq!(scrub_sensitive_text(&mg_key, false).unwrap(), mg_key);
        assert_eq!(
            scrub_sensitive_text(&format!("Mailgun {mg_key}"), false).unwrap(),
            "Mailgun [REDACTED]"
        );
    }

    #[test]
    fn accumulator_sorts_descending_with_insertion_order_tie_breaking() {
        let mut acc = RedactionAccumulator::new();
        acc.record(7, 1); // GitHub Token
        acc.record(0, 2); // AWS Access Key
        acc.record(48, 1); // Email Address
        acc.record(7, 1); // GitHub Token -> total 2 (inserted before AWS Access Key)

        assert_eq!(
            acc.into_sorted_redactions(),
            vec![
                ("GitHub Token", 2),
                ("AWS Access Key", 2),
                ("Email Address", 1),
            ]
        );
    }
}
