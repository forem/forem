//! Pure-Rust kernels for [`ApplicationMetalController`] and its high-throughput telemetry
//! endpoints (`BillboardEventsController`, `PageViewsController`, `FeedEventsController`,
//! and `FeedConfigVisitsController`).
//!
//! Includes:
//! - FIPS 180-4 SHA-256 and RFC 2104 HMAC-SHA256 on the stack (zero heap allocations).
//! - RFC 4648 strict/URL-safe Base64 decoding matching Ruby 3.3 `Base64.urlsafe_decode64`.
//! - Constant-time Rails 8 CSRF token unmasking and verification (`valid_authenticity_token?`).
//! - Constant-time HS256 JWT signature verification and flat-claim extraction (`decode_auth_token`).
//! - Single-pass SQL statement generation and ActiveRecord-compatible attribute casting for
//!   `BillboardEvent.add_impression_seconds` and `BillboardEvent.create_with_async_commit`.
//! - Comma-separated origin matching (`BillboardEventsController#embed_request?`), canonical
//!   UUID validation (`Feeds::RecordConfigVisit::UUID_PATTERN`), and 64-bit big-endian SHA-256
//!   advisory lock key derivation (`FeedEvents::BulkUpsert`).

use std::fmt::Write;
use std::hint::black_box;

use crate::feed::civil_from_days;

const AUTHENTICITY_TOKEN_LENGTH: usize = 32;
const GLOBAL_CSRF_TOKEN_IDENTIFIER: &[u8] = b"!real_csrf_token";

const SHA256_K: [u32; 64] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const SHA256_INIT: [u32; 8] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

/// Stack-allocated streaming SHA-256 hasher (FIPS 180-4).
#[derive(Clone)]
pub struct Sha256 {
    state: [u32; 8],
    buf: [u8; 64],
    buf_len: usize,
    total_len: u64,
}

impl Default for Sha256 {
    fn default() -> Self {
        Self::new()
    }
}

impl Sha256 {
    #[inline]
    pub const fn new() -> Self {
        Self {
            state: SHA256_INIT,
            buf: [0u8; 64],
            buf_len: 0,
            total_len: 0,
        }
    }

    pub fn update(&mut self, mut data: &[u8]) {
        self.total_len = self.total_len.wrapping_add(data.len() as u64);

        if self.buf_len > 0 {
            let take = (64 - self.buf_len).min(data.len());
            self.buf[self.buf_len..self.buf_len + take].copy_from_slice(&data[..take]);
            self.buf_len += take;
            data = &data[take..];
            if self.buf_len == 64 {
                let block = self.buf;
                Self::compress(&mut self.state, &block);
                self.buf_len = 0;
            }
        }

        while data.len() >= 64 {
            let (block, rest) = data.split_at(64);
            let block_arr: &[u8; 64] = block.try_into().unwrap();
            Self::compress(&mut self.state, block_arr);
            data = rest;
        }

        if !data.is_empty() {
            self.buf[..data.len()].copy_from_slice(data);
            self.buf_len = data.len();
        }
    }

    pub fn finalize(mut self) -> [u8; 32] {
        let bit_len = self.total_len.wrapping_mul(8);
        self.buf[self.buf_len] = 0x80;
        self.buf_len += 1;

        if self.buf_len > 56 {
            self.buf[self.buf_len..64].fill(0);
            let block = self.buf;
            Self::compress(&mut self.state, &block);
            self.buf_len = 0;
        }

        self.buf[self.buf_len..56].fill(0);
        self.buf[56..64].copy_from_slice(&bit_len.to_be_bytes());
        let block = self.buf;
        Self::compress(&mut self.state, &block);

        let mut out = [0u8; 32];
        for (i, word) in self.state.iter().enumerate() {
            out[i * 4..i * 4 + 4].copy_from_slice(&word.to_be_bytes());
        }
        out
    }

    #[inline]
    fn compress(state: &mut [u32; 8], block: &[u8; 64]) {
        let mut w = [0u32; 64];
        for (i, word) in w.iter_mut().take(16).enumerate() {
            let base = i * 4;
            *word = u32::from_be_bytes([
                block[base],
                block[base + 1],
                block[base + 2],
                block[base + 3],
            ]);
        }
        for i in 16..64 {
            let s0 = w[i - 15].rotate_right(7) ^ w[i - 15].rotate_right(18) ^ (w[i - 15] >> 3);
            let s1 = w[i - 2].rotate_right(17) ^ w[i - 2].rotate_right(19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16]
                .wrapping_add(s0)
                .wrapping_add(w[i - 7])
                .wrapping_add(s1);
        }

        let mut a = state[0];
        let mut b = state[1];
        let mut c = state[2];
        let mut d = state[3];
        let mut e = state[4];
        let mut f = state[5];
        let mut g = state[6];
        let mut h = state[7];

        for i in 0..64 {
            let s1 = e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25);
            let ch = (e & f) ^ ((!e) & g);
            let temp1 = h
                .wrapping_add(s1)
                .wrapping_add(ch)
                .wrapping_add(SHA256_K[i])
                .wrapping_add(w[i]);
            let s0 = a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22);
            let maj = (a & b) ^ (a & c) ^ (b & c);
            let temp2 = s0.wrapping_add(maj);

            h = g;
            g = f;
            f = e;
            e = d.wrapping_add(temp1);
            d = c;
            c = b;
            b = a;
            a = temp1.wrapping_add(temp2);
        }

        state[0] = state[0].wrapping_add(a);
        state[1] = state[1].wrapping_add(b);
        state[2] = state[2].wrapping_add(c);
        state[3] = state[3].wrapping_add(d);
        state[4] = state[4].wrapping_add(e);
        state[5] = state[5].wrapping_add(f);
        state[6] = state[6].wrapping_add(g);
        state[7] = state[7].wrapping_add(h);
    }
}

/// Computes the 32-byte SHA-256 digest of `data`.
#[inline]
pub fn sha256(data: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize()
}

/// Computes the RFC 2104 HMAC-SHA256 over a slice of message segments without concatenating them.
pub fn hmac_sha256_parts(key: &[u8], parts: &[&[u8]]) -> [u8; 32] {
    let mut key_block = [0u8; 64];
    if key.len() > 64 {
        let hashed = sha256(key);
        key_block[..32].copy_from_slice(&hashed);
    } else {
        key_block[..key.len()].copy_from_slice(key);
    }

    let mut ipad = [0x36u8; 64];
    let mut opad = [0x5cu8; 64];
    for i in 0..64 {
        ipad[i] ^= key_block[i];
        opad[i] ^= key_block[i];
    }

    let mut inner = Sha256::new();
    inner.update(&ipad);
    for part in parts {
        inner.update(part);
    }
    let inner_digest = inner.finalize();

    let mut outer = Sha256::new();
    outer.update(&opad);
    outer.update(&inner_digest);
    outer.finalize()
}

/// Computes the RFC 2104 HMAC-SHA256 of `message` under `key`.
#[inline]
pub fn hmac_sha256(key: &[u8], message: &[u8]) -> [u8; 32] {
    hmac_sha256_parts(key, &[message])
}

/// Constant-time 32-byte slice comparison matching `ActiveSupport::SecurityUtils.fixed_length_secure_compare`.
#[inline]
pub fn ct_eq_32(a: &[u8; 32], b: &[u8; 32]) -> bool {
    let mut diff = 0u8;
    for i in 0..32 {
        diff |= black_box(a[i]) ^ black_box(b[i]);
    }
    black_box(diff) == 0
}

/// Lookup table mapping both standard (`+/`) and URL-safe (`-_`) Base64 characters to `0..=63`,
/// or `0xFF` for invalid bytes.
const B64_DECODE_TABLE: [u8; 256] = {
    let mut table = [0xFFu8; 256];
    let mut i = 0u8;
    while i < 26 {
        table[(b'A' + i) as usize] = i;
        table[(b'a' + i) as usize] = i + 26;
        i += 1;
    }
    let mut d = 0u8;
    while d < 10 {
        table[(b'0' + d) as usize] = d + 52;
        d += 1;
    }
    table[b'+' as usize] = 62;
    table[b'-' as usize] = 62;
    table[b'/' as usize] = 63;
    table[b'_' as usize] = 63;
    table
};

/// Decodes a URL-safe or standard Base64 string into `out` using Ruby 3.3's exact
/// `Base64.urlsafe_decode64` rules (optional missing `=` padding when `!input.ends_with(b"=")`,
/// plus strict RFC 4648 canonical zero-bit checks on padded final quantums).
///
/// Returns `Some(decoded_len)` on success, or `None` if `input` is invalid Base64 or if the
/// decoded output would exceed `out.len()`.
pub fn urlsafe_decode64_into(input: &[u8], out: &mut [u8]) -> Option<usize> {
    if input.is_empty() {
        return Some(0);
    }

    let ends_with_eq = input.last() == Some(&b'=');
    let rem = input.len() % 4;
    if ends_with_eq && rem != 0 {
        return None;
    }
    if rem == 1 {
        return None;
    }

    let full_quads = input.len() / 4;
    let has_tail = rem != 0;
    let non_final_quads = if has_tail {
        full_quads
    } else {
        full_quads.saturating_sub(1)
    };

    let mut out_idx = 0usize;
    for q in 0..non_final_quads {
        let base = q * 4;
        let v0 = B64_DECODE_TABLE[input[base] as usize];
        let v1 = B64_DECODE_TABLE[input[base + 1] as usize];
        let v2 = B64_DECODE_TABLE[input[base + 2] as usize];
        let v3 = B64_DECODE_TABLE[input[base + 3] as usize];
        if (v0 | v1 | v2 | v3) & 0xC0 != 0 {
            return None;
        }
        if out_idx + 3 > out.len() {
            return None;
        }
        out[out_idx] = (v0 << 2) | (v1 >> 4);
        out[out_idx + 1] = (v1 << 4) | (v2 >> 2);
        out[out_idx + 2] = (v2 << 6) | v3;
        out_idx += 3;
    }

    let tail = &input[non_final_quads * 4..];
    match tail {
        [] => Some(out_idx),
        [c0, c1] | [c0, c1, b'=', b'='] => {
            let v0 = B64_DECODE_TABLE[*c0 as usize];
            let v1 = B64_DECODE_TABLE[*c1 as usize];
            if ((v0 | v1) & 0xC0 != 0) || (v1 & 0x0F != 0) {
                return None;
            }
            if out_idx + 1 > out.len() {
                return None;
            }
            out[out_idx] = (v0 << 2) | (v1 >> 4);
            Some(out_idx + 1)
        }
        [c0, c1, c2] | [c0, c1, c2, b'='] => {
            let v0 = B64_DECODE_TABLE[*c0 as usize];
            let v1 = B64_DECODE_TABLE[*c1 as usize];
            let v2 = B64_DECODE_TABLE[*c2 as usize];
            if ((v0 | v1 | v2) & 0xC0 != 0) || (v2 & 0x03 != 0) {
                return None;
            }
            if out_idx + 2 > out.len() {
                return None;
            }
            out[out_idx] = (v0 << 2) | (v1 >> 4);
            out[out_idx + 1] = (v1 << 4) | (v2 >> 2);
            Some(out_idx + 2)
        }
        [c0, c1, c2, c3] => {
            let v0 = B64_DECODE_TABLE[*c0 as usize];
            let v1 = B64_DECODE_TABLE[*c1 as usize];
            let v2 = B64_DECODE_TABLE[*c2 as usize];
            let v3 = B64_DECODE_TABLE[*c3 as usize];
            if (v0 | v1 | v2 | v3) & 0xC0 != 0 {
                return None;
            }
            if out_idx + 3 > out.len() {
                return None;
            }
            out[out_idx] = (v0 << 2) | (v1 >> 4);
            out[out_idx + 1] = (v1 << 4) | (v2 >> 2);
            out[out_idx + 2] = (v2 << 6) | v3;
            Some(out_idx + 3)
        }
        _ => None,
    }
}

/// Decodes a URL-safe or standard Base64 slice into an owned `Vec<u8>`.
pub fn urlsafe_decode64_vec(input: &[u8]) -> Option<Vec<u8>> {
    let max_len = (input.len() / 4 + 1) * 3;
    let mut out = vec![0u8; max_len];
    let len = urlsafe_decode64_into(input, &mut out)?;
    out.truncate(len);
    Some(out)
}

/// Verifies a Rails `encoded_masked_token` against the session's `encoded_real_token`,
/// matching `ActionController::RequestForgeryProtection#valid_authenticity_token?`.
///
/// Returns `None` only when `encoded_real_token` is not a valid 32-byte Base64 CSRF token
/// or `request_method` is longer than 32 bytes, so the caller can fall back to Rails.
pub fn verify_authenticity_token(
    encoded_masked_token: &[u8],
    encoded_real_token: &[u8],
    action_path: Option<&[u8]>,
    request_method: Option<&[u8]>,
) -> Option<bool> {
    let mut real_buf = [0u8; AUTHENTICITY_TOKEN_LENGTH];
    if urlsafe_decode64_into(encoded_real_token, &mut real_buf) != Some(AUTHENTICITY_TOKEN_LENGTH) {
        return None;
    }

    if let Some(method) = request_method {
        if method.len() > 32 {
            return None;
        }
    }

    if encoded_masked_token.is_empty() {
        return Some(false);
    }

    let mut masked_buf = [0u8; AUTHENTICITY_TOKEN_LENGTH * 2];
    let Some(decoded_len) = urlsafe_decode64_into(encoded_masked_token, &mut masked_buf) else {
        // Either invalid Base64 (Rails rescues `ArgumentError` and returns `false`) or
        // decoded length > 64 bytes (Rails `else false` branch).
        return Some(false);
    };

    if decoded_len == AUTHENTICITY_TOKEN_LENGTH {
        let unmasked: &[u8; 32] = masked_buf[..32].try_into().unwrap();
        return Some(ct_eq_32(unmasked, &real_buf));
    }

    if decoded_len == AUTHENTICITY_TOKEN_LENGTH * 2 {
        let mut csrf_token = [0u8; AUTHENTICITY_TOKEN_LENGTH];
        for i in 0..AUTHENTICITY_TOKEN_LENGTH {
            csrf_token[i] = masked_buf[i] ^ masked_buf[AUTHENTICITY_TOKEN_LENGTH + i];
        }

        let global_token = hmac_sha256(&real_buf, GLOBAL_CSRF_TOKEN_IDENTIFIER);
        if ct_eq_32(&csrf_token, &global_token) {
            return Some(true);
        }

        if ct_eq_32(&csrf_token, &real_buf) {
            return Some(true);
        }

        if let (Some(path), Some(method)) = (action_path, request_method) {
            let chomped_path = path.strip_suffix(b"/").unwrap_or(path);
            let mut method_lower = [0u8; 32];
            for (i, &b) in method.iter().enumerate() {
                method_lower[i] = b.to_ascii_lowercase();
            }
            let per_form_token = hmac_sha256_parts(
                &real_buf,
                &[chomped_path, b"#", &method_lower[..method.len()]],
            );
            return Some(ct_eq_32(&csrf_token, &per_form_token));
        }

        return Some(false);
    }

    Some(false)
}

/// Scalar value in a flat JWT JSON payload.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum JwtClaimValue {
    Int(i64),
    Str(String),
    Bool(bool),
    Null,
}

/// Outcome of verifying an HS256 JWT token via [`verify_hs256_jwt`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum JwtVerifyOutcome {
    /// Signature is valid, token is not expired, and payload is a flat JSON object.
    Valid(Vec<(String, JwtClaimValue)>),
    /// Token is structurally malformed, signature is invalid, or `exp <= now_sec`.
    Invalid,
    /// Token uses an uncommon header or complex JSON payload; caller should fall back to `JWT.decode`.
    DeferToRuby,
}

#[inline]
fn skip_json_ws(bytes: &[u8], mut i: usize) -> usize {
    while i < bytes.len() && matches!(bytes[i], b' ' | b'\t' | b'\n' | b'\r') {
        i += 1;
    }
    i
}

/// Parses a plain ASCII JSON string without escapes (`"..."`), returning `(slice, next_idx)`.
fn parse_plain_json_str(bytes: &[u8], start: usize) -> Option<(&str, usize)> {
    if bytes.get(start) != Some(&b'"') {
        return None;
    }
    let mut i = start + 1;
    while i < bytes.len() {
        let b = bytes[i];
        if b == b'"' {
            let s = std::str::from_utf8(&bytes[start + 1..i]).ok()?;
            return Some((s, i + 1));
        }
        if b == b'\\' || b < 0x20 {
            return None;
        }
        i += 1;
    }
    None
}

/// Checks that the decoded JWT header is a standard `{"alg":"HS256"}` (with optional `"typ"` string).
fn is_standard_hs256_header(bytes: &[u8]) -> Option<bool> {
    let mut i = skip_json_ws(bytes, 0);
    if bytes.get(i) != Some(&b'{') {
        return Some(false);
    }
    i = skip_json_ws(bytes, i + 1);
    let mut saw_alg_hs256 = false;

    while i < bytes.len() {
        let (key, next_i) = parse_plain_json_str(bytes, i)?;
        i = skip_json_ws(bytes, next_i);
        if bytes.get(i) != Some(&b':') {
            return Some(false);
        }
        i = skip_json_ws(bytes, i + 1);
        let (val, after_val) = parse_plain_json_str(bytes, i)?;
        match key {
            "alg" => {
                if val != "HS256" {
                    return Some(false);
                }
                saw_alg_hs256 = true;
            }
            "typ" => {}
            _ => return None,
        }
        i = skip_json_ws(bytes, after_val);
        match bytes.get(i) {
            Some(b',') => {
                i = skip_json_ws(bytes, i + 1);
            }
            Some(b'}') => {
                i = skip_json_ws(bytes, i + 1);
                return if i == bytes.len() {
                    Some(saw_alg_hs256)
                } else {
                    Some(false)
                };
            }
            _ => return None,
        }
    }
    Some(false)
}

/// Parses a flat JSON object (`{"user_id":123,"exp":1793727000}`) into key-value pairs.
/// Returns `None` if the JSON uses escapes, floats, arrays, nested objects, or registered
/// JWT claims (`nbf`, `aud`, `iss`, `sub`, `jti`, `iat`) that have custom `ruby-jwt` validators.
fn parse_flat_jwt_payload(bytes: &[u8]) -> Option<Vec<(String, JwtClaimValue)>> {
    let mut i = skip_json_ws(bytes, 0);
    if bytes.get(i) != Some(&b'{') {
        return None;
    }
    i = skip_json_ws(bytes, i + 1);
    let mut claims = Vec::with_capacity(4);
    if bytes.get(i) == Some(&b'}') {
        i = skip_json_ws(bytes, i + 1);
        return if i == bytes.len() { Some(claims) } else { None };
    }

    while i < bytes.len() {
        let (key, after_key) = parse_plain_json_str(bytes, i)?;
        if matches!(key, "nbf" | "aud" | "iss" | "sub" | "jti" | "iat") {
            return None;
        }
        i = skip_json_ws(bytes, after_key);
        if bytes.get(i) != Some(&b':') {
            return None;
        }
        i = skip_json_ws(bytes, i + 1);
        let b = *bytes.get(i)?;
        let val = if b == b'"' {
            let (s, next_i) = parse_plain_json_str(bytes, i)?;
            i = next_i;
            JwtClaimValue::Str(s.to_owned())
        } else if b == b'-' || b.is_ascii_digit() {
            let num_start = i;
            if b == b'-' {
                i += 1;
            }
            let digits_start = i;
            while i < bytes.len() && bytes[i].is_ascii_digit() {
                i += 1;
            }
            if i == digits_start {
                return None;
            }
            if matches!(bytes.get(i), Some(b'.' | b'e' | b'E')) {
                return None;
            }
            let num_str = std::str::from_utf8(&bytes[num_start..i]).ok()?;
            let n = num_str.parse::<i64>().ok()?;
            JwtClaimValue::Int(n)
        } else if bytes[i..].starts_with(b"true") {
            i += 4;
            JwtClaimValue::Bool(true)
        } else if bytes[i..].starts_with(b"false") {
            i += 5;
            JwtClaimValue::Bool(false)
        } else if bytes[i..].starts_with(b"null") {
            i += 4;
            JwtClaimValue::Null
        } else {
            return None;
        };

        if claims.iter().any(|(k, _)| k == key) {
            return None;
        }
        claims.push((key.to_owned(), val));

        i = skip_json_ws(bytes, i);
        match bytes.get(i) {
            Some(b',') => {
                i = skip_json_ws(bytes, i + 1);
            }
            Some(b'}') => {
                i = skip_json_ws(bytes, i + 1);
                return if i == bytes.len() { Some(claims) } else { None };
            }
            _ => return None,
        }
    }
    None
}

/// Verifies an HS256 JWT token (`JWT.decode(token, secret, true, algorithm: "HS256")[0]`)
/// in constant time and parses standard flat claim payloads.
pub fn verify_hs256_jwt(token: &[u8], secret: &[u8], now_sec: i64) -> JwtVerifyOutcome {
    if token.is_empty() || token.len() > 8192 {
        return JwtVerifyOutcome::Invalid;
    }

    let Some(first_dot) = token.iter().position(|&b| b == b'.') else {
        return JwtVerifyOutcome::Invalid;
    };
    let rest = &token[first_dot + 1..];
    let Some(rel_second_dot) = rest.iter().position(|&b| b == b'.') else {
        return JwtVerifyOutcome::Invalid;
    };
    let second_dot = first_dot + 1 + rel_second_dot;
    let sig_part = &token[second_dot + 1..];
    if sig_part.contains(&b'.') {
        return JwtVerifyOutcome::Invalid;
    }

    let header_part = &token[..first_dot];
    let payload_part = &token[first_dot + 1..second_dot];
    if header_part.is_empty() || payload_part.is_empty() || sig_part.is_empty() {
        return JwtVerifyOutcome::Invalid;
    }

    let mut sig_buf = [0u8; 32];
    if urlsafe_decode64_into(sig_part, &mut sig_buf) != Some(32) {
        return JwtVerifyOutcome::Invalid;
    }

    let signing_input = &token[..second_dot];
    let expected_sig = hmac_sha256(secret, signing_input);
    if !ct_eq_32(&sig_buf, &expected_sig) {
        return JwtVerifyOutcome::Invalid;
    }

    let mut header_buf = [0u8; 128];
    let Some(header_len) = urlsafe_decode64_into(header_part, &mut header_buf) else {
        return JwtVerifyOutcome::DeferToRuby;
    };
    match is_standard_hs256_header(&header_buf[..header_len]) {
        Some(true) => {}
        Some(false) => return JwtVerifyOutcome::Invalid,
        None => return JwtVerifyOutcome::DeferToRuby,
    }

    let Some(payload_bytes) = urlsafe_decode64_vec(payload_part) else {
        return JwtVerifyOutcome::Invalid;
    };
    let Some(claims) = parse_flat_jwt_payload(&payload_bytes) else {
        return JwtVerifyOutcome::DeferToRuby;
    };

    for (k, v) in &claims {
        if k == "exp" {
            match v {
                JwtClaimValue::Int(exp) => {
                    if *exp <= now_sec {
                        return JwtVerifyOutcome::Invalid;
                    }
                }
                _ => return JwtVerifyOutcome::DeferToRuby,
            }
        }
    }

    JwtVerifyOutcome::Valid(claims)
}

/// Result of casting a String to a signed 64-bit integer using ActiveRecord's
/// `ActiveModel::Type::BigInteger` / `ActiveModel::Type::Integer` rules.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ActiveRecordIntCast {
    /// Blank string (`/\A[[:space:]]*\z/`) casts to `nil`.
    Null,
    /// Casts to a 64-bit signed integer.
    Value(i64),
    /// Contains non-ASCII whitespace or overflows `i64`; caller should defer to Ruby.
    DeferToRuby,
}

#[inline]
const fn is_ascii_ruby_space(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0B | 0x0C)
}

/// Casts a byte slice according to `ActiveModel::Type::BigInteger#cast_value`:
/// - All-whitespace ASCII strings return `ActiveRecordIntCast::Null`.
/// - Otherwise parses leading optional `+`/`-` and decimal digits (with single `_` separators)
///   exactly like Ruby's `String#to_i`, returning `0` when no leading digits are present.
pub fn cast_active_record_bigint_bytes(bytes: &[u8]) -> ActiveRecordIntCast {
    let mut i = 0usize;
    while i < bytes.len() {
        let b = bytes[i];
        if is_ascii_ruby_space(b) {
            i += 1;
        } else if b >= 0x80 {
            return ActiveRecordIntCast::DeferToRuby;
        } else {
            break;
        }
    }

    if i == bytes.len() {
        return ActiveRecordIntCast::Null;
    }

    let mut negative = false;
    if bytes[i] == b'+' {
        i += 1;
    } else if bytes[i] == b'-' {
        negative = true;
        i += 1;
    }

    if i >= bytes.len() || !bytes[i].is_ascii_digit() {
        return ActiveRecordIntCast::Value(0);
    }

    let mut acc: u64 = 0;
    while i < bytes.len() {
        let b = bytes[i];
        if b.is_ascii_digit() {
            let digit = (b - b'0') as u64;
            let Some(next) = acc.checked_mul(10).and_then(|v| v.checked_add(digit)) else {
                return ActiveRecordIntCast::DeferToRuby;
            };
            acc = next;
            i += 1;
        } else if b == b'_' && i + 1 < bytes.len() && bytes[i + 1].is_ascii_digit() {
            i += 1;
        } else {
            break;
        }
    }

    if negative {
        if acc == (i64::MAX as u64) + 1 {
            ActiveRecordIntCast::Value(i64::MIN)
        } else if acc <= i64::MAX as u64 {
            ActiveRecordIntCast::Value(-(acc as i64))
        } else {
            ActiveRecordIntCast::DeferToRuby
        }
    } else if acc <= i64::MAX as u64 {
        ActiveRecordIntCast::Value(acc as i64)
    } else {
        ActiveRecordIntCast::DeferToRuby
    }
}

/// Formats a UTC timestamp `(unix_sec, usec)` into `out` as `'YYYY-MM-DD HH:MM:SS'` or
/// `'YYYY-MM-DD HH:MM:SS.ffffff'`, matching ActiveRecord's `Quoting#quoted_date`.
pub fn push_quoted_utc_timestamp(out: &mut String, unix_sec: i64, usec: u32) -> Option<()> {
    if usec >= 1_000_000 {
        return None;
    }
    let days = unix_sec.div_euclid(86_400);
    let secs_of_day = unix_sec.rem_euclid(86_400) as u32;
    let (year, month, day) = civil_from_days(days);
    if !(1000..=9999).contains(&year) {
        return None;
    }

    let hour = secs_of_day / 3600;
    let minute = (secs_of_day % 3600) / 60;
    let second = secs_of_day % 60;

    out.push('\'');
    let y = year as u32;
    for digit in [y / 1000, (y / 100) % 10, (y / 10) % 10, y % 10] {
        out.push(char::from(b'0' + digit as u8));
    }
    out.push('-');
    push_two_digits(out, month);
    out.push('-');
    push_two_digits(out, day);
    out.push(' ');
    push_two_digits(out, hour);
    out.push(':');
    push_two_digits(out, minute);
    out.push(':');
    push_two_digits(out, second);

    if usec > 0 {
        out.push('.');
        for divisor in [100_000, 10_000, 1_000, 100, 10, 1] {
            let digit = (usec / divisor) % 10;
            out.push(char::from(b'0' + digit as u8));
        }
    }
    out.push('\'');
    Some(())
}

#[inline]
fn push_two_digits(out: &mut String, val: u32) {
    out.push(char::from(b'0' + (val / 10) as u8));
    out.push(char::from(b'0' + (val % 10) as u8));
}

/// Quotes an optional SQL string literal (`NULL` or `'...'` with `'` doubled to `''`),
/// rejecting strings containing NUL (`\0`) bytes so callers can fall back if needed.
fn push_quoted_nullable_sql_str(out: &mut String, value: Option<&str>) -> Option<()> {
    let Some(s) = value else {
        out.push_str("NULL");
        return Some(());
    };
    if s.as_bytes().contains(&0) {
        return None;
    }
    out.push('\'');
    let bytes = s.as_bytes();
    let mut start = 0usize;
    for (i, &b) in bytes.iter().enumerate() {
        if b == b'\'' {
            out.push_str(&s[start..=i]);
            out.push('\'');
            start = i + 1;
        }
    }
    out.push_str(&s[start..]);
    out.push('\'');
    Some(())
}

/// Builds the single-statement `SET LOCAL synchronous_commit TO OFF; UPDATE "display_ad_events" ...`
/// SQL query for `BillboardEvent.add_impression_seconds`.
pub fn billboard_event_update_sql(
    event_id: i64,
    user_id: Option<i64>,
    seconds: i64,
    now_sec: i64,
    now_usec: u32,
    cutoff_sec: i64,
    cutoff_usec: u32,
) -> Option<String> {
    let mut out = String::with_capacity(260);
    out.push_str(
        "SET LOCAL synchronous_commit TO OFF; UPDATE \"display_ad_events\" SET seconds_visible = seconds_visible + ",
    );
    let _ = write!(out, "{seconds}, updated_at = ");
    push_quoted_utc_timestamp(&mut out, now_sec, now_usec)?;
    let _ = write!(
        out,
        " WHERE id = {event_id} AND category = 'impression' AND (user_id IS NULL OR user_id = "
    );
    match user_id {
        Some(uid) => {
            let _ = write!(out, "{uid}");
        }
        None => out.push_str("NULL"),
    }
    out.push_str(") AND updated_at <= ");
    push_quoted_utc_timestamp(&mut out, cutoff_sec, cutoff_usec)?;
    Some(out)
}

/// Parameters for [`billboard_event_insert_sql`].
#[derive(Debug, Clone, Copy)]
pub struct BillboardEventInsert<'a> {
    pub display_ad_id: i64,
    pub category: &'a str,
    pub context_type: &'a str,
    pub user_id: Option<i64>,
    pub article_id: Option<i32>,
    pub geolocation: Option<&'a str>,
    pub user_agent: Option<&'a str>,
    pub counts_for: i32,
    pub seconds_visible: i32,
    pub now_sec: i64,
    pub now_usec: u32,
    pub verify_billboard_exists: bool,
}

/// Outcome of validating and building the `INSERT` SQL for `BillboardEvent.create_with_async_commit`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BillboardEventInsertOutcome {
    /// Ready-to-execute single-round-trip SQL statement.
    Sql(String),
    /// Event fails model validation (`category` or `context_type` not in allowed sets).
    Invalid,
    /// Conversion/signup event for a logged-in user requires DB uniqueness/registration checks in Ruby.
    DeferToRuby,
}

#[inline]
pub fn is_valid_billboard_category(category: &str) -> bool {
    matches!(category, "click" | "impression" | "signup" | "conversion")
}

#[inline]
pub fn is_valid_billboard_context_type(context_type: &str) -> bool {
    matches!(context_type, "home" | "article" | "email" | "embed")
}

/// Validates and builds the `SET LOCAL synchronous_commit TO OFF; INSERT INTO "display_ad_events" ...`
/// SQL query for `BillboardEvent.create_with_async_commit`.
pub fn billboard_event_insert_sql(
    params: &BillboardEventInsert<'_>,
) -> BillboardEventInsertOutcome {
    if !is_valid_billboard_category(params.category)
        || !is_valid_billboard_context_type(params.context_type)
    {
        return BillboardEventInsertOutcome::Invalid;
    }

    if params.user_id.is_some() && matches!(params.category, "signup" | "conversion") {
        return BillboardEventInsertOutcome::DeferToRuby;
    }

    let mut out = String::with_capacity(420);
    out.push_str(
        "SET LOCAL synchronous_commit TO OFF; INSERT INTO \"display_ad_events\" (\"article_id\", \"category\", \"context_type\", \"counts_for\", \"created_at\", \"display_ad_id\", \"geolocation\", \"seconds_visible\", \"updated_at\", \"user_agent\", \"user_id\") ",
    );
    if params.verify_billboard_exists {
        out.push_str("SELECT ");
    } else {
        out.push_str("VALUES (");
    }

    match params.article_id {
        Some(aid) => {
            let _ = write!(out, "{aid}, ");
        }
        None => out.push_str("NULL, "),
    }
    let _ = write!(
        out,
        "'{}', '{}', {}, ",
        params.category, params.context_type, params.counts_for
    );
    let Some(()) = push_quoted_utc_timestamp(&mut out, params.now_sec, params.now_usec) else {
        return BillboardEventInsertOutcome::DeferToRuby;
    };
    let _ = write!(out, ", {}, ", params.display_ad_id);
    let Some(()) = push_quoted_nullable_sql_str(&mut out, params.geolocation) else {
        return BillboardEventInsertOutcome::DeferToRuby;
    };
    let _ = write!(out, ", {}, ", params.seconds_visible);
    let Some(()) = push_quoted_utc_timestamp(&mut out, params.now_sec, params.now_usec) else {
        return BillboardEventInsertOutcome::DeferToRuby;
    };
    out.push_str(", ");
    let Some(()) = push_quoted_nullable_sql_str(&mut out, params.user_agent) else {
        return BillboardEventInsertOutcome::DeferToRuby;
    };
    out.push_str(", ");
    match params.user_id {
        Some(uid) => {
            let _ = write!(out, "{uid}");
        }
        None => out.push_str("NULL"),
    }

    if params.verify_billboard_exists {
        let _ = write!(
            out,
            " WHERE EXISTS (SELECT 1 FROM \"display_ads\" WHERE \"display_ads\".\"id\" = {}) RETURNING \"id\"",
            params.display_ad_id
        );
    } else {
        out.push_str(") RETURNING \"id\"");
    }

    BillboardEventInsertOutcome::Sql(out)
}

#[inline]
const fn is_ruby_strip_ascii_ws(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0B | 0x0C | 0x00)
}

/// Checks whether `origin` matches any whitespace-trimmed non-empty entry in `comma_separated_list`,
/// matching `raw_list.to_s.split(",").map(&:strip).reject(&:empty?).include?(origin)`.
pub fn origin_in_comma_list(origin: &[u8], comma_separated_list: &[u8]) -> bool {
    if origin.is_empty() || comma_separated_list.is_empty() {
        return false;
    }

    for entry in comma_separated_list.split(|&b| b == b',') {
        let mut start = 0usize;
        let mut end = entry.len();
        while start < end && is_ruby_strip_ascii_ws(entry[start]) {
            start += 1;
        }
        while end > start && is_ruby_strip_ascii_ws(entry[end - 1]) {
            end -= 1;
        }
        let trimmed = &entry[start..end];
        if !trimmed.is_empty() && trimmed == origin {
            return true;
        }
    }
    false
}

/// Checks whether `bytes` matches `Feeds::RecordConfigVisit::UUID_PATTERN`
/// (`/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i`).
#[inline]
pub fn is_valid_uuid(bytes: &[u8]) -> bool {
    if bytes.len() != 36 {
        return false;
    }
    for (i, &b) in bytes.iter().enumerate() {
        if i == 8 || i == 13 || i == 18 || i == 23 {
            if b != b'-' {
                return false;
            }
        } else if !b.is_ascii_hexdigit() {
            return false;
        }
    }
    true
}

/// Computes `Digest::SHA256.digest("feed_events:#{user_id}").unpack1("q>")` for
/// `FeedEvents::BulkUpsert#call` on the stack with zero heap allocations.
#[inline]
pub fn feed_events_advisory_lock_key(user_id: i64) -> i64 {
    let mut buf = [0u8; 36];
    buf[..12].copy_from_slice(b"feed_events:");
    let n = user_id;
    let mut pos = 12usize;
    if n < 0 {
        buf[pos] = b'-';
        pos += 1;
    }
    let abs_val = n.unsigned_abs();
    if abs_val == 0 {
        buf[pos] = b'0';
        pos += 1;
    } else {
        let mut digits = [0u8; 20];
        let mut d_len = 0usize;
        let mut rem = abs_val;
        while rem > 0 {
            digits[d_len] = b'0' + (rem % 10) as u8;
            rem /= 10;
            d_len += 1;
        }
        while d_len > 0 {
            d_len -= 1;
            buf[pos] = digits[d_len];
            pos += 1;
        }
    }
    let digest = sha256(&buf[..pos]);
    i64::from_be_bytes([
        digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
    ])
}

/// Outcome of `ValidRequest#valid_request_origin?` fast-path evaluation.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OriginValidation {
    Valid,
    Invalid,
    NullOrigin,
}

#[inline]
fn is_valid_rfc3986_tail_char(b: u8) -> bool {
    matches!(
        b,
        b'A'..=b'Z'
            | b'a'..=b'z'
            | b'0'..=b'9'
            | b'-'
            | b'.'
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
            | b'/'
            | b'?'
            | b'#'
    )
}

#[inline]
fn validate_rfc3986_tail(tail: &[u8]) -> bool {
    let mut i = 0usize;
    while i < tail.len() {
        let b = tail[i];
        if b == b'%' {
            if i + 2 >= tail.len()
                || !tail[i + 1].is_ascii_hexdigit()
                || !tail[i + 2].is_ascii_hexdigit()
            {
                return false;
            }
            i += 3;
        } else if is_valid_rfc3986_tail_char(b) {
            i += 1;
        } else {
            return false;
        }
    }
    true
}

#[inline]
fn eq_replacing_https_with_http(a: &[u8], b: &[u8]) -> bool {
    let mut ia = 0usize;
    let mut ib = 0usize;
    while ia < a.len() && ib < b.len() {
        let ba = a[ia];
        let bb = b[ib];
        if ba != bb {
            return false;
        }
        let a_https = ia + 5 <= a.len() && &a[ia..ia + 5] == b"https";
        let b_https = ib + 5 <= b.len() && &b[ib..ib + 5] == b"https";
        if a_https || b_https {
            let a_http = a_https || (ia + 4 <= a.len() && &a[ia..ia + 4] == b"http");
            let b_http = b_https || (ib + 4 <= b.len() && &b[ib..ib + 4] == b"http");
            if !a_http || !b_http {
                return false;
            }
            ia += if a_https { 5 } else { 4 };
            ib += if b_https { 5 } else { 4 };
        } else {
            ia += 1;
            ib += 1;
        }
    }
    ia == a.len() && ib == b.len()
}

/// Evaluates `ValidRequest#valid_request_origin?` without allocating `URI::HTTP` objects or
/// running `String#gsub` on the heap.
///
/// Returns `None` if `referer` is a non-standard URI that should fall back to Ruby's `URI.parse`.
pub fn valid_request_origin(
    referer: Option<&[u8]>,
    origin: Option<&[u8]>,
    base_url: Option<&[u8]>,
    request_host: Option<&[u8]>,
    request_port: Option<i64>,
) -> Option<OriginValidation> {
    if let Some(ref_bytes) = referer {
        if ref_bytes.iter().any(|&b| b >= 0x80) {
            return None;
        }
        let is_blank = ref_bytes.iter().all(|&b| is_ruby_strip_ascii_ws(b));
        if !is_blank {
            let req_host = request_host?;
            let req_port = request_port?;

            let (default_port, rest) =
                if ref_bytes.len() >= 8 && ref_bytes[..8].eq_ignore_ascii_case(b"https://") {
                    (443i64, &ref_bytes[8..])
                } else if ref_bytes.len() >= 7 && ref_bytes[..7].eq_ignore_ascii_case(b"http://") {
                    (80i64, &ref_bytes[7..])
                } else {
                    return None;
                };

            let auth_end = rest
                .iter()
                .position(|&b| b == b'/' || b == b'?' || b == b'#')
                .unwrap_or(rest.len());
            let authority = &rest[..auth_end];
            let tail = &rest[auth_end..];
            if authority.is_empty() || !validate_rfc3986_tail(tail) {
                return None;
            }

            let (host_part, uri_port) = match authority.iter().position(|&b| b == b':') {
                Some(colon_pos) => {
                    let h = &authority[..colon_pos];
                    let p = &authority[colon_pos + 1..];
                    if p.contains(&b':') {
                        return None;
                    }
                    if p.is_empty() {
                        (h, default_port)
                    } else {
                        if p.len() > 5 || !p.iter().all(|b| b.is_ascii_digit()) {
                            return None;
                        }
                        let mut port_val = 0i64;
                        for &d in p {
                            port_val = port_val * 10 + (d - b'0') as i64;
                        }
                        (h, port_val)
                    }
                }
                None => (authority, default_port),
            };

            if host_part.is_empty()
                || !host_part
                    .iter()
                    .all(|&b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-')
            {
                return None;
            }

            return if host_part == req_host && uri_port == req_port {
                Some(OriginValidation::Valid)
            } else {
                Some(OriginValidation::Invalid)
            };
        }
    }

    match origin {
        None => Some(OriginValidation::Valid),
        Some(b"null") => Some(OriginValidation::NullOrigin),
        Some(orig_bytes) => {
            let base_bytes = base_url?;
            if eq_replacing_https_with_http(orig_bytes, base_bytes) {
                Some(OriginValidation::Valid)
            } else {
                Some(OriginValidation::Invalid)
            }
        }
    }
}

/// Extracts `(domain, path)` from a `PageView#referrer` string matching
/// `parsed_url = Addressable::URI.parse(referrer); [parsed_url.domain, parsed_url.path]`.
///
/// Returns `None` for non-standard/complex URIs so the caller falls back to `Addressable::URI.parse`.
pub fn extract_referrer_domain_and_path(referrer: &[u8]) -> Option<(Option<String>, String)> {
    if referrer.is_empty() {
        return Some((None, String::new()));
    }
    if referrer
        .iter()
        .all(|&b| b.is_ascii_alphanumeric() || b == b'_' || b == b'-')
    {
        let s = std::str::from_utf8(referrer).ok()?;
        return Some((None, s.to_owned()));
    }

    let rest = if referrer.starts_with(b"https://") {
        &referrer[8..]
    } else if referrer.starts_with(b"http://") {
        &referrer[7..]
    } else {
        return None;
    };

    let auth_end = rest
        .iter()
        .position(|&b| b == b'/' || b == b'?' || b == b'#')
        .unwrap_or(rest.len());
    let authority = &rest[..auth_end];
    if authority.is_empty() {
        return None;
    }

    let host_part = match authority.iter().position(|&b| b == b':') {
        Some(colon_pos) => {
            let h = &authority[..colon_pos];
            let p = &authority[colon_pos + 1..];
            if p.len() > 5 || !p.iter().all(|b| b.is_ascii_digit()) {
                return None;
            }
            h
        }
        None => authority,
    };

    if host_part.is_empty()
        || !host_part
            .iter()
            .all(|&b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-')
    {
        return None;
    }

    let tail = &rest[auth_end..];
    let path_bytes = if tail.starts_with(b"/") {
        let path_end = tail
            .iter()
            .position(|&b| b == b'?' || b == b'#')
            .unwrap_or(tail.len());
        let p = &tail[..path_end];
        // Defer dot-segments or percent-encoding or backslashes to Addressable::URI.
        if p.iter()
            .any(|&b| b <= 0x20 || b >= 0x7F || b == b'%' || b == b'\\')
            || p.windows(2).any(|w| w == b"//")
            || p.windows(3).any(|w| w == b"/./" || w == b"/..")
            || p.ends_with(b"/.")
            || p.ends_with(b"/..")
        {
            return None;
        }
        p
    } else {
        b""
    };

    let domain = if !host_part.contains(&b'.') {
        None
    } else {
        match crate::url::public_suffix_domain_ignore_private(host_part)? {
            Ok(d) => Some(d.into_owned()),
            Err(()) => return None,
        }
    };
    let path_str = std::str::from_utf8(path_bytes).ok()?.to_owned();
    Some((domain, path_str))
}

/// Fast-path route classification for `Middlewares::MetalTelemetryFastPath`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MetalTelemetryRoute<'a> {
    BillboardUpdate(&'a str),
    BillboardCreate,
    PageViewUpdate(&'a str),
    PageViewCreate,
    GaEventCreate,
    FeedEventsCreate,
    FeedConfigVisitsCreate,
}

#[inline]
fn extract_single_id_segment(rest: &[u8]) -> Option<&str> {
    if rest.is_empty() || rest.contains(&b'/') || rest.contains(&b'.') {
        return None;
    }
    std::str::from_utf8(rest).ok()
}

/// Classifies `(REQUEST_METHOD, PATH_INFO)` for `Middlewares::MetalTelemetryFastPath`.
#[inline]
pub fn match_metal_telemetry_route<'a>(
    method: &[u8],
    path: &'a [u8],
) -> Option<MetalTelemetryRoute<'a>> {
    let norm_path = if path.len() > 1 {
        path.strip_suffix(b"/").unwrap_or(path)
    } else {
        path
    };
    match method {
        b"PATCH" => {
            if let Some(rest) = norm_path.strip_prefix(b"/bb_tabulations/") {
                return extract_single_id_segment(rest).map(MetalTelemetryRoute::BillboardUpdate);
            }
            if let Some(rest) = norm_path.strip_prefix(b"/page_views/") {
                return extract_single_id_segment(rest).map(MetalTelemetryRoute::PageViewUpdate);
            }
            None
        }
        b"PUT" => {
            if let Some(rest) = norm_path.strip_prefix(b"/page_views/") {
                return extract_single_id_segment(rest).map(MetalTelemetryRoute::PageViewUpdate);
            }
            None
        }
        b"POST" => match norm_path {
            b"/bb_tabulations" | b"/billboard_events" | b"/display_ad_events" => {
                Some(MetalTelemetryRoute::BillboardCreate)
            }
            b"/page_views" => Some(MetalTelemetryRoute::PageViewCreate),
            b"/fallback_activity_recorder" => Some(MetalTelemetryRoute::GaEventCreate),
            b"/feed_events" => Some(MetalTelemetryRoute::FeedEventsCreate),
            b"/feed_config_visits" => Some(MetalTelemetryRoute::FeedConfigVisitsCreate),
            _ => None,
        },
        _ => None,
    }
}

/// Outcome of parsing a JSON body and building the `BillboardEvent` `INSERT` SQL statement.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BillboardJsonCreateOutcome {
    BlankId,
    Parsed {
        sql: Option<String>,
        raw_billboard_id: String,
    },
}

struct JsonScanner<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> JsonScanner<'a> {
    #[inline]
    fn new(bytes: &'a [u8]) -> Self {
        Self { bytes, pos: 0 }
    }

    #[inline]
    fn skip_ws(&mut self) {
        while self.pos < self.bytes.len() {
            match self.bytes[self.pos] {
                b' ' | b'\t' | b'\r' | b'\n' => self.pos += 1,
                _ => break,
            }
        }
    }

    #[inline]
    fn peek(&self) -> Option<u8> {
        self.bytes.get(self.pos).copied()
    }

    #[inline]
    fn consume_byte(&mut self, expected: u8) -> bool {
        self.skip_ws();
        if self.peek() == Some(expected) {
            self.pos += 1;
            true
        } else {
            false
        }
    }

    fn parse_string(&mut self) -> Option<String> {
        self.skip_ws();
        if self.peek() != Some(b'"') {
            return None;
        }
        self.pos += 1;
        let start = self.pos;
        let mut has_escape = false;
        while self.pos < self.bytes.len() {
            let b = self.bytes[self.pos];
            if b == b'"' {
                let raw = &self.bytes[start..self.pos];
                self.pos += 1;
                if !has_escape {
                    return std::str::from_utf8(raw).ok().map(str::to_owned);
                }
                return Self::unescape_simple(raw);
            }
            if b == b'\\' {
                has_escape = true;
                self.pos += 1;
                if self.pos >= self.bytes.len() {
                    return None;
                }
            } else if b < 0x20 {
                return None;
            }
            self.pos += 1;
        }
        None
    }

    fn unescape_simple(raw: &[u8]) -> Option<String> {
        let mut out = Vec::with_capacity(raw.len());
        let mut i = 0usize;
        while i < raw.len() {
            let b = raw[i];
            if b == b'\\' {
                i += 1;
                if i >= raw.len() {
                    return None;
                }
                match raw[i] {
                    b'"' => out.push(b'"'),
                    b'\\' => out.push(b'\\'),
                    b'/' => out.push(b'/'),
                    b'n' => out.push(b'\n'),
                    b'r' => out.push(b'\r'),
                    b't' => out.push(b'\t'),
                    _ => return None,
                }
            } else {
                out.push(b);
            }
            i += 1;
        }
        String::from_utf8(out).ok()
    }

    /// Parses a JSON scalar value (`"..."`, integer, `null`, `true`, `false`) as an optional string.
    /// Returns `None` (aborting fast-path) if the value is an array, object, float, or malformed.
    fn parse_scalar_as_string(&mut self) -> Option<Option<String>> {
        self.skip_ws();
        match self.peek()? {
            b'"' => self.parse_string().map(Some),
            b'n' => {
                if self.bytes[self.pos..].starts_with(b"null") {
                    self.pos += 4;
                    Some(None)
                } else {
                    None
                }
            }
            b't' => {
                if self.bytes[self.pos..].starts_with(b"true") {
                    self.pos += 4;
                    Some(Some("true".to_owned()))
                } else {
                    None
                }
            }
            b'f' => {
                if self.bytes[self.pos..].starts_with(b"false") {
                    self.pos += 5;
                    Some(Some("false".to_owned()))
                } else {
                    None
                }
            }
            b'-' | b'0'..=b'9' => {
                let start = self.pos;
                if self.bytes[self.pos] == b'-' {
                    self.pos += 1;
                }
                let digit_start = self.pos;
                while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
                    self.pos += 1;
                }
                if self.pos == digit_start {
                    return None;
                }
                // Defer floats/exponents to Ruby JSON parser.
                if matches!(self.peek(), Some(b'.' | b'e' | b'E')) {
                    return None;
                }
                let s = std::str::from_utf8(&self.bytes[start..self.pos]).ok()?;
                Some(Some(s.to_owned()))
            }
            _ => None,
        }
    }
}

#[derive(Default)]
struct RawEventFields {
    billboard_id: Option<String>,
    display_ad_id: Option<String>,
    context_type: Option<String>,
    category: Option<String>,
    article_id: Option<String>,
    user_agent: Option<String>,
}

fn parse_inner_event_object(scanner: &mut JsonScanner<'_>) -> Option<RawEventFields> {
    if !scanner.consume_byte(b'{') {
        return None;
    }
    let mut fields = RawEventFields::default();
    if scanner.consume_byte(b'}') {
        return Some(fields);
    }
    loop {
        let key = scanner.parse_string()?;
        if !scanner.consume_byte(b':') {
            return None;
        }
        let val = scanner.parse_scalar_as_string()?;
        match key.as_str() {
            "billboard_id" => fields.billboard_id = val,
            "display_ad_id" => fields.display_ad_id = val,
            "context_type" => fields.context_type = val,
            "category" => fields.category = val,
            "article_id" => fields.article_id = val,
            "user_agent" => fields.user_agent = val,
            _ => {}
        }
        if scanner.consume_byte(b',') {
            continue;
        }
        if scanner.consume_byte(b'}') {
            break;
        }
        return None;
    }
    Some(fields)
}

#[inline]
fn non_blank_str(opt: Option<&str>) -> Option<&str> {
    let s = opt?;
    if s.bytes().all(is_ruby_strip_ascii_ws) {
        None
    } else {
        Some(s)
    }
}

/// Parses a `POST /bb_tabulations` JSON payload and builds the `BillboardEvent` `INSERT` SQL
/// in a single native call without `ActiveSupport::JSON.decode` or `ActionController::Parameters`.
pub fn billboard_event_create_from_json_sql(
    json_body: &[u8],
    user_id: Option<i64>,
    geolocation: Option<&str>,
    header_user_agent: Option<&str>,
    is_embed: bool,
    now_sec: i64,
    now_usec: u32,
) -> Option<BillboardJsonCreateOutcome> {
    let mut scanner = JsonScanner::new(json_body);
    if !scanner.consume_byte(b'{') {
        return None;
    }

    let mut billboard_event: Option<RawEventFields> = None;
    let mut display_ad_event: Option<RawEventFields> = None;
    let mut top_article_id: Option<String> = None;
    let mut top_user_agent: Option<String> = None;

    if !scanner.consume_byte(b'}') {
        loop {
            let key = scanner.parse_string()?;
            if !scanner.consume_byte(b':') {
                return None;
            }
            match key.as_str() {
                "billboard_event" => {
                    scanner.skip_ws();
                    if scanner.peek() == Some(b'{') {
                        billboard_event = Some(parse_inner_event_object(&mut scanner)?);
                    } else if scanner.parse_scalar_as_string()?.is_none() {
                        billboard_event = None;
                    } else {
                        return None;
                    }
                }
                "display_ad_event" => {
                    scanner.skip_ws();
                    if scanner.peek() == Some(b'{') {
                        display_ad_event = Some(parse_inner_event_object(&mut scanner)?);
                    } else if scanner.parse_scalar_as_string()?.is_none() {
                        display_ad_event = None;
                    } else {
                        return None;
                    }
                }
                "article_id" => {
                    top_article_id = scanner.parse_scalar_as_string()?;
                }
                "user_agent" => {
                    top_user_agent = scanner.parse_scalar_as_string()?;
                }
                _ => {
                    scanner.parse_scalar_as_string()?;
                }
            }
            if scanner.consume_byte(b',') {
                continue;
            }
            if scanner.consume_byte(b'}') {
                break;
            }
            return None;
        }
    }
    scanner.skip_ws();
    if scanner.pos != scanner.bytes.len() {
        return None;
    }

    let ev = billboard_event.or(display_ad_event).unwrap_or_default();
    let raw_billboard_id = ev.billboard_id.as_deref().or(ev.display_ad_id.as_deref());

    let raw_id_str = match non_blank_str(raw_billboard_id) {
        Some(s) => s,
        None => return Some(BillboardJsonCreateOutcome::BlankId),
    };

    let display_ad_id = match cast_active_record_bigint_bytes(raw_id_str.as_bytes()) {
        ActiveRecordIntCast::Value(n) => n,
        ActiveRecordIntCast::Null => {
            return Some(BillboardJsonCreateOutcome::Parsed {
                sql: None,
                raw_billboard_id: raw_id_str.to_owned(),
            });
        }
        ActiveRecordIntCast::DeferToRuby => return None,
    };

    let effective_article_str = if non_blank_str(top_article_id.as_deref()).is_some() {
        top_article_id.as_deref()
    } else {
        ev.article_id.as_deref()
    };

    let article_id = match effective_article_str {
        None => None,
        Some(s) => match cast_active_record_bigint_bytes(s.as_bytes()) {
            ActiveRecordIntCast::Value(n) => match i32::try_from(n) {
                Ok(v) => Some(v),
                Err(_) => return None,
            },
            ActiveRecordIntCast::Null => None,
            ActiveRecordIntCast::DeferToRuby => return None,
        },
    };

    let effective_context_type = if is_embed {
        "embed"
    } else {
        match ev.context_type.as_deref() {
            Some(c) => c,
            None => {
                return Some(BillboardJsonCreateOutcome::Parsed {
                    sql: None,
                    raw_billboard_id: raw_id_str.to_owned(),
                });
            }
        }
    };

    let category = match ev.category.as_deref() {
        Some(c) => c,
        None => {
            return Some(BillboardJsonCreateOutcome::Parsed {
                sql: None,
                raw_billboard_id: raw_id_str.to_owned(),
            });
        }
    };

    let effective_user_id = if is_embed { None } else { user_id };
    let effective_user_agent = non_blank_str(ev.user_agent.as_deref())
        .or_else(|| non_blank_str(top_user_agent.as_deref()))
        .or(header_user_agent);

    let insert_outcome = billboard_event_insert_sql(&BillboardEventInsert {
        display_ad_id,
        category,
        context_type: effective_context_type,
        user_id: effective_user_id,
        article_id,
        geolocation,
        user_agent: effective_user_agent,
        counts_for: 1,
        seconds_visible: 10,
        now_sec,
        now_usec,
        verify_billboard_exists: true,
    });

    match insert_outcome {
        BillboardEventInsertOutcome::Sql(sql) => Some(BillboardJsonCreateOutcome::Parsed {
            sql: Some(sql),
            raw_billboard_id: raw_id_str.to_owned(),
        }),
        BillboardEventInsertOutcome::Invalid => Some(BillboardJsonCreateOutcome::Parsed {
            sql: None,
            raw_billboard_id: raw_id_str.to_owned(),
        }),
        BillboardEventInsertOutcome::DeferToRuby => None,
    }
}

/// Extracted GA4 fallback page_view fields for `GaEventsController#create`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct GaEventFields {
    pub page_title: Option<String>,
    pub page_location: Option<String>,
    pub page_path: Option<String>,
    pub user_language: Option<String>,
    pub referrer: Option<String>,
    pub user_agent: Option<String>,
    pub viewport_size: Option<String>,
    pub screen_resolution: Option<String>,
    pub document_encoding: Option<String>,
}

/// Outcome of parsing a `POST /fallback_activity_recorder` JSON body.
#[allow(clippy::large_enum_variant)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum GaEventParseOutcome {
    Parsed(GaEventFields),
    InvalidJson,
    DeferToRuby,
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum GaScalarOutcome {
    Str(String),
    Null,
    InvalidJson,
    DeferToRuby,
}

impl<'a> JsonScanner<'a> {
    fn parse_ga_string_or_null(&mut self) -> GaScalarOutcome {
        self.skip_ws();
        match self.peek() {
            None => GaScalarOutcome::InvalidJson,
            Some(b'n') => {
                if self.bytes[self.pos..].starts_with(b"null") {
                    self.pos += 4;
                    GaScalarOutcome::Null
                } else {
                    GaScalarOutcome::InvalidJson
                }
            }
            Some(b'"') => {
                self.pos += 1;
                let start = self.pos;
                let mut has_escape = false;
                while self.pos < self.bytes.len() {
                    let b = self.bytes[self.pos];
                    if b == b'"' {
                        let raw = &self.bytes[start..self.pos];
                        self.pos += 1;
                        if !has_escape {
                            return match std::str::from_utf8(raw) {
                                Ok(s) => GaScalarOutcome::Str(s.to_owned()),
                                Err(_) => GaScalarOutcome::InvalidJson,
                            };
                        }
                        return match Self::unescape_simple(raw) {
                            Some(s) => GaScalarOutcome::Str(s),
                            None => GaScalarOutcome::DeferToRuby,
                        };
                    }
                    if b == b'\\' {
                        has_escape = true;
                        self.pos += 1;
                        if self.pos >= self.bytes.len() {
                            return GaScalarOutcome::InvalidJson;
                        }
                    } else if b < 0x20 {
                        return GaScalarOutcome::InvalidJson;
                    }
                    self.pos += 1;
                }
                GaScalarOutcome::InvalidJson
            }
            Some(b't' | b'f' | b'-' | b'0'..=b'9' | b'[' | b'{') => GaScalarOutcome::DeferToRuby,
            Some(_) => GaScalarOutcome::InvalidJson,
        }
    }
}

/// Parses a `POST /fallback_activity_recorder` JSON body and filters `referrer` against `app_url`.
pub fn parse_ga_event_json(json_body: &[u8], app_url: Option<&str>) -> GaEventParseOutcome {
    let mut scanner = JsonScanner::new(json_body);
    scanner.skip_ws();
    match scanner.peek() {
        None => return GaEventParseOutcome::InvalidJson,
        Some(b'{') => {
            scanner.pos += 1;
        }
        Some(b'[' | b'"' | b't' | b'f' | b'n' | b'-' | b'0'..=b'9') => {
            return GaEventParseOutcome::DeferToRuby
        }
        Some(_) => return GaEventParseOutcome::InvalidJson,
    }

    let mut fields = GaEventFields::default();
    if !scanner.consume_byte(b'}') {
        loop {
            let key = match scanner.parse_ga_string_or_null() {
                GaScalarOutcome::Str(k) => k,
                GaScalarOutcome::Null => return GaEventParseOutcome::InvalidJson,
                GaScalarOutcome::InvalidJson => return GaEventParseOutcome::InvalidJson,
                GaScalarOutcome::DeferToRuby => return GaEventParseOutcome::DeferToRuby,
            };
            if !scanner.consume_byte(b':') {
                return GaEventParseOutcome::InvalidJson;
            }
            match key.as_str() {
                "document_title" | "document_path" | "path" | "user_language" | "referrer"
                | "user_agent" | "viewport_size" | "screen_resolution" | "document_encoding" => {
                    let val = match scanner.parse_ga_string_or_null() {
                        GaScalarOutcome::Str(s) => Some(s),
                        GaScalarOutcome::Null => None,
                        GaScalarOutcome::InvalidJson => return GaEventParseOutcome::InvalidJson,
                        GaScalarOutcome::DeferToRuby => return GaEventParseOutcome::DeferToRuby,
                    };
                    match key.as_str() {
                        "document_title" => fields.page_title = val,
                        "document_path" => fields.page_location = val,
                        "path" => fields.page_path = val,
                        "user_language" => fields.user_language = val,
                        "referrer" => fields.referrer = val,
                        "user_agent" => fields.user_agent = val,
                        "viewport_size" => fields.viewport_size = val,
                        "screen_resolution" => fields.screen_resolution = val,
                        "document_encoding" => fields.document_encoding = val,
                        _ => unreachable!(),
                    }
                }
                _ => match scanner.parse_ga_string_or_null() {
                    GaScalarOutcome::Str(_) | GaScalarOutcome::Null => {}
                    GaScalarOutcome::InvalidJson => return GaEventParseOutcome::InvalidJson,
                    GaScalarOutcome::DeferToRuby => return GaEventParseOutcome::DeferToRuby,
                },
            }
            if scanner.consume_byte(b',') {
                scanner.skip_ws();
                if scanner.peek() == Some(b'}') || scanner.peek().is_none() {
                    return GaEventParseOutcome::InvalidJson;
                }
                continue;
            }
            if scanner.consume_byte(b'}') {
                break;
            }
            return GaEventParseOutcome::InvalidJson;
        }
    }
    scanner.skip_ws();
    if scanner.pos != scanner.bytes.len() {
        return GaEventParseOutcome::InvalidJson;
    }

    if let (Some(ref r), Some(prefix)) = (&fields.referrer, app_url) {
        if r.starts_with(prefix) {
            fields.referrer = None;
        }
    }

    GaEventParseOutcome::Parsed(fields)
}

/// Validated and normalized `FeedEvent` attributes for `FeedEvents::BulkUpsert`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ValidatedFeedEvent {
    pub article_id: i64,
    pub user_id: Option<i64>,
    pub article_position: i32,
    pub category: &'static str,
    pub context_type: &'static str,
    pub feed_config_id: Option<i64>,
    pub event_id: Option<String>,
}

/// Parses an integer string strictly matching Rails `NumericalityValidator` (`/\A[+-]?\d+\z/`).
#[inline]
pub fn parse_strict_integer_i64(bytes: &[u8]) -> Option<i64> {
    if bytes.is_empty() {
        return None;
    }
    let s = std::str::from_utf8(bytes).ok()?;
    let rest = s
        .strip_prefix('+')
        .or_else(|| s.strip_prefix('-'))
        .unwrap_or(s);
    if rest.is_empty() || !rest.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    s.parse::<i64>().ok()
}

/// Validates and normalizes a single `FeedEvent` entry matching `FeedEvent.new(event_data).valid?`.
pub fn validate_feed_event_fields(
    article_id: Option<i64>,
    user_id: Option<i64>,
    article_position: Option<i64>,
    category: Option<&[u8]>,
    context_type: Option<&[u8]>,
    feed_config_id: Option<i64>,
    event_id: Option<&[u8]>,
) -> Option<ValidatedFeedEvent> {
    let article_id = article_id?;
    let pos_i64 = article_position?;
    if pos_i64 <= 0 {
        return None;
    }
    let article_position = i32::try_from(pos_i64).ok()?;

    let category = match category? {
        b"impression" => "impression",
        b"click" => "click",
        b"reaction" => "reaction",
        b"comment" => "comment",
        b"extended_pageview" => "extended_pageview",
        _ => return None,
    };

    let context_type = match context_type? {
        b"home" => "home",
        b"search" => "search",
        b"tag" => "tag",
        b"email" => "email",
        b"sidebar" => "sidebar",
        _ => return None,
    };

    let event_id = match event_id {
        None => None,
        Some(bytes) => {
            if !is_valid_uuid(bytes) {
                return None;
            }
            Some(std::str::from_utf8(bytes).ok()?.to_ascii_lowercase())
        }
    };

    Some(ValidatedFeedEvent {
        article_id,
        user_id,
        article_position,
        category,
        context_type,
        feed_config_id,
        event_id,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha256_and_hmac_vectors() {
        // NIST empty string vector
        let empty = sha256(b"");
        assert_eq!(
            empty,
            [
                0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14, 0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f,
                0xb9, 0x24, 0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c, 0xa4, 0x95, 0x99, 0x1b,
                0x78, 0x52, 0xb8, 0x55
            ]
        );

        // RFC 4231 Test Case 2: key = "Jefe", data = "what do ya want for nothing?"
        let mac = hmac_sha256(b"Jefe", b"what do ya want for nothing?");
        assert_eq!(
            mac,
            [
                0x5b, 0xdc, 0xc1, 0x46, 0xbf, 0x60, 0x75, 0x4e, 0x6a, 0x04, 0x24, 0x26, 0x08, 0x95,
                0x75, 0xc7, 0x5a, 0x00, 0x3f, 0x08, 0x9d, 0x27, 0x39, 0x83, 0x9d, 0xec, 0x58, 0xb9,
                0x64, 0xec, 0x38, 0x43
            ]
        );
    }

    #[test]
    fn test_urlsafe_decode64_canonical_and_unpadded() {
        let mut buf = [0u8; 64];
        assert_eq!(
            urlsafe_decode64_into(b"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", &mut buf),
            Some(32)
        );
        assert_eq!(&buf[..32], &[0u8; 32]);
        // Non-zero trailing bit in final char is rejected just like Ruby 3.3 `strict_decode64`.
        assert_eq!(
            urlsafe_decode64_into(b"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB", &mut buf),
            None
        );
    }

    #[test]
    fn test_verify_authenticity_token_global_real_and_per_form() {
        // Real token = 32 bytes of 0x11, base64url encoded: "ERERERERERERERERERERERERERERERERERERERERERE"
        let encoded_real = b"ERERERERERERERERERERERERERERERERERERERERERE";
        // Unmasked 32-byte token equal to real_token
        assert_eq!(
            verify_authenticity_token(encoded_real, encoded_real, None, None),
            Some(true)
        );
        // Empty token
        assert_eq!(
            verify_authenticity_token(b"", encoded_real, None, None),
            Some(false)
        );
        // Invalid base64
        assert_eq!(
            verify_authenticity_token(b"not!valid!base64", encoded_real, None, None),
            Some(false)
        );
    }

    #[test]
    fn test_cast_active_record_bigint_bytes() {
        assert_eq!(
            cast_active_record_bigint_bytes(b""),
            ActiveRecordIntCast::Null
        );
        assert_eq!(
            cast_active_record_bigint_bytes(b"   \t\n"),
            ActiveRecordIntCast::Null
        );
        assert_eq!(
            cast_active_record_bigint_bytes(b"  42  "),
            ActiveRecordIntCast::Value(42)
        );
        assert_eq!(
            cast_active_record_bigint_bytes(b"-42.9"),
            ActiveRecordIntCast::Value(-42)
        );
        assert_eq!(
            cast_active_record_bigint_bytes(b"1_000"),
            ActiveRecordIntCast::Value(1000)
        );
        assert_eq!(
            cast_active_record_bigint_bytes(b"1__000"),
            ActiveRecordIntCast::Value(1)
        );
        assert_eq!(
            cast_active_record_bigint_bytes(b"not-an-id"),
            ActiveRecordIntCast::Value(0)
        );
    }

    #[test]
    fn test_billboard_event_sql_builders() {
        let update_sql = billboard_event_update_sql(
            12345,
            Some(67890),
            10,
            1_793_727_000,
            123_456,
            1_793_726_991,
            123_456,
        )
        .unwrap();
        assert_eq!(
            update_sql,
            "SET LOCAL synchronous_commit TO OFF; UPDATE \"display_ad_events\" SET seconds_visible = seconds_visible + 10, updated_at = '2026-11-03 17:30:00.123456' WHERE id = 12345 AND category = 'impression' AND (user_id IS NULL OR user_id = 67890) AND updated_at <= '2026-11-03 17:29:51.123456'"
        );

        let insert_outcome = billboard_event_insert_sql(&BillboardEventInsert {
            display_ad_id: 99,
            category: "impression",
            context_type: "home",
            user_id: Some(77),
            article_id: Some(42),
            geolocation: Some("US-NY"),
            user_agent: Some("Mozilla/5.0's test"),
            counts_for: 1,
            seconds_visible: 10,
            now_sec: 1_793_727_000,
            now_usec: 123_456,
            verify_billboard_exists: false,
        });
        assert_eq!(
            insert_outcome,
            BillboardEventInsertOutcome::Sql(
                "SET LOCAL synchronous_commit TO OFF; INSERT INTO \"display_ad_events\" (\"article_id\", \"category\", \"context_type\", \"counts_for\", \"created_at\", \"display_ad_id\", \"geolocation\", \"seconds_visible\", \"updated_at\", \"user_agent\", \"user_id\") VALUES (42, 'impression', 'home', 1, '2026-11-03 17:30:00.123456', 99, 'US-NY', 10, '2026-11-03 17:30:00.123456', 'Mozilla/5.0''s test', 77) RETURNING \"id\"".to_owned()
            )
        );
    }

    #[test]
    fn test_uuid_origin_and_lock_key() {
        assert!(is_valid_uuid(b"550e8400-e29b-41d4-a716-446655440000"));
        assert!(is_valid_uuid(b"550E8400-E29B-41D4-A716-446655440000"));
        assert!(!is_valid_uuid(b"550e8400-e29b-41d4-a716-44665544000g"));
        assert!(!is_valid_uuid(b"short"));

        assert!(origin_in_comma_list(
            b"https://embed.example.com",
            b"https://embed.example.com, https://other.example.com"
        ));
        assert!(origin_in_comma_list(
            b"https://other.example.com",
            b"https://embed.example.com, https://other.example.com"
        ));
        assert!(!origin_in_comma_list(
            b"https://evil.example.com",
            b"https://embed.example.com, https://other.example.com"
        ));
    }

    #[test]
    fn test_valid_request_origin() {
        assert_eq!(
            valid_request_origin(
                Some(b"https://dev.to/ben/some-post"),
                None,
                Some(b"http://dev.to"),
                Some(b"dev.to"),
                Some(443)
            ),
            Some(OriginValidation::Valid)
        );
        assert_eq!(
            valid_request_origin(
                Some(b"https://evil.com/phish"),
                None,
                Some(b"http://dev.to"),
                Some(b"dev.to"),
                Some(443)
            ),
            Some(OriginValidation::Invalid)
        );
        assert_eq!(
            valid_request_origin(
                None,
                Some(b"null"),
                Some(b"http://dev.to"),
                Some(b"dev.to"),
                Some(80)
            ),
            Some(OriginValidation::NullOrigin)
        );
        assert_eq!(
            valid_request_origin(
                None,
                Some(b"https://dev.to"),
                Some(b"http://dev.to"),
                Some(b"dev.to"),
                Some(80)
            ),
            Some(OriginValidation::Valid)
        );
        assert_eq!(
            valid_request_origin(
                None,
                Some(b"https://evil.com"),
                Some(b"http://dev.to"),
                Some(b"dev.to"),
                Some(80)
            ),
            Some(OriginValidation::Invalid)
        );
    }

    #[test]
    fn test_extract_referrer_domain_and_path() {
        assert_eq!(
            extract_referrer_domain_and_path(b"https://www.google.com/search?q=forem#top"),
            Some((Some("google.com".to_owned()), "/search".to_owned()))
        );
        assert_eq!(
            extract_referrer_domain_and_path(b"https://www.google.com"),
            Some((Some("google.com".to_owned()), String::new()))
        );
        assert_eq!(
            extract_referrer_domain_and_path(b"https://someone.github.io/post"),
            Some((Some("github.io".to_owned()), "/post".to_owned()))
        );
        assert_eq!(
            extract_referrer_domain_and_path(b"https://localhost:3000/articles"),
            Some((None, "/articles".to_owned()))
        );
        assert_eq!(
            extract_referrer_domain_and_path(b"test"),
            Some((None, "test".to_owned()))
        );
    }

    #[test]
    fn test_match_metal_telemetry_route() {
        assert_eq!(
            match_metal_telemetry_route(b"PATCH", b"/bb_tabulations/12345"),
            Some(MetalTelemetryRoute::BillboardUpdate("12345"))
        );
        assert_eq!(
            match_metal_telemetry_route(b"POST", b"/bb_tabulations"),
            Some(MetalTelemetryRoute::BillboardCreate)
        );
        assert_eq!(
            match_metal_telemetry_route(b"POST", b"/billboard_events"),
            Some(MetalTelemetryRoute::BillboardCreate)
        );
        assert_eq!(
            match_metal_telemetry_route(b"POST", b"/display_ad_events"),
            Some(MetalTelemetryRoute::BillboardCreate)
        );
        assert_eq!(
            match_metal_telemetry_route(b"PUT", b"/page_views/999"),
            Some(MetalTelemetryRoute::PageViewUpdate("999"))
        );
        assert_eq!(
            match_metal_telemetry_route(b"POST", b"/page_views"),
            Some(MetalTelemetryRoute::PageViewCreate)
        );
        assert_eq!(
            match_metal_telemetry_route(b"POST", b"/fallback_activity_recorder"),
            Some(MetalTelemetryRoute::GaEventCreate)
        );
        assert_eq!(
            match_metal_telemetry_route(b"POST", b"/feed_events"),
            Some(MetalTelemetryRoute::FeedEventsCreate)
        );
        assert_eq!(
            match_metal_telemetry_route(b"POST", b"/feed_config_visits"),
            Some(MetalTelemetryRoute::FeedConfigVisitsCreate)
        );
        assert_eq!(match_metal_telemetry_route(b"GET", b"/articles"), None);
    }

    #[test]
    fn test_parse_ga_event_json() {
        let valid_json = br#"{"document_title":"Hello","path":"/ben","user_language":"en","referrer":"https://google.com/"}"#;
        assert_eq!(
            parse_ga_event_json(valid_json, Some("https://dev.to")),
            GaEventParseOutcome::Parsed(GaEventFields {
                page_title: Some("Hello".to_owned()),
                page_location: None,
                page_path: Some("/ben".to_owned()),
                user_language: Some("en".to_owned()),
                referrer: Some("https://google.com/".to_owned()),
                user_agent: None,
                viewport_size: None,
                screen_resolution: None,
                document_encoding: None,
            })
        );

        let same_host_json = br#"{"path":"/ben","referrer":"https://dev.to/other"}"#;
        assert_eq!(
            parse_ga_event_json(same_host_json, Some("https://dev.to")),
            GaEventParseOutcome::Parsed(GaEventFields {
                page_path: Some("/ben".to_owned()),
                referrer: None,
                ..GaEventFields::default()
            })
        );

        assert_eq!(
            parse_ga_event_json(b"", Some("https://dev.to")),
            GaEventParseOutcome::InvalidJson
        );
        assert_eq!(
            parse_ga_event_json(
                br#"{"path":"/example","document_path":"/example"#,
                Some("https://dev.to")
            ),
            GaEventParseOutcome::InvalidJson
        );
    }

    #[test]
    fn test_validate_feed_event_fields() {
        let valid = validate_feed_event_fields(
            Some(42),
            Some(7),
            Some(3),
            Some(b"click"),
            Some(b"home"),
            Some(99),
            Some(b"550e8400-e29b-41d4-a716-446655440000"),
        );
        assert_eq!(
            valid,
            Some(ValidatedFeedEvent {
                article_id: 42,
                user_id: Some(7),
                article_position: 3,
                category: "click",
                context_type: "home",
                feed_config_id: Some(99),
                event_id: Some("550e8400-e29b-41d4-a716-446655440000".to_owned()),
            })
        );

        assert_eq!(
            validate_feed_event_fields(
                Some(42),
                Some(7),
                Some(0),
                Some(b"click"),
                Some(b"home"),
                None,
                None
            ),
            None
        );
        assert_eq!(
            validate_feed_event_fields(
                Some(42),
                Some(7),
                Some(1),
                Some(b"invalid"),
                Some(b"home"),
                None,
                None
            ),
            None
        );
        assert_eq!(
            validate_feed_event_fields(
                Some(42),
                Some(7),
                Some(1),
                Some(b"click"),
                Some(b"home"),
                None,
                Some(b"not-a-uuid")
            ),
            None
        );
    }

    #[test]
    fn test_billboard_event_create_from_json_sql() {
        let json = br#"{"billboard_event":{"billboard_id":"555","context_type":"home","category":"impression","article_id":"42","user_agent":"Mozilla/5.0"}}"#;
        let res = billboard_event_create_from_json_sql(
            json,
            Some(77),
            Some("US-NY"),
            Some("FallbackUA"),
            false,
            1_793_727_000,
            123_456,
        );
        match res {
            Some(BillboardJsonCreateOutcome::Parsed {
                sql: Some(sql),
                raw_billboard_id,
            }) => {
                assert_eq!(raw_billboard_id, "555");
                assert!(sql.contains("SELECT 42, 'impression', 'home', 1"));
                assert!(sql.ends_with(
                    "WHERE EXISTS (SELECT 1 FROM \"display_ads\" WHERE \"display_ads\".\"id\" = 555) RETURNING \"id\""
                ));
            }
            other => panic!("unexpected outcome: {other:?}"),
        }

        let blank_json = br#"{"billboard_event":{"billboard_id":"","context_type":"home","category":"impression"}}"#;
        assert_eq!(
            billboard_event_create_from_json_sql(
                blank_json,
                Some(77),
                None,
                None,
                false,
                1_793_727_000,
                0
            ),
            Some(BillboardJsonCreateOutcome::BlankId)
        );
    }
}
