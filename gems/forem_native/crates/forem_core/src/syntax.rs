//! Pure-Rust syntax highlighting engine and Rouge-compatible language registry.
//!
//! Replaces the runtime `rouge` Ruby gem across:
//! - `Redcarpet::Render::HTMLRouge#block_code` (`highlight_code_block`)
//! - `AgentSessionRenderers::MarkdownRenderer.highlight_tagged_code_blocks` (`highlight_html`)
//! - `AgentSessionsHelper#rouge_highlight` and `#language_from_path` (`highlight_html`, `language_from_path`)
//! - `Articles::DetectCodeBlockLanguages` (`supported_language_tags`, `language_criteria`, `normalize_language_tag`)

use crate::syntax_data::{
    LexerFamily, LEXER_FAMILIES, LEXER_TAGS, LEXER_TITLES, MIMETYPE_ENTRIES, REGISTRY_ENTRIES,
};

const PLAINTEXT_TAG: &str = "plaintext";
const PLAINTEXT_CRITERIA: &str = "Plain text, console output, or no specific language";

/// Returns the static slice of all 228 sorted canonical language tags, matching
/// `(Rouge::Lexer.all.filter_map(&:tag) + ["plaintext"]).uniq.sort`.
#[inline]
pub fn supported_language_tags() -> &'static [&'static str] {
    &LEXER_TAGS
}

/// Returns `(tag, title_or_criteria)` pairs for all 228 supported language tags, matching
/// `Articles::DetectCodeBlockLanguages.language_criteria`.
#[inline]
pub fn language_criteria_entries() -> impl Iterator<Item = (&'static str, &'static str)> {
    LEXER_TAGS
        .iter()
        .copied()
        .zip(LEXER_TITLES.iter().copied())
        .map(|(tag, title)| {
            let desc = if tag == PLAINTEXT_TAG {
                PLAINTEXT_CRITERIA
            } else {
                title
            };
            (tag, desc)
        })
}

/// Looks up a lexer by exact name or alias in the 392-entry Rouge registry, returning its
/// canonical index into `LEXER_TAGS`, matching `Rouge::Lexer.find(name)`.
#[inline]
fn find_lexer_index(name: &str) -> Option<usize> {
    if name == "plain" {
        return REGISTRY_ENTRIES
            .binary_search_by_key(&PLAINTEXT_TAG.as_bytes(), |(k, _)| k.as_bytes())
            .ok()
            .map(|pos| REGISTRY_ENTRIES[pos].1 as usize);
    }
    REGISTRY_ENTRIES
        .binary_search_by_key(&name.as_bytes(), |(k, _)| k.as_bytes())
        .ok()
        .map(|pos| REGISTRY_ENTRIES[pos].1 as usize)
}

/// Looks up a lexer by name or alias in the 392-entry Rouge registry and returns its
/// canonical tag (e.g. `"js"` -> `Some("javascript")`), matching `Rouge::Lexer.find(name)&.tag`.
#[inline]
pub fn find_lexer_tag(name: &str) -> Option<&'static str> {
    find_lexer_index(name).map(|idx| LEXER_TAGS[idx])
}

/// Normalizes an arbitrary language hint to a canonical supported Rouge tag, falling back to
/// `"plaintext"` when blank or unrecognized, matching
/// `Articles::DetectCodeBlockLanguages#normalize_language`.
#[inline]
pub fn normalize_language_tag(language: &str) -> &'static str {
    let trimmed = language
        .trim()
        .trim_start_matches('`')
        .trim_end_matches('`')
        .trim();
    let token = trimmed.split_ascii_whitespace().next().unwrap_or("");
    if token.is_empty() {
        return PLAINTEXT_TAG;
    }
    if token.bytes().all(|b| !b.is_ascii_uppercase()) {
        return find_lexer_tag(token).unwrap_or(PLAINTEXT_TAG);
    }
    let lower = token.to_ascii_lowercase();
    find_lexer_tag(&lower).unwrap_or(PLAINTEXT_TAG)
}

/// Resolves a lexer tag using `Rouge::Lexer.find_fancy` semantics:
/// - Handles direct lookup when `lang` has no `'?'` and is not `"guess"`.
/// - Parses CGI query options (e.g. `"ruby?start_inline=1"` or `"guess?mimetype=text/x-ruby"`).
/// - Supports `"guess"` (or `None`) via MIME type, Emacs/Vim modelines, and shebang/doctype/source
///   detection heuristics.
/// - When `rescue_ambiguous` is `true` (as in `Rouge::Plugins::Redcarpet`), returns the first
///   matching lexer on ambiguous guesses; when `false`, returns `None` on ambiguous guesses.
pub fn find_fancy_tag(
    lang: Option<&str>,
    code: Option<&str>,
    rescue_ambiguous: bool,
) -> Option<&'static str> {
    if let Some(s) = lang {
        if !s.contains('?') && s != "guess" {
            return find_lexer_tag(s);
        }
    }

    let (name, query) = match lang {
        Some(s) => match s.split_once('?') {
            Some((n, q)) => (Some(n), q),
            None => (Some(s), ""),
        },
        None => (None, ""),
    };

    match name {
        None | Some("guess") => {
            let mimetype = extract_query_param(query, "mimetype");
            guess_lexer_tag(code, mimetype.as_deref(), rescue_ambiguous)
        }
        Some(n) => find_lexer_tag(n),
    }
}

/// Extracts the file extension from the first whitespace-delimited token in `path` and resolves
/// its canonical Rouge lexer tag, matching `AgentSessionsHelper#language_from_path`.
pub fn language_from_path(path: &str) -> Option<&'static str> {
    let trimmed = path.trim();
    if trimmed.is_empty() {
        return None;
    }
    let token = trimmed.split_whitespace().next()?;
    if token.as_bytes().contains(&0) {
        return None;
    }
    let without_trailing_slash = token.trim_end_matches('/');
    let file_name = without_trailing_slash
        .rsplit('/')
        .next()
        .unwrap_or(without_trailing_slash);
    let dot_pos = file_name.rfind('.')?;
    if !file_name[..dot_pos].bytes().any(|b| b != b'.') {
        return None;
    }
    let ext = &file_name[dot_pos + 1..];
    if ext.is_empty() {
        return None;
    }
    find_fancy_tag(Some(ext), None, false).or_else(|| find_lexer_tag(ext))
}

/// Highlights `code` for `lang` and returns the inner HTML token stream (without outer `<pre><code>`
/// wrappers), matching `Rouge::Formatters::HTML.new.format(lexer.lex(code))`.
pub fn highlight_html(code: &str, lang: Option<&str>) -> String {
    let lexer_idx = lang
        .and_then(|l| {
            find_lexer_index(l).or_else(|| {
                let lower = l.trim().to_ascii_lowercase();
                find_lexer_index(&lower)
            })
        })
        .unwrap_or_else(|| find_lexer_index(PLAINTEXT_TAG).unwrap_or(0));

    let mut out = String::with_capacity(code.len() + (code.len() / 2));
    highlight_into(&mut out, code, lexer_idx);
    out
}

/// Highlights a fenced Markdown code block for `Redcarpet::Render::HTMLRouge#block_code`,
/// returning `<div class="highlight"><pre class="highlight {tag}"><code>{highlighted}</code></pre></div>`.
pub fn highlight_code_block(code: &str, language: Option<&str>) -> String {
    let normalized = language.unwrap_or("").to_ascii_lowercase();
    let tag = find_fancy_tag(Some(&normalized), Some(code), true).unwrap_or(PLAINTEXT_TAG);
    let lexer_idx = find_lexer_index(tag).unwrap_or(0);

    // Match Rouge::Plugins::Redcarpet's Makefile leading-4-space-to-tab normalization
    let processed_code;
    let source = if tag == "make" && (code.starts_with("    ") || code.contains("\n    ")) {
        processed_code = replace_leading_four_spaces_with_tab(code);
        processed_code.as_str()
    } else {
        code
    };

    let mut out = String::with_capacity(source.len() + (source.len() / 2) + 80);
    out.push_str("<div class=\"highlight\"><pre class=\"highlight ");
    out.push_str(tag);
    out.push_str("\"><code>");
    highlight_into(&mut out, source, lexer_idx);
    out.push_str("</code></pre></div>");
    out
}

fn replace_leading_four_spaces_with_tab(code: &str) -> String {
    let mut out = String::with_capacity(code.len());
    for (idx, line) in code.split('\n').enumerate() {
        if idx > 0 {
            out.push('\n');
        }
        if let Some(rest) = line.strip_prefix("    ") {
            out.push('\t');
            out.push_str(rest);
        } else {
            out.push_str(line);
        }
    }
    out
}

fn extract_query_param(query: &str, target_key: &str) -> Option<String> {
    if query.is_empty() {
        return None;
    }
    let mut last_val: Option<String> = None;
    for pair in query.split('&') {
        if pair.is_empty() {
            continue;
        }
        let (k, v) = pair.split_once('=').unwrap_or((pair, ""));
        if url_decode(k) == target_key {
            last_val = Some(url_decode(v));
        }
    }
    last_val
}

fn url_decode(input: &str) -> String {
    let bytes = input.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'+' => {
                out.push(b' ');
                i += 1;
            }
            b'%' if i + 2 < bytes.len() => {
                if let (Some(hi), Some(lo)) = (hex_val(bytes[i + 1]), hex_val(bytes[i + 2])) {
                    out.push((hi << 4) | lo);
                    i += 3;
                } else {
                    out.push(bytes[i]);
                    i += 1;
                }
            }
            b => {
                out.push(b);
                i += 1;
            }
        }
    }
    String::from_utf8_lossy(&out).into_owned()
}

#[inline]
fn hex_val(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

fn guess_lexer_tag(
    code: Option<&str>,
    mimetype: Option<&str>,
    rescue_ambiguous: bool,
) -> Option<&'static str> {
    if let Some(mt) = mimetype {
        let mut matches = MIMETYPE_ENTRIES
            .iter()
            .filter(|&&(m, _)| m == mt)
            .map(|&(_, idx)| LEXER_TAGS[idx as usize]);
        if let Some(first) = matches.next() {
            if matches.next().is_none() || rescue_ambiguous {
                return Some(first);
            }
            return None;
        }
    }

    if let Some(src) = code {
        if let Some(tag) = detect_modeline(src).or_else(|| detect_source(src)) {
            return Some(tag);
        }
    }

    Some(PLAINTEXT_TAG)
}

fn detect_modeline(src: &str) -> Option<&'static str> {
    let first_lines = src.lines().take(5).chain(src.lines().rev().take(5));
    for line in first_lines {
        let lower = line.to_ascii_lowercase();
        if let Some(start) = lower.find("-*-") {
            let rest = &lower[start + 3..];
            if let Some(end) = rest.find("-*-") {
                let inner = rest[..end].trim();
                let mode = if let Some(m_pos) = inner.find("mode:") {
                    inner[m_pos + 5..].split(';').next().unwrap_or("").trim()
                } else {
                    inner
                };
                if !mode.is_empty() {
                    if let Some(tag) = find_lexer_tag(mode) {
                        return Some(tag);
                    }
                }
            }
        }
        if let Some(vpos) = lower.find("vim:").or_else(|| lower.find("vi:")) {
            let after = &lower[vpos..];
            for key in ["ft=", "filetype=", "syntax="] {
                if let Some(kpos) = after.find(key) {
                    let val: String = after[kpos + key.len()..]
                        .chars()
                        .take_while(|c| c.is_ascii_alphanumeric() || *c == '_' || *c == '-')
                        .collect();
                    if let Some(tag) = find_lexer_tag(&val) {
                        return Some(tag);
                    }
                }
            }
        }
    }
    None
}

fn extract_shebang(src: &str) -> Option<&str> {
    let trimmed = src.trim_start();
    let rest = trimmed.strip_prefix("#!")?;
    Some(rest.lines().next().unwrap_or(rest))
}

fn shebang_has_word(shebang: &str, word: &str) -> bool {
    let bytes = shebang.as_bytes();
    let wbytes = word.as_bytes();
    if wbytes.is_empty() || wbytes.len() > bytes.len() {
        return false;
    }
    let mut i = 0;
    while i + wbytes.len() <= bytes.len() {
        if &bytes[i..i + wbytes.len()] == wbytes {
            let left_ok = i == 0 || !is_ident_continue(bytes[i - 1]);
            let right_idx = i + wbytes.len();
            let right_ok = right_idx == bytes.len() || bytes[right_idx].is_ascii_whitespace();
            if left_ok && right_ok {
                return true;
            }
        }
        i += 1;
    }
    false
}

fn detect_source(src: &str) -> Option<&'static str> {
    if let Some(sb) = extract_shebang(src) {
        for (word, tag) in [
            ("awk", "awk"),
            ("coffee", "coffeescript"),
            ("crystal", "crystal"),
            ("elixir", "elixir"),
            ("factor", "factor"),
            ("gherkin", "gherkin"),
            ("node", "javascript"),
            ("jsc", "javascript"),
            ("groovy", "groovy"),
            ("php", "php"),
            ("runhaskell", "haskell"),
            ("haxe", "haxe"),
            ("io", "io"),
            ("ruby", "ruby"),
            ("macruby", "ruby"),
            ("rbx", "ruby"),
            ("jruby", "ruby"),
            ("julia", "julia"),
            ("lasso", "lasso"),
            ("lsc", "livescript"),
            ("lua", "lua"),
            ("luajit", "lua"),
            ("mojo", "mojo"),
            ("moon", "moonscript"),
            ("perl", "perl"),
            ("praat", "praat"),
            ("puppet-apply", "puppet"),
            ("puppet", "puppet"),
            ("Rscript", "r"),
            ("rustc", "rust"),
            ("sed", "sed"),
            ("bash", "shell"),
            ("zsh", "shell"),
            ("ksh", "shell"),
            ("sh", "shell"),
            ("tclsh", "tcl"),
            ("wish", "tcl"),
            ("jimsh", "tcl"),
            ("tulip", "tulip"),
        ] {
            if shebang_has_word(sb, word) {
                return Some(tag);
            }
        }
        if sb.contains("python") {
            return Some("python");
        }
    }

    let trimmed = src.trim_start();
    if trimmed.starts_with("<!DOCTYPE html")
        || trimmed.starts_with("<!doctype html")
        || trimmed.starts_with("<html")
    {
        return Some("html");
    }
    if trimmed.starts_with("<?xml") || trimmed.starts_with("<!DOCTYPE ") {
        return Some("xml");
    }
    if trimmed.starts_with("<?php") {
        return Some("php");
    }
    if trimmed.starts_with("<?hh") {
        return Some("hack");
    }
    if trimmed.starts_with("%YAML") {
        return Some("yaml");
    }
    if src.starts_with("Index: ")
        || src.starts_with("diff ")
        || (src.contains("---") && src.contains("+++"))
    {
        return Some("diff");
    }
    if src.starts_with("#compdef") || src.starts_with("#autoload") {
        return Some("shell");
    }
    if let Some(rest) = src.strip_prefix("#lang ") {
        let lang_line = rest.lines().next().unwrap_or("");
        if lang_line.contains("racket") || lang_line.contains("scribble") {
            return Some("racket");
        }
    }
    if trimmed.starts_with("\\documentclass")
        || trimmed.starts_with("\\input")
        || trimmed.starts_with("\\documentstyle")
        || trimmed.starts_with("\\ProvidesPackage")
        || trimmed.starts_with("\\ProvidesClass")
    {
        return Some("tex");
    }
    if src.starts_with("%!PS-Adobe") {
        return Some("postscript");
    }
    if src.contains("<Biml") || src.contains("< Biml") {
        return Some("biml");
    }
    None
}

// ============================================================================
// Token Emission & HTML Escaping
// ============================================================================

struct TokenEmitter<'a> {
    out: &'a mut String,
    last_class: Option<&'static str>,
}

impl<'a> TokenEmitter<'a> {
    #[inline]
    fn new(out: &'a mut String) -> Self {
        Self {
            out,
            last_class: None,
        }
    }

    #[inline]
    fn close_active(&mut self) {
        if self.last_class.take().is_some() {
            self.out.push_str("</span>");
        }
    }

    #[inline]
    fn push_text(&mut self, text: &str) {
        if text.is_empty() {
            return;
        }
        self.close_active();
        push_escaped_html(self.out, text);
    }

    #[inline]
    fn push_token(&mut self, class: &'static str, text: &str) {
        if text.is_empty() {
            return;
        }
        if class.is_empty() {
            self.push_text(text);
            return;
        }
        if self.last_class != Some(class) {
            self.close_active();
            self.out.push_str("<span class=\"");
            self.out.push_str(class);
            self.out.push_str("\">");
            self.last_class = Some(class);
        }
        push_escaped_html(self.out, text);
    }

    /// Emits a non-consolidating `<span class="...">` token so adjacent punctuation tokens
    /// (such as `{` and `}`) remain distinct DOM nodes for `unescape_raw_tag_in_codeblocks`.
    #[inline]
    fn push_isolated_token(&mut self, class: &'static str, text: &str) {
        if text.is_empty() {
            return;
        }
        self.close_active();
        self.out.push_str("<span class=\"");
        self.out.push_str(class);
        self.out.push_str("\">");
        push_escaped_html(self.out, text);
        self.out.push_str("</span>");
    }

    #[inline]
    fn finish(mut self) {
        self.close_active();
    }
}

#[inline]
fn push_escaped_html(out: &mut String, text: &str) {
    let bytes = text.as_bytes();
    let mut last = 0;
    for (i, &b) in bytes.iter().enumerate() {
        let rep = match b {
            b'&' => "&amp;",
            b'<' => "&lt;",
            b'>' => "&gt;",
            _ => continue,
        };
        if i > last {
            out.push_str(&text[last..i]);
        }
        out.push_str(rep);
        last = i + 1;
    }
    if last < bytes.len() {
        out.push_str(&text[last..]);
    }
}

// ============================================================================
// Dispatcher across all 34 LexerFamily modes
// ============================================================================

fn highlight_into(out: &mut String, code: &str, lexer_idx: usize) {
    if code.is_empty() {
        return;
    }
    let family = LEXER_FAMILIES
        .get(lexer_idx)
        .copied()
        .unwrap_or(LexerFamily::PlainText);

    match family {
        LexerFamily::PlainText => push_escaped_html(out, code),
        LexerFamily::Diff => highlight_diff(out, code),
        LexerFamily::Json => highlight_json(out, code, false),
        LexerFamily::Json5 => highlight_json(out, code, true),
        LexerFamily::Yaml => highlight_yaml(out, code),
        LexerFamily::TomlIni => highlight_toml_ini(out, code),
        LexerFamily::HtmlXml => highlight_markup(out, code, false),
        LexerFamily::TemplateMarkup => highlight_markup(out, code, true),
        LexerFamily::EmberGjsGts => highlight_ember_gjs(out, code),
        LexerFamily::Css => highlight_css(out, code),
        LexerFamily::Markdown => highlight_markdown(out, code),
        LexerFamily::Shell => highlight_shell(out, code, false),
        LexerFamily::Make => highlight_shell(out, code, true),
        LexerFamily::Batch => highlight_code_with_profile(out, code, &PROFILE_BATCH),
        LexerFamily::PowerShell => highlight_code_with_profile(out, code, &PROFILE_POWERSHELL),
        LexerFamily::Sql => highlight_code_with_profile(out, code, &PROFILE_SQL),
        LexerFamily::Lisp => highlight_lisp(out, code),
        LexerFamily::Ruby => highlight_code_with_profile(out, code, &PROFILE_RUBY),
        LexerFamily::Python => highlight_code_with_profile(out, code, &PROFILE_PYTHON),
        LexerFamily::JsTs => highlight_code_with_profile(out, code, &PROFILE_JSTS),
        LexerFamily::Rust => highlight_code_with_profile(out, code, &PROFILE_RUST),
        LexerFamily::Go => highlight_code_with_profile(out, code, &PROFILE_GO),
        LexerFamily::CFamily => highlight_code_with_profile(out, code, &PROFILE_CFAMILY),
        LexerFamily::CSharpJava => highlight_code_with_profile(out, code, &PROFILE_CSHARP_JAVA),
        LexerFamily::Swift => highlight_code_with_profile(out, code, &PROFILE_SWIFT),
        LexerFamily::Php => highlight_code_with_profile(out, code, &PROFILE_PHP),
        LexerFamily::ElixirErlang => highlight_code_with_profile(out, code, &PROFILE_ELIXIR),
        LexerFamily::FunctionalMl => highlight_code_with_profile(out, code, &PROFILE_ML_HASKELL),
        LexerFamily::Lua => highlight_code_with_profile(out, code, &PROFILE_LUA),
        LexerFamily::Perl => highlight_code_with_profile(out, code, &PROFILE_PERL),
        LexerFamily::Scientific => highlight_code_with_profile(out, code, &PROFILE_SCIENTIFIC),
        LexerFamily::PascalAda => highlight_code_with_profile(out, code, &PROFILE_PASCAL_ADA),
        LexerFamily::Basic => highlight_code_with_profile(out, code, &PROFILE_BASIC),
        LexerFamily::Assembly => highlight_code_with_profile(out, code, &PROFILE_ASSEMBLY),
    }
}

// ============================================================================
// Specialized Lexers: Diff, JSON, YAML, TOML/INI, Markup, Ember GJS/GTS, CSS,
// Markdown, Shell/Make, Lisp
// ============================================================================

fn highlight_diff(out: &mut String, code: &str) {
    let mut em = TokenEmitter::new(out);
    for full_line in code.split_inclusive('\n') {
        let (line, nl) = match full_line.strip_suffix('\n') {
            Some(stripped) => (stripped, "\n"),
            None => (full_line, ""),
        };
        if !line.is_empty() {
            if line.starts_with("+++") || line.starts_with('+') || line.starts_with('>') {
                em.push_token("gi", line);
            } else if line.starts_with("---") || line.starts_with('-') || line.starts_with('<') {
                em.push_token("gd", line);
            } else if line.starts_with("@@")
                || line.starts_with("diff ")
                || line.starts_with("Index: ")
                || line.starts_with("===")
                || line.starts_with('!')
            {
                em.push_token("gu", line);
            } else {
                em.push_text(line);
            }
        }
        if !nl.is_empty() {
            em.push_text(nl);
        }
    }
    em.finish();
}

fn highlight_json(out: &mut String, code: &str, allow_extensions: bool) {
    let mut em = TokenEmitter::new(out);
    let bytes = code.as_bytes();
    let mut i = 0;

    while i < bytes.len() {
        let b = bytes[i];
        if b.is_ascii_whitespace() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_text(&code[start..i]);
        } else if allow_extensions && b == b'/' && bytes.get(i + 1) == Some(&b'/') {
            let start = i;
            i = scan_line_end(bytes, i + 2);
            em.push_token("c1", &code[start..i]);
        } else if allow_extensions && b == b'/' && bytes.get(i + 1) == Some(&b'*') {
            let start = i;
            i = scan_block_comment(bytes, i + 2, b"*/");
            em.push_token("cm", &code[start..i]);
        } else if allow_extensions && b == b'#' {
            let start = i;
            i = scan_line_end(bytes, i + 1);
            em.push_token("c1", &code[start..i]);
        } else if b == b'"' || (allow_extensions && b == b'\'') {
            let start = i;
            i = scan_quoted_string(bytes, i, b);
            let mut look = i;
            while look < bytes.len() && (bytes[look] == b' ' || bytes[look] == b'\t') {
                look += 1;
            }
            let cls = if bytes.get(look) == Some(&b':') {
                "nl"
            } else if b == b'\'' {
                "s1"
            } else {
                "s2"
            };
            em.push_token(cls, &code[start..i]);
        } else if b.is_ascii_digit()
            || (b == b'-' && bytes.get(i + 1).is_some_and(u8::is_ascii_digit))
        {
            let start = i;
            let (end, cls) = scan_number(bytes, i);
            i = end;
            em.push_token(cls, &code[start..i]);
        } else if is_ident_start(b) {
            let start = i;
            i = scan_ident(bytes, i);
            let word = &code[start..i];
            let mut look = i;
            while look < bytes.len() && (bytes[look] == b' ' || bytes[look] == b'\t') {
                look += 1;
            }
            let cls = if allow_extensions && bytes.get(look) == Some(&b':') {
                "nl"
            } else if matches!(word, "true" | "false" | "null" | "Infinity" | "NaN") {
                "kc"
            } else {
                "n"
            };
            em.push_token(cls, word);
        } else if matches!(b, b'{' | b'}' | b'[' | b']' | b':' | b',') {
            em.push_isolated_token("p", &code[i..i + 1]);
            i += 1;
        } else {
            let ch_len = utf8_char_len(bytes[i]);
            let end = (i + ch_len).min(bytes.len());
            em.push_token("err", &code[i..end]);
            i = end;
        }
    }
    em.finish();
}

fn highlight_yaml(out: &mut String, code: &str) {
    let mut em = TokenEmitter::new(out);
    for line in code.split_inclusive('\n') {
        let trimmed = line.trim_start_matches([' ', '\t']);
        let indent_len = line.len() - trimmed.len();
        if indent_len > 0 {
            em.push_text(&line[..indent_len]);
        }
        if trimmed.starts_with('#') {
            em.push_token("c1", trimmed);
            continue;
        }
        if trimmed.starts_with("---") || trimmed.starts_with("...") || trimmed.starts_with('%') {
            em.push_token("nn", trimmed);
            continue;
        }
        highlight_yaml_line(&mut em, trimmed);
    }
    em.finish();
}

fn highlight_yaml_line(em: &mut TokenEmitter<'_>, mut rest: &str) {
    if let Some(after_dash) = rest.strip_prefix("- ") {
        em.push_token("p", "-");
        em.push_text(" ");
        rest = after_dash;
    }
    if let Some(colon_idx) = find_yaml_colon(rest) {
        let key = &rest[..colon_idx];
        em.push_token("na", key);
        em.push_token("p", ":");
        rest = &rest[colon_idx + 1..];
    }
    let bytes = rest.as_bytes();
    let mut i = 0;
    let mut flow_depth: usize = 0;
    while i < bytes.len() {
        let b = bytes[i];
        if bytes[i..].starts_with(b"{----% raw %----}")
            || bytes[i..].starts_with(b"{----% endraw %----}")
        {
            let marker = if bytes[i..].starts_with(b"{----% raw %----}") {
                "raw"
            } else {
                "endraw"
            };
            let len = if marker == "raw" { 17 } else { 20 };
            em.push_isolated_token("p", "{");
            em.push_isolated_token("o", "----%");
            em.push_text(" ");
            em.push_isolated_token("n", marker);
            em.push_text(" ");
            em.push_isolated_token("o", "%----");
            em.push_isolated_token("p", "}");
            i += len;
        } else if b.is_ascii_whitespace() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_text(&rest[start..i]);
        } else if b == b'#' && (i == 0 || bytes[i - 1].is_ascii_whitespace()) {
            em.push_token("c1", &rest[i..]);
            break;
        } else if b == b'"' || b == b'\'' {
            let start = i;
            i = scan_quoted_string(bytes, i, b);
            em.push_token(if b == b'\'' { "s1" } else { "s2" }, &rest[start..i]);
        } else if b == b'&' || b == b'*' {
            let start = i;
            i += 1;
            while i < bytes.len() && !bytes[i].is_ascii_whitespace() && bytes[i] != b',' {
                i += 1;
            }
            em.push_token("nv", &rest[start..i]);
        } else if b == b'!' {
            let start = i;
            i += 1;
            while i < bytes.len() && !bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_token("kt", &rest[start..i]);
        } else if matches!(b, b'{' | b'}' | b'[' | b']' | b',' | b'|' | b'>') {
            if matches!(b, b'{' | b'[') {
                flow_depth += 1;
            } else if matches!(b, b'}' | b']') {
                flow_depth = flow_depth.saturating_sub(1);
            }
            em.push_isolated_token("p", &rest[i..i + 1]);
            i += 1;
        } else {
            let start = i;
            if flow_depth > 0 {
                while i < bytes.len()
                    && !bytes[i].is_ascii_whitespace()
                    && !matches!(bytes[i], b',' | b']' | b'}')
                {
                    i += 1;
                }
            } else {
                while i < bytes.len() && !matches!(bytes[i], b'\n' | b'\r') {
                    if bytes[i] == b'#' && i > start && bytes[i - 1].is_ascii_whitespace() {
                        break;
                    }
                    if bytes[i..].starts_with(b"{----% raw %----}")
                        || bytes[i..].starts_with(b"{----% endraw %----}")
                    {
                        break;
                    }
                    i += 1;
                }
                while i > start && matches!(bytes[i - 1], b' ' | b'\t') {
                    i -= 1;
                }
            }
            let val = &rest[start..i];
            let cls = if matches!(
                val,
                "true" | "false" | "null" | "yes" | "no" | "on" | "off" | "~" | "True" | "False"
            ) {
                "kc"
            } else if val
                .bytes()
                .all(|c| c.is_ascii_digit() || c == b'.' || c == b'-')
                && val.bytes().any(|c| c.is_ascii_digit())
            {
                if val.contains('.') {
                    "mf"
                } else {
                    "mi"
                }
            } else {
                "s"
            };
            em.push_token(cls, val);
        }
    }
}

fn find_yaml_colon(s: &str) -> Option<usize> {
    let bytes = s.as_bytes();
    if bytes.is_empty() || matches!(bytes[0], b'{' | b'[') {
        return None;
    }
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b':' && (i + 1 == bytes.len() || bytes[i + 1].is_ascii_whitespace()) {
            return Some(i);
        }
        if matches!(bytes[i], b'#' | b'\n' | b'\r') {
            return None;
        }
        i += 1;
    }
    None
}

fn highlight_toml_ini(out: &mut String, code: &str) {
    let mut em = TokenEmitter::new(out);
    for line in code.split_inclusive('\n') {
        let trimmed = line.trim_start_matches([' ', '\t']);
        let indent = line.len() - trimmed.len();
        if indent > 0 {
            em.push_text(&line[..indent]);
        }
        if trimmed.starts_with('#') || trimmed.starts_with(';') {
            em.push_token("c1", trimmed);
        } else if trimmed.starts_with('[') {
            if let Some(close) = trimmed.find(']') {
                let end = if trimmed.as_bytes().get(close + 1) == Some(&b']') {
                    close + 2
                } else {
                    close + 1
                };
                em.push_token("k", &trimmed[..end]);
                highlight_code_with_profile_em(&mut em, &trimmed[end..], &PROFILE_GO);
            } else {
                highlight_code_with_profile_em(&mut em, trimmed, &PROFILE_GO);
            }
        } else if let Some(eq_idx) = trimmed.find('=') {
            let key = &trimmed[..eq_idx];
            if !key.contains('"') && !key.contains('\'') {
                let key_trimmed = key.trim_end();
                em.push_token("na", key_trimmed);
                em.push_text(&key[key_trimmed.len()..]);
                em.push_token("o", "=");
                highlight_code_with_profile_em(&mut em, &trimmed[eq_idx + 1..], &PROFILE_GO);
            } else {
                highlight_code_with_profile_em(&mut em, trimmed, &PROFILE_GO);
            }
        } else {
            highlight_code_with_profile_em(&mut em, trimmed, &PROFILE_GO);
        }
    }
    em.finish();
}

fn highlight_ember_gjs(out: &mut String, code: &str) {
    let mut em = TokenEmitter::new(out);
    let mut pos = 0;
    while pos < code.len() {
        if let Some(rel_open) = code[pos..].find("<template") {
            let open_start = pos + rel_open;
            if open_start > pos {
                highlight_code_with_profile_em(&mut em, &code[pos..open_start], &PROFILE_JSTS);
            }
            let after_kw = open_start + "<template".len();
            if let Some(rel_gt) = code[after_kw..].find('>') {
                let gt_pos = after_kw + rel_gt;
                em.push_token("nt", "<");
                em.push_token("k", "template");
                if gt_pos > after_kw {
                    highlight_markup_attrs(&mut em, &code[after_kw..gt_pos]);
                }
                em.push_token("nt", ">");
                pos = gt_pos + 1;
                if let Some(rel_close) = code[pos..].find("</template>") {
                    let close_start = pos + rel_close;
                    highlight_markup_em(&mut em, &code[pos..close_start], true);
                    em.push_token("nt", "</");
                    em.push_token("k", "template");
                    em.push_token("nt", ">");
                    pos = close_start + "</template>".len();
                } else {
                    highlight_markup_em(&mut em, &code[pos..], true);
                    break;
                }
            } else {
                highlight_code_with_profile_em(&mut em, &code[open_start..], &PROFILE_JSTS);
                break;
            }
        } else {
            highlight_code_with_profile_em(&mut em, &code[pos..], &PROFILE_JSTS);
            break;
        }
    }
    em.finish();
}

fn highlight_markup(out: &mut String, code: &str, allow_templates: bool) {
    let mut em = TokenEmitter::new(out);
    highlight_markup_em(&mut em, code, allow_templates);
    em.finish();
}

fn highlight_markup_em(em: &mut TokenEmitter<'_>, code: &str, allow_templates: bool) {
    let bytes = code.as_bytes();
    let mut i = 0;

    while i < bytes.len() {
        if bytes[i..].starts_with(b"{----% raw %----}")
            || bytes[i..].starts_with(b"{----% endraw %----}")
        {
            let marker = if bytes[i..].starts_with(b"{----% raw %----}") {
                "raw"
            } else {
                "endraw"
            };
            let len = if marker == "raw" { 17 } else { 20 };
            em.push_isolated_token("p", "{");
            em.push_isolated_token("o", "----%");
            em.push_text(" ");
            em.push_isolated_token("nt", marker);
            em.push_text(" ");
            em.push_isolated_token("o", "%----");
            em.push_isolated_token("p", "}");
            i += len;
            continue;
        }
        if allow_templates && (bytes[i..].starts_with(b"{{") || bytes[i..].starts_with(b"{%")) {
            let is_brace = bytes[i + 1] == b'{';
            let close_delim: &[u8] = if is_brace { b"}}" } else { b"%}" };
            em.push_isolated_token("cp", &code[i..i + 2]);
            i += 2;
            let start = i;
            let end_expr = find_subslice(bytes, i, close_delim).unwrap_or(bytes.len());
            highlight_code_with_profile_em(em, &code[start..end_expr], &PROFILE_RUBY);
            if end_expr < bytes.len() {
                em.push_isolated_token("cp", &code[end_expr..end_expr + 2]);
                i = end_expr + 2;
            } else {
                i = bytes.len();
            }
            continue;
        }
        if allow_templates && bytes[i..].starts_with(b"<%") {
            let open_len = if matches!(bytes.get(i + 2), Some(b'=' | b'-' | b'#')) {
                3
            } else {
                2
            };
            em.push_token("cp", &code[i..i + open_len]);
            i += open_len;
            let start = i;
            let end_expr = find_subslice(bytes, i, b"%>").unwrap_or(bytes.len());
            highlight_code_with_profile_em(em, &code[start..end_expr], &PROFILE_RUBY);
            if end_expr < bytes.len() {
                em.push_token("cp", "%>");
                i = end_expr + 2;
            } else {
                i = bytes.len();
            }
            continue;
        }
        if bytes[i..].starts_with(b"<!--") {
            let start = i;
            i = scan_block_comment(bytes, i + 4, b"-->");
            em.push_token("c", &code[start..i]);
        } else if bytes[i..].starts_with(b"<![CDATA[") {
            let start = i;
            i = scan_block_comment(bytes, i + 9, b"]]>");
            em.push_token("cp", &code[start..i]);
        } else if bytes[i..].starts_with(b"<!") || bytes[i..].starts_with(b"<?") {
            let start = i;
            i = scan_until_byte(bytes, i + 2, b'>');
            em.push_token("cp", &code[start..i]);
        } else if bytes[i] == b'<'
            && bytes
                .get(i + 1)
                .is_some_and(|&c| c.is_ascii_alphabetic() || c == b'/' || c == b'!')
        {
            let tag_open = i;
            i += 1;
            if bytes.get(i) == Some(&b'/') {
                i += 1;
            }
            while i < bytes.len()
                && (bytes[i].is_ascii_alphanumeric()
                    || matches!(bytes[i], b'-' | b'_' | b':' | b'.'))
            {
                i += 1;
            }
            let tag_head = &code[tag_open..i];
            let lower_tag = tag_head.trim_start_matches(['<', '/']).to_ascii_lowercase();
            em.push_token("nt", tag_head);

            let attr_start = i;
            let mut in_quote: Option<u8> = None;
            while i < bytes.len() {
                let c = bytes[i];
                if let Some(q) = in_quote {
                    if c == q {
                        in_quote = None;
                    }
                    i += 1;
                } else if c == b'"' || c == b'\'' {
                    in_quote = Some(c);
                    i += 1;
                } else if c == b'>' {
                    break;
                } else {
                    i += 1;
                }
            }
            let attr_slice = &code[attr_start..i];
            let self_closing = attr_slice.ends_with('/');
            let clean_attrs = if self_closing {
                &attr_slice[..attr_slice.len() - 1]
            } else {
                attr_slice
            };
            highlight_markup_attrs(em, clean_attrs);
            if i < bytes.len() && bytes[i] == b'>' {
                em.push_token("nt", if self_closing { "/>" } else { ">" });
                i += 1;
                if !self_closing && !tag_head.starts_with("</") {
                    if lower_tag == "script" {
                        let close_idx =
                            find_case_insensitive(code, i, "</script").unwrap_or(code.len());
                        highlight_code_with_profile_em(em, &code[i..close_idx], &PROFILE_JSTS);
                        i = close_idx;
                    } else if lower_tag == "style" {
                        let close_idx =
                            find_case_insensitive(code, i, "</style").unwrap_or(code.len());
                        highlight_css_em(em, &code[i..close_idx]);
                        i = close_idx;
                    }
                }
            }
        } else if bytes[i] == b'&' {
            let start = i;
            i += 1;
            while i < bytes.len()
                && i - start <= 12
                && (bytes[i].is_ascii_alphanumeric() || bytes[i] == b'#')
            {
                i += 1;
            }
            if i < bytes.len() && bytes[i] == b';' {
                i += 1;
                em.push_token("ni", &code[start..i]);
            } else {
                em.push_text(&code[start..i]);
            }
        } else {
            let start = i;
            i += 1;
            while i < bytes.len() && !matches!(bytes[i], b'<' | b'&' | b'{') {
                i += 1;
            }
            em.push_text(&code[start..i]);
        }
    }
}

fn highlight_markup_attrs(em: &mut TokenEmitter<'_>, attrs: &str) {
    let bytes = attrs.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        let b = bytes[i];
        if b.is_ascii_whitespace() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_text(&attrs[start..i]);
        } else if b == b'"' || b == b'\'' {
            let start = i;
            i = scan_quoted_string(bytes, i, b);
            em.push_token("s", &attrs[start..i]);
        } else if b == b'=' {
            em.push_token("o", "=");
            i += 1;
        } else if b == b'{' && bytes.get(i + 1) == Some(&b'{') {
            let end_expr = find_subslice(bytes, i + 2, b"}}").unwrap_or(bytes.len());
            em.push_token("k", "{{");
            if end_expr > i + 2 {
                em.push_token("na", &attrs[i + 2..end_expr]);
            }
            if end_expr < bytes.len() {
                em.push_token("k", "}}");
                i = end_expr + 2;
            } else {
                i = bytes.len();
            }
        } else {
            let start = i;
            while i < bytes.len()
                && !bytes[i].is_ascii_whitespace()
                && !matches!(bytes[i], b'=' | b'"' | b'\'' | b'{')
            {
                i += 1;
            }
            em.push_token("na", &attrs[start..i]);
        }
    }
}

fn highlight_css(out: &mut String, code: &str) {
    let mut em = TokenEmitter::new(out);
    highlight_css_em(&mut em, code);
    em.finish();
}

fn highlight_css_em(em: &mut TokenEmitter<'_>, code: &str) {
    let bytes = code.as_bytes();
    let mut i = 0;
    let mut brace_depth = 0usize;

    while i < bytes.len() {
        let b = bytes[i];
        if b.is_ascii_whitespace() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_text(&code[start..i]);
        } else if b == b'/' && bytes.get(i + 1) == Some(&b'*') {
            let start = i;
            i = scan_block_comment(bytes, i + 2, b"*/");
            em.push_token("cm", &code[start..i]);
        } else if b == b'/' && bytes.get(i + 1) == Some(&b'/') {
            let start = i;
            i = scan_line_end(bytes, i + 2);
            em.push_token("c1", &code[start..i]);
        } else if b == b'"' || b == b'\'' {
            let start = i;
            i = scan_quoted_string(bytes, i, b);
            em.push_token(if b == b'\'' { "s1" } else { "s2" }, &code[start..i]);
        } else if b == b'{' {
            brace_depth += 1;
            em.push_isolated_token("p", "{");
            i += 1;
        } else if b == b'}' {
            brace_depth = brace_depth.saturating_sub(1);
            em.push_isolated_token("p", "}");
            i += 1;
        } else if b == b'@' || b == b'$' {
            let start = i;
            i += 1;
            while i < bytes.len()
                && (bytes[i].is_ascii_alphanumeric() || matches!(bytes[i], b'-' | b'_'))
            {
                i += 1;
            }
            em.push_token(if b == b'@' { "k" } else { "nv" }, &code[start..i]);
        } else if b == b'#' {
            let start = i;
            i += 1;
            while i < bytes.len()
                && (bytes[i].is_ascii_alphanumeric() || matches!(bytes[i], b'-' | b'_'))
            {
                i += 1;
            }
            let cls = if brace_depth > 0
                && i > start + 1
                && code[start + 1..i].bytes().all(|c| c.is_ascii_hexdigit())
            {
                "mh"
            } else {
                "nn"
            };
            em.push_token(cls, &code[start..i]);
        } else if b == b'.'
            && bytes
                .get(i + 1)
                .is_some_and(|&c| c.is_ascii_alphabetic() || c == b'-' || c == b'_')
        {
            let start = i;
            i += 1;
            while i < bytes.len()
                && (bytes[i].is_ascii_alphanumeric() || matches!(bytes[i], b'-' | b'_'))
            {
                i += 1;
            }
            em.push_token("nc", &code[start..i]);
        } else if b.is_ascii_digit() {
            let start = i;
            let (end, num_cls) = scan_number(bytes, i);
            i = end;
            em.push_token(num_cls, &code[start..i]);
            let unit_start = i;
            while i < bytes.len() && (bytes[i].is_ascii_alphabetic() || bytes[i] == b'%') {
                i += 1;
            }
            if i > unit_start {
                em.push_token("kt", &code[unit_start..i]);
            }
        } else if b.is_ascii_alphabetic() || b == b'-' || b == b'_' {
            let start = i;
            while i < bytes.len()
                && (bytes[i].is_ascii_alphanumeric() || matches!(bytes[i], b'-' | b'_'))
            {
                i += 1;
            }
            let word = &code[start..i];
            let cls = if word.starts_with("--") {
                "nv"
            } else if bytes.get(i) == Some(&b'(') {
                "nf"
            } else if brace_depth > 0 && bytes.get(i) == Some(&b':') {
                "nl"
            } else if brace_depth == 0 {
                "nt"
            } else {
                "n"
            };
            em.push_token(cls, word);
        } else if matches!(b, b':' | b';' | b',' | b'(' | b')' | b'[' | b']') {
            em.push_isolated_token("p", &code[i..i + 1]);
            i += 1;
        } else {
            let ch_len = utf8_char_len(b);
            let end = (i + ch_len).min(bytes.len());
            em.push_token("o", &code[i..end]);
            i = end;
        }
    }
}

fn highlight_markdown(out: &mut String, code: &str) {
    let mut em = TokenEmitter::new(out);
    for line in code.split_inclusive('\n') {
        let trimmed = line.trim_start_matches([' ', '\t']);
        if trimmed.starts_with('#') {
            em.push_token("gu", line);
        } else if trimmed.starts_with('>') {
            em.push_token("ge", line);
        } else if trimmed.starts_with("```") || trimmed.starts_with("~~~") {
            em.push_token("k", line);
        } else if trimmed.starts_with("- ")
            || trimmed.starts_with("* ")
            || trimmed.starts_with("+ ")
        {
            let indent = line.len() - trimmed.len();
            if indent > 0 {
                em.push_text(&line[..indent]);
            }
            em.push_token("k", &trimmed[..2]);
            highlight_markdown_inline(&mut em, &trimmed[2..]);
        } else {
            highlight_markdown_inline(&mut em, line);
        }
    }
    em.finish();
}

fn highlight_markdown_inline(em: &mut TokenEmitter<'_>, line: &str) {
    let bytes = line.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'`' {
            let start = i;
            i += 1;
            while i < bytes.len() && bytes[i] != b'`' {
                i += 1;
            }
            if i < bytes.len() {
                i += 1;
            }
            em.push_token("sb", &line[start..i]);
        } else if bytes[i..].starts_with(b"**") {
            if let Some(rel) = line[i + 2..].find("**") {
                let end = i + 2 + rel + 2;
                em.push_token("gs", &line[i..end]);
                i = end;
            } else {
                em.push_text("**");
                i += 2;
            }
        } else {
            let start = i;
            i += 1;
            while i < bytes.len() && !matches!(bytes[i], b'`' | b'*') {
                i += 1;
            }
            em.push_text(&line[start..i]);
        }
    }
}

fn highlight_shell(out: &mut String, code: &str, is_makefile: bool) {
    let mut em = TokenEmitter::new(out);
    if is_makefile {
        for line in code.split_inclusive('\n') {
            if !line.starts_with('\t') && !line.starts_with('#') {
                if let Some(colon_idx) = line.find(':') {
                    let target = &line[..colon_idx];
                    if !target.is_empty()
                        && !target.contains('=')
                        && !target.contains('$')
                        && !target.trim().is_empty()
                    {
                        em.push_token("nl", target);
                        em.push_token("o", ":");
                        highlight_shell_code(&mut em, &line[colon_idx + 1..]);
                        continue;
                    }
                }
            }
            highlight_shell_code(&mut em, line);
        }
    } else {
        highlight_shell_code(&mut em, code);
    }
    em.finish();
}

fn highlight_shell_code(em: &mut TokenEmitter<'_>, code: &str) {
    let bytes = code.as_bytes();
    let mut i = 0;

    while i < bytes.len() {
        let b = bytes[i];
        if bytes[i..].starts_with(b"{----% raw %----}")
            || bytes[i..].starts_with(b"{----% endraw %----}")
        {
            let marker = if bytes[i..].starts_with(b"{----% raw %----}") {
                "raw"
            } else {
                "endraw"
            };
            let len = if marker == "raw" { 17 } else { 20 };
            em.push_isolated_token("p", "{");
            em.push_isolated_token("o", "----%");
            em.push_text(" ");
            em.push_isolated_token("n", marker);
            em.push_text(" ");
            em.push_isolated_token("o", "%----");
            em.push_isolated_token("p", "}");
            i += len;
        } else if b.is_ascii_whitespace() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_text(&code[start..i]);
        } else if b == b'#' && (i == 0 || bytes[i - 1].is_ascii_whitespace()) {
            let start = i;
            i = scan_line_end(bytes, i + 1);
            em.push_token("c", &code[start..i]);
        } else if b == b'"' || b == b'\'' || b == b'`' {
            let start = i;
            i = scan_quoted_string(bytes, i, b);
            let cls = match b {
                b'\'' => "s1",
                b'`' => "sb",
                _ => "s2",
            };
            em.push_token(cls, &code[start..i]);
        } else if b == b'$'
            && bytes.get(i + 1).is_some_and(|&c| {
                is_ident_start(c)
                    || c.is_ascii_digit()
                    || matches!(c, b'{' | b'(' | b'@' | b'*' | b'?' | b'!' | b'#')
            })
        {
            let start = i;
            i += 1;
            if bytes.get(i) == Some(&b'{') {
                i = scan_until_byte(bytes, i + 1, b'}');
            } else if is_ident_start(bytes[i]) {
                i = scan_ident(bytes, i);
            } else {
                i += 1;
            }
            em.push_token("nv", &code[start..i]);
        } else if matches!(b, b'{' | b'}' | b'(' | b')' | b'[' | b']' | b';') {
            em.push_isolated_token("o", &code[i..i + 1]);
            i += 1;
        } else if matches!(b, b'|' | b'&' | b'>' | b'<' | b'=') {
            let start = i;
            i += 1;
            while i < bytes.len() && matches!(bytes[i], b'|' | b'&' | b'>' | b'<' | b'=') {
                i += 1;
            }
            em.push_token("o", &code[start..i]);
        } else {
            let start = i;
            while i < bytes.len()
                && !bytes[i].is_ascii_whitespace()
                && !matches!(
                    bytes[i],
                    b'"' | b'\''
                        | b'`'
                        | b'$'
                        | b'{'
                        | b'}'
                        | b'('
                        | b')'
                        | b'['
                        | b']'
                        | b';'
                        | b'|'
                        | b'&'
                        | b'>'
                        | b'<'
                )
            {
                if bytes[i] == b'='
                    && i > start
                    && bytes[start..i].iter().copied().all(is_ident_continue)
                {
                    break;
                }
                i += 1;
            }
            let word = &code[start..i];
            if bytes.get(i) == Some(&b'=')
                && !word.is_empty()
                && is_ident_start(word.as_bytes()[0])
                && word.bytes().all(is_ident_continue)
            {
                em.push_token("nv", word);
                em.push_token("o", "=");
                i += 1;
            } else if PROFILE_SHELL.keywords.binary_search(&word).is_ok() {
                em.push_token("k", word);
            } else if PROFILE_SHELL.declarations.binary_search(&word).is_ok() {
                em.push_token("kd", word);
            } else if PROFILE_SHELL.constants.binary_search(&word).is_ok() {
                em.push_token("kc", word);
            } else if PROFILE_SHELL.builtins.binary_search(&word).is_ok() {
                em.push_token("nb", word);
            } else {
                em.push_text(word);
            }
        }
    }
}

fn highlight_lisp(out: &mut String, code: &str) {
    let mut em = TokenEmitter::new(out);
    let bytes = code.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        let b = bytes[i];
        if b.is_ascii_whitespace() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_text(&code[start..i]);
        } else if b == b';' {
            let start = i;
            i = scan_line_end(bytes, i + 1);
            em.push_token("c1", &code[start..i]);
        } else if b == b'"' {
            let start = i;
            i = scan_quoted_string(bytes, i, b'"');
            em.push_token("s2", &code[start..i]);
        } else if matches!(b, b'(' | b')' | b'[' | b']' | b'{' | b'}') {
            em.push_isolated_token("p", &code[i..i + 1]);
            i += 1;
        } else if b == b':' || b == b'\'' {
            let start = i;
            i += 1;
            while i < bytes.len()
                && !bytes[i].is_ascii_whitespace()
                && !matches!(
                    bytes[i],
                    b'(' | b')' | b'[' | b']' | b'{' | b'}' | b';' | b'"'
                )
            {
                i += 1;
            }
            em.push_token("ss", &code[start..i]);
        } else if b.is_ascii_digit()
            || (b == b'-' && bytes.get(i + 1).is_some_and(u8::is_ascii_digit))
        {
            let start = i;
            let (end, cls) = scan_number(bytes, i);
            i = end;
            em.push_token(cls, &code[start..i]);
        } else {
            let start = i;
            while i < bytes.len()
                && !bytes[i].is_ascii_whitespace()
                && !matches!(
                    bytes[i],
                    b'(' | b')' | b'[' | b']' | b'{' | b'}' | b';' | b'"'
                )
            {
                i += 1;
            }
            let sym = &code[start..i];
            let cls = if matches!(
                sym,
                "def"
                    | "defn"
                    | "defn-"
                    | "defmacro"
                    | "defstruct"
                    | "defprotocol"
                    | "defrecord"
                    | "deftype"
                    | "define"
                    | "define-syntax"
                    | "defun"
                    | "defvar"
                    | "defparameter"
                    | "fn"
                    | "lambda"
                    | "let"
                    | "let*"
                    | "if"
                    | "cond"
                    | "case"
                    | "when"
                    | "unless"
                    | "do"
                    | "loop"
                    | "recur"
                    | "ns"
                    | "require"
                    | "import"
                    | "use"
                    | "quote"
                    | "set!"
                    | "begin"
            ) {
                "k"
            } else if matches!(sym, "true" | "false" | "nil" | "#t" | "#f") {
                "kc"
            } else {
                "nv"
            };
            em.push_token(cls, sym);
        }
    }
    em.finish();
}

// ============================================================================
// Parameterized Programming Language Tokenizer (`CodeProfile`)
// ============================================================================

struct CodeProfile {
    slash_comments: bool,
    hash_comments: bool,
    dash_comments: bool,
    percent_comments: bool,
    semi_comments: bool,
    apostrophe_comments: bool,
    c_preprocessor: bool,
    rust_lifetimes_and_macros: bool,
    ruby_symbols_and_ivars: bool,
    dollar_vars: bool,
    triple_quotes: bool,
    backtick_strings: bool,
    case_insensitive_keywords: bool,
    keywords: &'static [&'static str],
    declarations: &'static [&'static str],
    types: &'static [&'static str],
    constants: &'static [&'static str],
    builtins: &'static [&'static str],
}

fn highlight_code_with_profile(out: &mut String, code: &str, profile: &CodeProfile) {
    let mut em = TokenEmitter::new(out);
    highlight_code_with_profile_em(&mut em, code, profile);
    em.finish();
}

fn highlight_code_with_profile_em(em: &mut TokenEmitter<'_>, code: &str, profile: &CodeProfile) {
    let bytes = code.as_bytes();
    let mut i = 0;
    let mut prev_was_def_kw = false;

    while i < bytes.len() {
        let b = bytes[i];

        // Preserve Forem's Liquid `{----% raw %----}` and `{----% endraw %----}` escape markers
        // with isolated `{`, `raw`/`endraw`, and `}` child tokens so `unescape_raw_tag_in_codeblocks`
        // reliably strips `"----"` across all languages.
        if b == b'{'
            && (bytes[i..].starts_with(b"{----% raw %----}")
                || bytes[i..].starts_with(b"{----% endraw %----}"))
        {
            let marker = if bytes[i..].starts_with(b"{----% raw %----}") {
                "raw"
            } else {
                "endraw"
            };
            let len = if marker == "raw" { 17 } else { 20 };
            em.push_isolated_token("p", "{");
            em.push_isolated_token("o", "----%");
            em.push_text(" ");
            em.push_isolated_token("n", marker);
            em.push_text(" ");
            em.push_isolated_token("o", "%----");
            em.push_isolated_token("p", "}");
            i += len;
            prev_was_def_kw = false;
            continue;
        }

        // 1. Whitespace
        if b.is_ascii_whitespace() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_whitespace() {
                i += 1;
            }
            em.push_text(&code[start..i]);
            continue;
        }

        // 2. Comments & Preprocessor Directives
        if profile.slash_comments && b == b'/' && bytes.get(i + 1) == Some(&b'/') {
            let start = i;
            i = scan_line_end(bytes, i + 2);
            em.push_token("c1", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.slash_comments && b == b'/' && bytes.get(i + 1) == Some(&b'*') {
            let start = i;
            i = scan_block_comment(bytes, i + 2, b"*/");
            em.push_token("cm", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.hash_comments && b == b'#' {
            if profile.rust_lifetimes_and_macros
                && (bytes.get(i + 1) == Some(&b'[')
                    || (bytes.get(i + 1) == Some(&b'!') && bytes.get(i + 2) == Some(&b'[')))
            {
                let start = i;
                i = scan_until_byte(bytes, i + 1, b']');
                em.push_token("cp", &code[start..i]);
            } else {
                let start = i;
                i = scan_line_end(bytes, i + 1);
                em.push_token("c1", &code[start..i]);
            }
            prev_was_def_kw = false;
            continue;
        }
        if profile.c_preprocessor && b == b'#' {
            let start = i;
            i = scan_line_end(bytes, i + 1);
            em.push_token("cp", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.dash_comments && b == b'-' && bytes.get(i + 1) == Some(&b'-') {
            let start = i;
            if bytes[i..].starts_with(b"--[[") {
                i = scan_block_comment(bytes, i + 4, b"]]");
                em.push_token("cm", &code[start..i]);
            } else {
                i = scan_line_end(bytes, i + 2);
                em.push_token("c1", &code[start..i]);
            }
            prev_was_def_kw = false;
            continue;
        }
        if profile.dash_comments && b == b'(' && bytes.get(i + 1) == Some(&b'*') {
            let start = i;
            i = scan_block_comment(bytes, i + 2, b"*)");
            em.push_token("cm", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.dash_comments && b == b'{' && bytes.get(i + 1) == Some(&b'-') {
            let start = i;
            i = scan_block_comment(bytes, i + 2, b"-}");
            em.push_token("cm", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.percent_comments && b == b'%' {
            let start = i;
            i = scan_line_end(bytes, i + 1);
            em.push_token("c1", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.semi_comments && b == b';' {
            let start = i;
            i = scan_line_end(bytes, i + 1);
            em.push_token("c1", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.apostrophe_comments && b == b'\'' {
            let start = i;
            i = scan_line_end(bytes, i + 1);
            em.push_token("c1", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 3. Triple-quoted strings (`"""..."""` or `'''...'''`)
        if profile.triple_quotes
            && (bytes[i..].starts_with(b"\"\"\"") || bytes[i..].starts_with(b"'''"))
        {
            let delim = &bytes[i..i + 3];
            let start = i;
            i = scan_block_comment(bytes, i + 3, delim);
            em.push_token("s2", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 4. Rust raw strings `r#"..."#` / `r"..."`
        if profile.rust_lifetimes_and_macros && b == b'r' {
            let mut hashes = 0usize;
            while bytes.get(i + 1 + hashes) == Some(&b'#') {
                hashes += 1;
            }
            if bytes.get(i + 1 + hashes) == Some(&b'"') {
                let start = i;
                i += 2 + hashes;
                while i < bytes.len() {
                    if bytes[i] == b'"'
                        && i + hashes < bytes.len()
                        && bytes[i + 1..i + 1 + hashes].iter().all(|&c| c == b'#')
                    {
                        i += 1 + hashes;
                        break;
                    }
                    i += 1;
                }
                em.push_token("s2", &code[start..i]);
                prev_was_def_kw = false;
                continue;
            }
        }

        // 5. Quoted strings & char literals / Rust lifetimes
        if b == b'"' {
            let start = i;
            i = scan_quoted_string(bytes, i, b'"');
            em.push_token("s2", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if b == b'\'' {
            if profile.rust_lifetimes_and_macros
                && bytes.get(i + 1).is_some_and(|&c| is_ident_start(c))
            {
                let ident_end = scan_ident(bytes, i + 1);
                if bytes.get(ident_end) != Some(&b'\'') {
                    em.push_token("kt", &code[i..ident_end]);
                    i = ident_end;
                    prev_was_def_kw = false;
                    continue;
                }
            }
            let start = i;
            i = scan_quoted_string(bytes, i, b'\'');
            em.push_token("s1", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }
        if profile.backtick_strings && b == b'`' {
            let start = i;
            i = scan_quoted_string(bytes, i, b'`');
            em.push_token("sb", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 6. Ruby/Elixir symbols `:symbol`
        if profile.ruby_symbols_and_ivars
            && b == b':'
            && bytes.get(i + 1).is_some_and(|&c| is_ident_start(c))
            && (i == 0 || bytes[i - 1] != b':')
        {
            let start = i;
            i = scan_ident_with_suffix(bytes, i + 1);
            em.push_token("ss", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 7. `@ivar` / `@@cvar` / `@decorator`
        if b == b'@'
            && (i == 0 || !is_ident_continue(bytes[i - 1]))
            && bytes
                .get(i + 1)
                .is_some_and(|&c| is_ident_start(c) || c == b'@')
        {
            let start = i;
            i += 1;
            if bytes.get(i) == Some(&b'@') {
                i += 1;
            }
            i = scan_ident(bytes, i);
            let cls = if profile.ruby_symbols_and_ivars {
                if code[start..i].starts_with("@@") {
                    "vc"
                } else {
                    "vi"
                }
            } else {
                "nd"
            };
            em.push_token(cls, &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 8. `$variable` in Shell / PHP / Perl / JS
        if profile.dollar_vars
            && b == b'$'
            && bytes.get(i + 1).is_some_and(|&c| {
                is_ident_start(c)
                    || c.is_ascii_digit()
                    || matches!(c, b'{' | b'(' | b'@' | b'*' | b'?' | b'!' | b'#')
            })
        {
            let start = i;
            i += 1;
            if bytes.get(i) == Some(&b'{') {
                i = scan_until_byte(bytes, i + 1, b'}');
            } else if is_ident_start(bytes[i]) {
                i = scan_ident(bytes, i);
            } else {
                i += 1;
            }
            em.push_token("nv", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 9. Numbers (Hex, Binary, Octal, Float, Integer)
        if b.is_ascii_digit() {
            let start = i;
            let (end, cls) = scan_number(bytes, i);
            i = end;
            em.push_token(cls, &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 10. Identifiers, Keywords, Types, Builtins, Function names
        if is_ident_start(b) {
            let start = i;
            i = if profile.ruby_symbols_and_ivars {
                scan_ident_with_suffix(bytes, i)
            } else {
                scan_ident(bytes, i)
            };
            if profile.rust_lifetimes_and_macros && bytes.get(i) == Some(&b'!') {
                i += 1;
                em.push_token("nf", &code[start..i]);
                prev_was_def_kw = false;
                continue;
            }
            let word = &code[start..i];
            if prev_was_def_kw {
                let cls = if b.is_ascii_uppercase() { "nc" } else { "nf" };
                em.push_token(cls, word);
                prev_was_def_kw = false;
                continue;
            }

            let cls = classify_word(word, bytes.get(i).copied(), profile);
            prev_was_def_kw = matches!(
                word,
                "def"
                    | "fn"
                    | "func"
                    | "function"
                    | "fun"
                    | "sub"
                    | "proc"
                    | "class"
                    | "struct"
                    | "enum"
                    | "trait"
                    | "interface"
                    | "module"
                    | "mod"
            );
            em.push_token(cls, word);
            continue;
        }

        // 11. Single-character Punctuation (isolated for `{` and `}`)
        if matches!(
            b,
            b'{' | b'}' | b'(' | b')' | b'[' | b']' | b',' | b';' | b'.'
        ) {
            em.push_isolated_token("p", &code[i..i + 1]);
            i += 1;
            prev_was_def_kw = false;
            continue;
        }
        if b == b':' && bytes.get(i + 1) != Some(&b':') && bytes.get(i + 1) != Some(&b'=') {
            em.push_isolated_token("p", ":");
            i += 1;
            prev_was_def_kw = false;
            continue;
        }

        // 12. Operators
        if is_operator_byte(b) {
            let start = i;
            i += 1;
            while i < bytes.len() && is_operator_byte(bytes[i]) {
                i += 1;
            }
            em.push_token("o", &code[start..i]);
            prev_was_def_kw = false;
            continue;
        }

        // 13. Non-ASCII / Unicode characters (identifiers or text)
        let ch_len = utf8_char_len(b);
        let end = (i + ch_len).min(bytes.len());
        em.push_text(&code[i..end]);
        i = end;
        prev_was_def_kw = false;
    }
}

fn classify_word(word: &str, next_byte: Option<u8>, profile: &CodeProfile) -> &'static str {
    let lookup_buf;
    let key = if profile.case_insensitive_keywords && word.bytes().any(|b| b.is_ascii_uppercase()) {
        lookup_buf = word.to_ascii_lowercase();
        lookup_buf.as_str()
    } else {
        word
    };

    if profile.keywords.binary_search(&key).is_ok() {
        return "k";
    }
    if profile.declarations.binary_search(&key).is_ok() {
        return "kd";
    }
    if profile.types.binary_search(&key).is_ok() {
        return "kt";
    }
    if profile.constants.binary_search(&key).is_ok() {
        return "kc";
    }
    if profile.builtins.binary_search(&key).is_ok() {
        return "nb";
    }
    if matches!(key, "and" | "or" | "not" | "xor") {
        return "ow";
    }
    let first = word.as_bytes()[0];
    if first.is_ascii_uppercase() {
        if word
            .bytes()
            .all(|b| b.is_ascii_uppercase() || b.is_ascii_digit() || b == b'_')
        {
            return "no";
        }
        return "nc";
    }
    if next_byte == Some(b'(') {
        return "nf";
    }
    "n"
}

// ============================================================================
// Low-level Scanners
// ============================================================================

#[inline]
fn is_ident_start(b: u8) -> bool {
    b.is_ascii_alphabetic() || b == b'_'
}

#[inline]
fn is_ident_continue(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'_'
}

#[inline]
fn is_operator_byte(b: u8) -> bool {
    matches!(
        b,
        b'+' | b'-'
            | b'*'
            | b'/'
            | b'%'
            | b'='
            | b'!'
            | b'<'
            | b'>'
            | b'&'
            | b'|'
            | b'^'
            | b'~'
            | b'?'
            | b':'
    )
}

#[inline]
fn utf8_char_len(b: u8) -> usize {
    match b {
        0x00..=0x7F => 1,
        0xC0..=0xDF => 2,
        0xE0..=0xEF => 3,
        0xF0..=0xF7 => 4,
        _ => 1,
    }
}

#[inline]
fn scan_quoted_string(bytes: &[u8], start: usize, quote: u8) -> usize {
    let mut i = start + 1;
    while i < bytes.len() {
        let b = bytes[i];
        if b == b'\\' {
            i += 1;
            if i < bytes.len() {
                i = (i + utf8_char_len(bytes[i])).min(bytes.len());
            }
        } else if b == quote {
            return i + 1;
        } else {
            i += 1;
        }
    }
    bytes.len()
}

#[inline]
fn scan_ident(bytes: &[u8], mut i: usize) -> usize {
    while i < bytes.len() && is_ident_continue(bytes[i]) {
        i += 1;
    }
    i
}

#[inline]
fn scan_ident_with_suffix(bytes: &[u8], i: usize) -> usize {
    let mut end = scan_ident(bytes, i);
    if matches!(bytes.get(end), Some(b'?' | b'!')) && bytes.get(end + 1) != Some(&b'=') {
        end += 1;
    }
    end
}

#[inline]
fn scan_line_end(bytes: &[u8], mut i: usize) -> usize {
    while i < bytes.len() && bytes[i] != b'\n' {
        i += 1;
    }
    i
}

#[inline]
fn scan_until_byte(bytes: &[u8], mut i: usize, target: u8) -> usize {
    while i < bytes.len() {
        if bytes[i] == target {
            return i + 1;
        }
        i += 1;
    }
    bytes.len()
}

#[inline]
fn scan_block_comment(bytes: &[u8], mut i: usize, close: &[u8]) -> usize {
    while i + close.len() <= bytes.len() {
        if &bytes[i..i + close.len()] == close {
            return i + close.len();
        }
        i += 1;
    }
    bytes.len()
}

#[inline]
fn find_subslice(bytes: &[u8], mut i: usize, needle: &[u8]) -> Option<usize> {
    while i + needle.len() <= bytes.len() {
        if &bytes[i..i + needle.len()] == needle {
            return Some(i);
        }
        i += 1;
    }
    None
}

fn find_case_insensitive(haystack: &str, from: usize, needle_lower: &str) -> Option<usize> {
    let hbytes = haystack.as_bytes();
    let nbytes = needle_lower.as_bytes();
    if from + nbytes.len() > hbytes.len() {
        return None;
    }
    for i in from..=hbytes.len() - nbytes.len() {
        if hbytes[i..i + nbytes.len()]
            .iter()
            .zip(nbytes.iter())
            .all(|(&a, &b)| a.to_ascii_lowercase() == b)
        {
            return Some(i);
        }
    }
    None
}

fn scan_number(bytes: &[u8], start: usize) -> (usize, &'static str) {
    let mut i = start;
    if bytes[i] == b'-' {
        i += 1;
    }
    if bytes.get(i) == Some(&b'0') {
        match bytes.get(i + 1) {
            Some(b'x' | b'X') => {
                i += 2;
                while i < bytes.len() && (bytes[i].is_ascii_hexdigit() || bytes[i] == b'_') {
                    i += 1;
                }
                return (i, "mh");
            }
            Some(b'b' | b'B') => {
                i += 2;
                while i < bytes.len() && matches!(bytes[i], b'0' | b'1' | b'_') {
                    i += 1;
                }
                return (i, "mb");
            }
            Some(b'o' | b'O') => {
                i += 2;
                while i < bytes.len() && matches!(bytes[i], b'0'..=b'7' | b'_') {
                    i += 1;
                }
                return (i, "mo");
            }
            _ => {}
        }
    }
    let mut is_float = false;
    while i < bytes.len() && (bytes[i].is_ascii_digit() || bytes[i] == b'_') {
        i += 1;
    }
    if bytes.get(i) == Some(&b'.') && bytes.get(i + 1).is_some_and(u8::is_ascii_digit) {
        is_float = true;
        i += 1;
        while i < bytes.len() && (bytes[i].is_ascii_digit() || bytes[i] == b'_') {
            i += 1;
        }
    }
    if matches!(bytes.get(i), Some(b'e' | b'E')) {
        is_float = true;
        i += 1;
        if matches!(bytes.get(i), Some(b'+' | b'-')) {
            i += 1;
        }
        while i < bytes.len() && (bytes[i].is_ascii_digit() || bytes[i] == b'_') {
            i += 1;
        }
    }
    while i < bytes.len() && (bytes[i].is_ascii_alphabetic() || bytes[i] == b'_') {
        i += 1;
    }
    (i, if is_float { "mf" } else { "mi" })
}

// ============================================================================
// Sorted Static Language Profiles
// ============================================================================

static PROFILE_RUBY: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: true,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "BEGIN", "END", "alias", "begin", "break", "case", "class", "def", "defined?", "do",
        "else", "elsif", "end", "ensure", "for", "if", "in", "module", "next", "redo", "rescue",
        "retry", "return", "super", "then", "undef", "unless", "until", "when", "while", "yield",
    ],
    declarations: &[
        "attr_accessor",
        "attr_reader",
        "attr_writer",
        "extend",
        "include",
        "prepend",
        "private",
        "protected",
        "public",
    ],
    types: &[],
    constants: &[
        "__Encoding__",
        "__FILE__",
        "__LINE__",
        "false",
        "nil",
        "true",
    ],
    builtins: &[
        "abort",
        "autoload",
        "binding",
        "block_given?",
        "caller",
        "catch",
        "eval",
        "exec",
        "exit",
        "exit!",
        "fail",
        "fork",
        "format",
        "freeze",
        "gets",
        "global_variables",
        "lambda",
        "load",
        "local_variables",
        "loop",
        "open",
        "p",
        "print",
        "printf",
        "proc",
        "putc",
        "puts",
        "raise",
        "rand",
        "readline",
        "readlines",
        "require",
        "require_relative",
        "select",
        "self",
        "sleep",
        "spawn",
        "sprintf",
        "srand",
        "syscall",
        "system",
        "test",
        "throw",
        "trace_var",
        "trap",
        "untrace_var",
        "warn",
    ],
};

static PROFILE_PYTHON: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: true,
    backtick_strings: false,
    case_insensitive_keywords: false,
    keywords: &[
        "as", "assert", "async", "await", "break", "case", "class", "continue", "def", "del",
        "elif", "else", "except", "exec", "finally", "for", "from", "global", "if", "import", "in",
        "is", "lambda", "match", "nonlocal", "pass", "print", "raise", "return", "try", "while",
        "with", "yield",
    ],
    declarations: &["type", "var"],
    types: &[
        "bool",
        "bytes",
        "complex",
        "dict",
        "float",
        "frozenset",
        "int",
        "list",
        "object",
        "set",
        "str",
        "tuple",
    ],
    constants: &["Ellipsis", "False", "None", "NotImplemented", "True"],
    builtins: &[
        "__import__",
        "abs",
        "all",
        "any",
        "ascii",
        "bin",
        "breakpoint",
        "bytearray",
        "callable",
        "chr",
        "classmethod",
        "compile",
        "delattr",
        "dir",
        "divmod",
        "enumerate",
        "eval",
        "filter",
        "format",
        "getattr",
        "globals",
        "hasattr",
        "hash",
        "help",
        "hex",
        "id",
        "input",
        "isinstance",
        "issubclass",
        "iter",
        "len",
        "locals",
        "map",
        "max",
        "memoryview",
        "min",
        "next",
        "oct",
        "open",
        "ord",
        "pow",
        "property",
        "range",
        "repr",
        "reversed",
        "round",
        "self",
        "setattr",
        "slice",
        "sorted",
        "staticmethod",
        "sum",
        "super",
        "vars",
        "zip",
    ],
};

static PROFILE_JSTS: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: false,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "as",
        "async",
        "await",
        "break",
        "case",
        "catch",
        "class",
        "continue",
        "debugger",
        "default",
        "delete",
        "do",
        "else",
        "export",
        "extends",
        "finally",
        "for",
        "from",
        "if",
        "implements",
        "import",
        "in",
        "instanceof",
        "new",
        "of",
        "package",
        "private",
        "protected",
        "public",
        "readonly",
        "return",
        "satisfies",
        "static",
        "super",
        "switch",
        "throw",
        "try",
        "typeof",
        "void",
        "while",
        "with",
        "yield",
    ],
    declarations: &[
        "abstract",
        "const",
        "declare",
        "enum",
        "function",
        "interface",
        "let",
        "module",
        "namespace",
        "type",
        "var",
    ],
    types: &[
        "any", "bigint", "boolean", "never", "number", "object", "string", "symbol", "unknown",
    ],
    constants: &[
        "Infinity",
        "NaN",
        "false",
        "globalThis",
        "null",
        "this",
        "true",
        "undefined",
    ],
    builtins: &[
        "Array",
        "Boolean",
        "Date",
        "Error",
        "Function",
        "JSON",
        "Map",
        "Math",
        "Number",
        "Object",
        "Promise",
        "Proxy",
        "RegExp",
        "Set",
        "String",
        "Symbol",
        "WeakMap",
        "WeakSet",
        "console",
        "document",
        "fetch",
        "parseFloat",
        "parseInt",
        "process",
        "require",
        "setInterval",
        "setTimeout",
        "window",
    ],
};

static PROFILE_RUST: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: true,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: false,
    backtick_strings: false,
    case_insensitive_keywords: false,
    keywords: &[
        "as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum",
        "extern", "fn", "for", "if", "impl", "in", "loop", "match", "mod", "move", "pub", "ref",
        "return", "struct", "super", "trait", "type", "union", "unsafe", "use", "where", "while",
        "yield",
    ],
    declarations: &["let", "mut", "static"],
    types: &[
        "Box", "Cow", "Option", "Result", "Self", "String", "Vec", "bool", "char", "f32", "f64",
        "i128", "i16", "i32", "i64", "i8", "isize", "str", "u128", "u16", "u32", "u64", "u8",
        "usize",
    ],
    constants: &["Err", "None", "Ok", "Some", "false", "true"],
    builtins: &["drop", "self"],
};

static PROFILE_GO: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: true,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "break",
        "case",
        "chan",
        "continue",
        "default",
        "defer",
        "else",
        "fallthrough",
        "for",
        "func",
        "go",
        "goto",
        "if",
        "import",
        "interface",
        "map",
        "package",
        "range",
        "return",
        "select",
        "struct",
        "switch",
        "type",
    ],
    declarations: &["const", "var"],
    types: &[
        "any",
        "bool",
        "byte",
        "comparable",
        "complex128",
        "complex64",
        "error",
        "float32",
        "float64",
        "int",
        "int16",
        "int32",
        "int64",
        "int8",
        "rune",
        "string",
        "uint",
        "uint16",
        "uint32",
        "uint64",
        "uint8",
        "uintptr",
    ],
    constants: &["false", "iota", "nil", "null", "true"],
    builtins: &[
        "append", "cap", "clear", "close", "complex", "copy", "delete", "imag", "len", "make",
        "max", "min", "new", "panic", "print", "println", "real", "recover",
    ],
};

static PROFILE_CFAMILY: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: false,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: true,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: false,
    backtick_strings: false,
    case_insensitive_keywords: false,
    keywords: &[
        "alignas",
        "alignof",
        "asm",
        "break",
        "case",
        "catch",
        "class",
        "co_await",
        "co_return",
        "co_yield",
        "concept",
        "const_cast",
        "continue",
        "decltype",
        "default",
        "delete",
        "do",
        "dynamic_cast",
        "else",
        "enum",
        "explicit",
        "export",
        "for",
        "friend",
        "goto",
        "if",
        "inline",
        "namespace",
        "new",
        "noexcept",
        "operator",
        "private",
        "protected",
        "public",
        "reinterpret_cast",
        "requires",
        "return",
        "sizeof",
        "static_assert",
        "static_cast",
        "struct",
        "switch",
        "template",
        "throw",
        "try",
        "typedef",
        "typeid",
        "typename",
        "union",
        "using",
        "virtual",
        "while",
    ],
    declarations: &[
        "auto",
        "const",
        "constexpr",
        "constinit",
        "extern",
        "mutable",
        "register",
        "static",
        "thread_local",
        "volatile",
    ],
    types: &[
        "FILE",
        "bool",
        "char",
        "char16_t",
        "char32_t",
        "char8_t",
        "double",
        "float",
        "int",
        "int16_t",
        "int32_t",
        "int64_t",
        "int8_t",
        "long",
        "ptrdiff_t",
        "short",
        "signed",
        "size_t",
        "ssize_t",
        "uint16_t",
        "uint32_t",
        "uint64_t",
        "uint8_t",
        "uintptr_t",
        "unsigned",
        "void",
        "wchar_t",
    ],
    constants: &[
        "EOF", "FALSE", "NULL", "TRUE", "false", "nullptr", "this", "true",
    ],
    builtins: &[
        "calloc", "free", "malloc", "memcpy", "memset", "printf", "puts", "realloc", "snprintf",
        "strlen",
    ],
};

static PROFILE_CSHARP_JAVA: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: false,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: true,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: true,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "abstract",
        "as",
        "assert",
        "async",
        "await",
        "base",
        "break",
        "case",
        "catch",
        "checked",
        "class",
        "continue",
        "default",
        "delegate",
        "do",
        "else",
        "enum",
        "event",
        "explicit",
        "extends",
        "extern",
        "finally",
        "fixed",
        "for",
        "foreach",
        "fun",
        "goto",
        "if",
        "implements",
        "implicit",
        "import",
        "in",
        "instanceof",
        "interface",
        "internal",
        "is",
        "lock",
        "match",
        "namespace",
        "native",
        "new",
        "null",
        "object",
        "operator",
        "out",
        "override",
        "package",
        "params",
        "private",
        "protected",
        "public",
        "readonly",
        "record",
        "ref",
        "return",
        "sealed",
        "sizeof",
        "stackalloc",
        "static",
        "strictfp",
        "struct",
        "super",
        "switch",
        "synchronized",
        "this",
        "throw",
        "throws",
        "trait",
        "transient",
        "try",
        "typeof",
        "unchecked",
        "unsafe",
        "using",
        "virtual",
        "volatile",
        "when",
        "where",
        "while",
        "yield",
    ],
    declarations: &[
        "const", "def", "final", "lateinit", "lazy", "type", "val", "var",
    ],
    types: &[
        "Boolean",
        "Byte",
        "Character",
        "Double",
        "Float",
        "Int",
        "Integer",
        "List",
        "Long",
        "Map",
        "Object",
        "Set",
        "Short",
        "String",
        "Unit",
        "Void",
        "bool",
        "boolean",
        "byte",
        "char",
        "decimal",
        "double",
        "dynamic",
        "float",
        "int",
        "long",
        "sbyte",
        "short",
        "string",
        "uint",
        "ulong",
        "ushort",
        "void",
    ],
    constants: &["false", "null", "true"],
    builtins: &["println", "typeof"],
};

static PROFILE_SWIFT: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: false,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: true,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: true,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "actor",
        "as",
        "async",
        "await",
        "break",
        "case",
        "catch",
        "class",
        "continue",
        "default",
        "defer",
        "deinit",
        "do",
        "else",
        "enum",
        "extension",
        "fallthrough",
        "fileprivate",
        "for",
        "func",
        "guard",
        "if",
        "import",
        "in",
        "init",
        "inout",
        "internal",
        "is",
        "open",
        "operator",
        "private",
        "protocol",
        "public",
        "repeat",
        "rethrows",
        "return",
        "some",
        "static",
        "struct",
        "subscript",
        "super",
        "switch",
        "throw",
        "throws",
        "try",
        "typealias",
        "where",
        "while",
    ],
    declarations: &[
        "associatedtype",
        "convenience",
        "final",
        "lazy",
        "let",
        "mutating",
        "nonmutating",
        "optional",
        "override",
        "required",
        "unowned",
        "var",
        "weak",
    ],
    types: &[
        "Any",
        "AnyObject",
        "Array",
        "Bool",
        "Character",
        "Dictionary",
        "Double",
        "Float",
        "Int",
        "Optional",
        "Result",
        "Self",
        "Set",
        "String",
        "Void",
    ],
    constants: &["false", "nil", "self", "true"],
    builtins: &[
        "debugPrint",
        "fatalError",
        "max",
        "min",
        "precondition",
        "print",
        "stride",
        "zip",
    ],
};

static PROFILE_PHP: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: true,
    keywords: &[
        "abstract",
        "as",
        "break",
        "callable",
        "case",
        "catch",
        "class",
        "clone",
        "continue",
        "declare",
        "default",
        "do",
        "echo",
        "else",
        "elseif",
        "enddeclare",
        "endfor",
        "endforeach",
        "endif",
        "endswitch",
        "endwhile",
        "enum",
        "extends",
        "final",
        "finally",
        "fn",
        "for",
        "foreach",
        "function",
        "global",
        "goto",
        "if",
        "implements",
        "include",
        "include_once",
        "instanceof",
        "insteadof",
        "interface",
        "match",
        "namespace",
        "new",
        "print",
        "private",
        "protected",
        "public",
        "readonly",
        "require",
        "require_once",
        "return",
        "static",
        "switch",
        "throw",
        "trait",
        "try",
        "use",
        "while",
        "yield",
    ],
    declarations: &["const", "var"],
    types: &[
        "array", "bool", "float", "int", "iterable", "mixed", "never", "object", "self", "string",
        "void",
    ],
    constants: &["false", "null", "parent", "true"],
    builtins: &[
        "array_map",
        "count",
        "die",
        "empty",
        "exit",
        "implode",
        "isset",
        "json_decode",
        "json_encode",
        "strlen",
        "unset",
        "var_dump",
    ],
};

static PROFILE_ELIXIR: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: true,
    dash_comments: false,
    percent_comments: true,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: true,
    dollar_vars: false,
    triple_quotes: true,
    backtick_strings: false,
    case_insensitive_keywords: false,
    keywords: &[
        "after",
        "alias",
        "case",
        "catch",
        "cond",
        "def",
        "defdelegate",
        "defexception",
        "defguard",
        "defimpl",
        "defmacro",
        "defmacrop",
        "defmodule",
        "defoverridable",
        "defp",
        "defprotocol",
        "defstruct",
        "do",
        "else",
        "end",
        "fn",
        "for",
        "if",
        "import",
        "in",
        "quote",
        "raise",
        "receive",
        "require",
        "reraise",
        "rescue",
        "super",
        "throw",
        "try",
        "unless",
        "unquote",
        "use",
        "when",
        "with",
    ],
    declarations: &[],
    types: &[],
    constants: &["false", "nil", "true"],
    builtins: &[
        "elem",
        "hd",
        "inspect",
        "is_atom",
        "is_binary",
        "is_boolean",
        "is_float",
        "is_function",
        "is_integer",
        "is_list",
        "is_map",
        "is_nil",
        "is_number",
        "is_pid",
        "is_tuple",
        "length",
        "map_size",
        "put_elem",
        "self",
        "spawn",
        "tl",
        "tuple_size",
    ],
};

static PROFILE_ML_HASKELL: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: false,
    dash_comments: true,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "as",
        "begin",
        "case",
        "class",
        "data",
        "default",
        "deriving",
        "do",
        "else",
        "end",
        "exception",
        "external",
        "forall",
        "fun",
        "function",
        "functor",
        "hiding",
        "if",
        "import",
        "in",
        "include",
        "infix",
        "infixl",
        "infixr",
        "inherit",
        "initializer",
        "instance",
        "let",
        "match",
        "method",
        "module",
        "mutable",
        "newtype",
        "nonrec",
        "object",
        "of",
        "open",
        "private",
        "qualified",
        "rec",
        "sig",
        "struct",
        "then",
        "to",
        "try",
        "type",
        "val",
        "virtual",
        "when",
        "where",
        "while",
        "with",
    ],
    declarations: &[],
    types: &[
        "Bool", "Char", "Double", "Either", "Float", "IO", "Int", "Integer", "Maybe", "Ordering",
        "String", "bool", "char", "float", "int", "list", "option", "ref", "string", "unit",
    ],
    constants: &[
        "False", "Just", "Left", "None", "Nothing", "Right", "Some", "True", "false", "true",
    ],
    builtins: &[
        "error", "fst", "head", "id", "map", "print", "putStr", "putStrLn", "return", "show",
        "snd", "tail",
    ],
};

static PROFILE_LUA: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: true,
    dash_comments: true,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: false,
    backtick_strings: false,
    case_insensitive_keywords: false,
    keywords: &[
        "and", "break", "do", "else", "elseif", "end", "for", "function", "goto", "if", "in",
        "local", "not", "or", "repeat", "return", "then", "until", "while",
    ],
    declarations: &["local"],
    types: &[],
    constants: &["false", "nil", "true"],
    builtins: &[
        "assert",
        "collectgarbage",
        "dofile",
        "error",
        "getmetatable",
        "ipairs",
        "load",
        "next",
        "pairs",
        "pcall",
        "print",
        "rawequal",
        "rawget",
        "rawlen",
        "rawset",
        "require",
        "select",
        "self",
        "setmetatable",
        "tonumber",
        "tostring",
        "type",
        "xpcall",
    ],
};

static PROFILE_PERL: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "continue", "default", "do", "else", "elsif", "for", "foreach", "given", "goto", "if",
        "last", "local", "my", "next", "no", "our", "package", "redo", "require", "return",
        "state", "sub", "unless", "until", "use", "when", "while",
    ],
    declarations: &["local", "my", "our", "state", "sub"],
    types: &[],
    constants: &["__END__", "__FILE__", "__LINE__", "__PACKAGE__", "undef"],
    builtins: &[
        "chomp", "chop", "chr", "close", "die", "eval", "exec", "exit", "grep", "hex", "index",
        "int", "join", "keys", "length", "map", "oct", "open", "ord", "pop", "print", "printf",
        "push", "reverse", "rindex", "say", "scalar", "shift", "sort", "splice", "split",
        "sprintf", "substr", "system", "uncurry", "unshift", "values", "warn",
    ],
};

static PROFILE_SHELL: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "ADD",
        "ARG",
        "CMD",
        "COPY",
        "ENTRYPOINT",
        "ENV",
        "EXPOSE",
        "FROM",
        "HEALTHCHECK",
        "LABEL",
        "MAINTAINER",
        "ONBUILD",
        "RUN",
        "SHELL",
        "STOPSIGNAL",
        "USER",
        "VOLUME",
        "WORKDIR",
        "case",
        "do",
        "done",
        "elif",
        "else",
        "esac",
        "fi",
        "for",
        "function",
        "if",
        "in",
        "select",
        "then",
        "time",
        "until",
        "while",
    ],
    declarations: &["declare", "export", "local", "readonly", "typeset", "unset"],
    types: &[],
    constants: &["false", "true"],
    builtins: &[
        "alias", "bg", "bind", "break", "builtin", "cd", "command", "continue", "dirs", "disown",
        "echo", "enable", "eval", "exec", "exit", "fg", "getopts", "hash", "help", "history",
        "jobs", "kill", "let", "logout", "popd", "printf", "pushd", "pwd", "read", "return", "set",
        "shift", "shopt", "source", "suspend", "test", "times", "trap", "type", "ulimit", "umask",
        "unalias", "wait",
    ],
};

static PROFILE_BATCH: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: false,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: false,
    case_insensitive_keywords: true,
    keywords: &[
        "call", "do", "echo", "else", "endlocal", "equ", "exist", "exit", "for", "geq", "goto",
        "gtr", "if", "in", "leq", "lss", "neq", "not", "pause", "rem", "set", "setlocal", "shift",
    ],
    declarations: &["set"],
    types: &[],
    constants: &["nul"],
    builtins: &[
        "cd", "cls", "copy", "del", "dir", "md", "mkdir", "move", "rd", "ren", "rmdir", "start",
        "type", "xcopy",
    ],
};

static PROFILE_POWERSHELL: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: true,
    keywords: &[
        "begin",
        "break",
        "catch",
        "class",
        "continue",
        "data",
        "default",
        "do",
        "dynamicparam",
        "else",
        "elseif",
        "end",
        "enum",
        "exit",
        "filter",
        "finally",
        "for",
        "foreach",
        "from",
        "function",
        "if",
        "in",
        "inlinescript",
        "parallel",
        "param",
        "process",
        "return",
        "sequence",
        "switch",
        "throw",
        "trap",
        "try",
        "until",
        "using",
        "var",
        "while",
        "workflow",
    ],
    declarations: &["function", "param", "var"],
    types: &[
        "array",
        "bool",
        "byte",
        "char",
        "datetime",
        "decimal",
        "double",
        "guid",
        "hashtable",
        "int",
        "long",
        "pscustomobject",
        "psobject",
        "regex",
        "single",
        "string",
        "switch",
        "void",
        "xml",
    ],
    constants: &["false", "null", "true"],
    builtins: &[
        "write-error",
        "write-host",
        "write-output",
        "write-verbose",
        "write-warning",
    ],
};

static PROFILE_SQL: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: true,
    dash_comments: true,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: true,
    case_insensitive_keywords: true,
    keywords: &[
        "add",
        "all",
        "alter",
        "analyze",
        "and",
        "any",
        "as",
        "asc",
        "begin",
        "between",
        "by",
        "cascade",
        "case",
        "check",
        "collate",
        "column",
        "commit",
        "conflict",
        "constraint",
        "create",
        "cross",
        "current",
        "cursor",
        "database",
        "declare",
        "default",
        "delete",
        "desc",
        "distinct",
        "do",
        "drop",
        "else",
        "end",
        "except",
        "exists",
        "explain",
        "fetch",
        "filter",
        "first",
        "following",
        "for",
        "foreign",
        "from",
        "full",
        "function",
        "grant",
        "group",
        "having",
        "if",
        "ilike",
        "in",
        "index",
        "inner",
        "insert",
        "intersect",
        "into",
        "is",
        "join",
        "key",
        "last",
        "lateral",
        "left",
        "like",
        "limit",
        "local",
        "lock",
        "match",
        "materialized",
        "natural",
        "not",
        "nothing",
        "nulls",
        "offset",
        "on",
        "only",
        "or",
        "order",
        "outer",
        "over",
        "partition",
        "preceding",
        "primary",
        "procedure",
        "references",
        "reindex",
        "replace",
        "restrict",
        "return",
        "returning",
        "returns",
        "revoke",
        "right",
        "rollback",
        "row",
        "rows",
        "schema",
        "select",
        "set",
        "table",
        "temp",
        "temporary",
        "then",
        "to",
        "transaction",
        "trigger",
        "truncate",
        "unbounded",
        "union",
        "unique",
        "update",
        "using",
        "vacuum",
        "values",
        "view",
        "when",
        "where",
        "window",
        "with",
    ],
    declarations: &[],
    types: &[
        "array",
        "bigint",
        "bigserial",
        "bit",
        "blob",
        "bool",
        "boolean",
        "bytea",
        "char",
        "character",
        "cidr",
        "citext",
        "date",
        "datetime",
        "decimal",
        "double",
        "float",
        "float4",
        "float8",
        "inet",
        "int",
        "int2",
        "int4",
        "int8",
        "integer",
        "interval",
        "json",
        "jsonb",
        "macaddr",
        "money",
        "numeric",
        "precision",
        "real",
        "serial",
        "smallint",
        "smallserial",
        "text",
        "time",
        "timestamp",
        "timestamptz",
        "tsquery",
        "tsvector",
        "uuid",
        "varbit",
        "varchar",
        "varying",
        "vector",
        "xml",
    ],
    constants: &[
        "current_date",
        "current_time",
        "current_timestamp",
        "false",
        "null",
        "true",
    ],
    builtins: &[
        "abs",
        "array_agg",
        "avg",
        "cast",
        "coalesce",
        "concat",
        "count",
        "date_trunc",
        "dense_rank",
        "extract",
        "first_value",
        "json_agg",
        "jsonb_agg",
        "jsonb_build_object",
        "lag",
        "last_value",
        "lead",
        "length",
        "lower",
        "max",
        "min",
        "now",
        "nullif",
        "rank",
        "replace",
        "round",
        "row_number",
        "string_agg",
        "substring",
        "sum",
        "trim",
        "unnest",
        "upper",
    ],
};

static PROFILE_SCIENTIFIC: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: true,
    dash_comments: false,
    percent_comments: true,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: true,
    dollar_vars: true,
    triple_quotes: true,
    backtick_strings: true,
    case_insensitive_keywords: false,
    keywords: &[
        "abstract",
        "baremodule",
        "begin",
        "break",
        "catch",
        "classdef",
        "const",
        "continue",
        "do",
        "else",
        "elseif",
        "end",
        "export",
        "finally",
        "for",
        "function",
        "global",
        "if",
        "import",
        "in",
        "let",
        "local",
        "macro",
        "module",
        "mutable",
        "otherwise",
        "parfor",
        "persistent",
        "primitive",
        "quote",
        "repeat",
        "return",
        "spmd",
        "struct",
        "switch",
        "try",
        "type",
        "using",
        "where",
        "while",
    ],
    declarations: &["const", "global", "local"],
    types: &[
        "Any", "Array", "Bool", "Char", "Complex", "Dict", "Float16", "Float32", "Float64",
        "Function", "Int", "Int16", "Int32", "Int64", "Int8", "Matrix", "Missing", "Nothing",
        "Number", "Real", "Set", "String", "Symbol", "Tuple", "UInt", "UInt16", "UInt32", "UInt64",
        "UInt8", "Union", "Vector",
    ],
    constants: &[
        "FALSE", "Inf", "NA", "NULL", "NaN", "TRUE", "false", "inf", "missing", "nan", "nothing",
        "pi", "true",
    ],
    builtins: &[
        "c",
        "cat",
        "cbind",
        "data.frame",
        "disp",
        "error",
        "fprintf",
        "lapply",
        "length",
        "library",
        "list",
        "mean",
        "names",
        "paste",
        "plot",
        "print",
        "println",
        "rbind",
        "rep",
        "require",
        "sapply",
        "seq",
        "sprintf",
        "str",
        "subset",
        "sum",
        "summary",
        "table",
        "typeof",
        "zeros",
    ],
};

static PROFILE_PASCAL_ADA: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: true,
    dash_comments: true,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: false,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: true,
    backtick_strings: false,
    case_insensitive_keywords: true,
    keywords: &[
        "abort",
        "abs",
        "abstract",
        "accept",
        "access",
        "aliased",
        "all",
        "and",
        "array",
        "at",
        "begin",
        "body",
        "case",
        "class",
        "constant",
        "declare",
        "delay",
        "delta",
        "digits",
        "div",
        "do",
        "downto",
        "else",
        "elsif",
        "end",
        "entry",
        "exception",
        "exit",
        "exports",
        "for",
        "function",
        "generic",
        "goto",
        "if",
        "implementation",
        "in",
        "inherited",
        "initialization",
        "interface",
        "is",
        "label",
        "limited",
        "loop",
        "mod",
        "new",
        "not",
        "null",
        "of",
        "or",
        "others",
        "out",
        "overriding",
        "package",
        "pragma",
        "private",
        "procedure",
        "program",
        "protected",
        "raise",
        "range",
        "record",
        "rem",
        "renames",
        "requeue",
        "return",
        "reverse",
        "select",
        "separate",
        "set",
        "shl",
        "shr",
        "some",
        "subtype",
        "synchronized",
        "tagged",
        "task",
        "terminate",
        "then",
        "to",
        "try",
        "type",
        "unit",
        "until",
        "use",
        "uses",
        "var",
        "when",
        "while",
        "with",
        "xor",
    ],
    declarations: &["const", "function", "procedure", "type", "var"],
    types: &[
        "boolean",
        "byte",
        "char",
        "character",
        "double",
        "float",
        "integer",
        "longint",
        "natural",
        "positive",
        "real",
        "shortint",
        "single",
        "string",
        "word",
    ],
    constants: &["false", "nil", "null", "true"],
    builtins: &["echo", "read", "readln", "write", "writeln"],
};

static PROFILE_BASIC: CodeProfile = CodeProfile {
    slash_comments: false,
    hash_comments: false,
    dash_comments: false,
    percent_comments: false,
    semi_comments: false,
    apostrophe_comments: true,
    c_preprocessor: false,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: false,
    triple_quotes: false,
    backtick_strings: false,
    case_insensitive_keywords: true,
    keywords: &[
        "and",
        "as",
        "byref",
        "byval",
        "call",
        "case",
        "catch",
        "class",
        "const",
        "continue",
        "declare",
        "default",
        "delegate",
        "dim",
        "do",
        "each",
        "else",
        "elseif",
        "end",
        "endif",
        "enum",
        "erase",
        "error",
        "event",
        "exit",
        "finally",
        "for",
        "friend",
        "function",
        "get",
        "global",
        "gosub",
        "goto",
        "handles",
        "if",
        "implements",
        "imports",
        "in",
        "inherits",
        "interface",
        "is",
        "let",
        "lib",
        "loop",
        "me",
        "mod",
        "module",
        "mustinherit",
        "mustoverride",
        "mybase",
        "myclass",
        "namespace",
        "new",
        "next",
        "not",
        "nothing",
        "notinheritable",
        "notoverridable",
        "of",
        "on",
        "operator",
        "option",
        "optional",
        "or",
        "orelse",
        "overloads",
        "overridable",
        "overrides",
        "paramarray",
        "partial",
        "private",
        "property",
        "protected",
        "public",
        "raiseevent",
        "readonly",
        "redim",
        "rem",
        "resume",
        "return",
        "select",
        "set",
        "shadows",
        "shared",
        "static",
        "step",
        "stop",
        "structure",
        "sub",
        "synclock",
        "then",
        "throw",
        "to",
        "try",
        "typeof",
        "until",
        "wend",
        "when",
        "while",
        "widening",
        "with",
        "withevents",
        "writeonly",
        "xor",
    ],
    declarations: &["const", "dim", "function", "let", "property", "sub"],
    types: &[
        "boolean", "byte", "char", "date", "decimal", "double", "integer", "long", "object",
        "sbyte", "short", "single", "string", "uinteger", "ulong", "ushort", "variant",
    ],
    constants: &["false", "nothing", "null", "true"],
    builtins: &[
        "cbool", "cbyte", "cchar", "cdate", "cdbl", "cdec", "cint", "clng", "cobj", "csbyte",
        "cshort", "csng", "cstr", "ctype", "cuint", "culng", "cushort", "len", "mid", "msgbox",
        "print", "trim", "ubound",
    ],
};

static PROFILE_ASSEMBLY: CodeProfile = CodeProfile {
    slash_comments: true,
    hash_comments: true,
    dash_comments: false,
    percent_comments: false,
    semi_comments: true,
    apostrophe_comments: false,
    c_preprocessor: true,
    rust_lifetimes_and_macros: false,
    ruby_symbols_and_ivars: false,
    dollar_vars: true,
    triple_quotes: false,
    backtick_strings: false,
    case_insensitive_keywords: true,
    keywords: &[
        "add", "and", "b", "beq", "bl", "bne", "br", "call", "cmp", "dec", "define", "div",
        "entry", "extern", "global", "icmp", "inc", "je", "jg", "jge", "jl", "jle", "jmp", "jne",
        "jnz", "jz", "ldr", "lea", "load", "mov", "mul", "neg", "nop", "not", "or", "pop", "push",
        "ret", "section", "shl", "shr", "store", "str", "sub", "svc", "syscall", "test", "xor",
    ],
    declarations: &[
        "db", "dd", "dq", "dw", "equ", "resb", "resd", "resq", "resw",
    ],
    types: &[
        "byte", "dword", "i1", "i16", "i32", "i64", "i8", "ptr", "qword", "void", "word",
    ],
    constants: &["false", "null", "true", "zeroinitializer"],
    builtins: &[
        "eax", "ebp", "ebx", "ecx", "edi", "edx", "eip", "esi", "esp", "r10", "r11", "r12", "r13",
        "r14", "r15", "r8", "r9", "rax", "rbp", "rbx", "rcx", "rdi", "rdx", "rip", "rsi", "rsp",
        "sp",
    ],
};

// ============================================================================
// Unit Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn registry_and_tags_are_sorted_and_complete() {
        assert_eq!(supported_language_tags().len(), 228);
        assert!(supported_language_tags().windows(2).all(|w| w[0] < w[1]));
        assert!(REGISTRY_ENTRIES
            .windows(2)
            .all(|w| w[0].0.as_bytes() < w[1].0.as_bytes()));

        for &tag in supported_language_tags() {
            assert_eq!(find_lexer_tag(tag), Some(tag));
            assert_eq!(normalize_language_tag(tag), tag);
        }
        assert_eq!(find_lexer_tag("js"), Some("javascript"));
        assert_eq!(find_lexer_tag("ts"), Some("typescript"));
        assert_eq!(find_lexer_tag("rb"), Some("ruby"));
        assert_eq!(find_lexer_tag("py"), Some("python"));
        assert_eq!(find_lexer_tag("rs"), Some("rust"));
        assert_eq!(find_lexer_tag("c++"), Some("cpp"));
        assert_eq!(find_lexer_tag("c#"), Some("csharp"));
        assert_eq!(find_lexer_tag("Dockerfile"), Some("docker"));
        assert_eq!(find_lexer_tag("R"), Some("r"));
        assert_eq!(find_lexer_tag("LaTeX"), Some("tex"));
        assert_eq!(find_lexer_tag("unknown_lang"), None);
        assert_eq!(normalize_language_tag("  JS \n"), "javascript");
        assert_eq!(normalize_language_tag("totally-made-up"), "plaintext");
    }

    #[test]
    fn find_fancy_and_path_resolution_handle_all_edge_cases() {
        assert_eq!(find_fancy_tag(Some(""), Some("puts 1"), true), None);
        assert_eq!(
            find_fancy_tag(Some("ruby?start_inline=1"), Some("puts 1"), true),
            Some("ruby")
        );
        assert_eq!(
            find_fancy_tag(Some("?mimetype=text/x-ruby"), Some("puts 1"), true),
            None
        );
        assert_eq!(
            find_fancy_tag(Some("guess?mimetype=application/json"), Some("{}"), true),
            Some("json")
        );
        assert_eq!(
            find_fancy_tag(Some("guess"), Some("#!/usr/bin/env ruby\nputs 1"), true),
            Some("ruby")
        );
        assert_eq!(
            find_fancy_tag(Some("guess"), Some("#!/bin/bash\necho hi"), true),
            Some("shell")
        );
        assert_eq!(
            find_fancy_tag(Some("guess"), Some("<!DOCTYPE html><html></html>"), true),
            Some("html")
        );

        assert_eq!(language_from_path("app/models/user.rb"), Some("ruby"));
        assert_eq!(
            language_from_path("  src/index.ts  extra"),
            Some("typescript")
        );
        assert_eq!(language_from_path("README.md"), Some("markdown"));
        assert_eq!(language_from_path("a/b.rb///"), Some("ruby"));
        assert_eq!(language_from_path("dir/..rb"), None);
        assert_eq!(language_from_path("dir/...rb"), None);
        assert_eq!(language_from_path("a\0b.rb"), None);
        assert_eq!(language_from_path(".gitignore"), None);
        assert_eq!(language_from_path("no_extension"), None);
        assert_eq!(language_from_path(""), None);
    }

    #[test]
    fn highlights_every_supported_language_and_escapes_html_entities() {
        let sample = "日本語 🚀 /* comment */ // line\n# hash\ndef foo(x = 42, s = \"<script>&</script>\"):\n  return true\nend\n";
        for &tag in supported_language_tags() {
            let html = highlight_html(sample, Some(tag));
            assert!(
                !html.contains("<script>"),
                "unescaped <script> for tag={tag}"
            );
            assert!(
                html.contains("&lt;script&gt;")
                    && html.contains("&amp;")
                    && html.contains("&lt;/script&gt;"),
                "missing escaped text for tag={tag}: {html}"
            );

            let block = highlight_code_block(sample, Some(tag));
            assert!(block.starts_with(&format!(
                "<div class=\"highlight\"><pre class=\"highlight {tag}\"><code>"
            )));
            assert!(block.ends_with("</code></pre></div>"));
        }
    }

    #[test]
    fn ember_gjs_gts_highlights_import_and_template_tags() {
        let code = "import UiList from 'my-app/components/ui/list';\n\n<template>\n  <UiList @items={{@items}} />\n</template>\n";
        for hint in ["gjs", "gts"] {
            let block = highlight_code_block(code, Some(hint));
            assert!(block.contains(&format!("highlight {hint}")));
            assert!(block.contains("<span class=\"k\">import</span>"));
            assert!(block.contains("<span class=\"k\">template</span>"));
        }
    }

    #[test]
    fn makefile_converts_leading_four_spaces_to_tabs() {
        let block = highlight_code_block("all:\n    echo hi\n", Some("make"));
        assert!(block.contains("highlight make"));
        assert!(block.contains("\t<span class=\"nb\">echo</span>"));
    }

    #[test]
    fn raw_liquid_markers_are_isolated_for_unescaping() {
        let code = "{----% raw %----}some text{----% endraw %----}";
        for lang in ["js", "ruby", "html", "liquid", "plaintext"] {
            let html = highlight_code_block(code, Some(lang));
            let unescaped = crate::html::unescape_raw_tag_in_codeblocks(&html).unwrap();
            assert!(
                !unescaped.contains("----"),
                "failed for lang={lang}: {unescaped}"
            );
            assert!(unescaped.contains("raw"));
            assert!(unescaped.contains("endraw"));
        }
    }

    #[test]
    fn profiles_have_strictly_sorted_word_lists() {
        for profile in [
            &PROFILE_RUBY,
            &PROFILE_PYTHON,
            &PROFILE_JSTS,
            &PROFILE_RUST,
            &PROFILE_GO,
            &PROFILE_CFAMILY,
            &PROFILE_CSHARP_JAVA,
            &PROFILE_SWIFT,
            &PROFILE_PHP,
            &PROFILE_ELIXIR,
            &PROFILE_ML_HASKELL,
            &PROFILE_LUA,
            &PROFILE_PERL,
            &PROFILE_SHELL,
            &PROFILE_BATCH,
            &PROFILE_POWERSHELL,
            &PROFILE_SQL,
            &PROFILE_SCIENTIFIC,
            &PROFILE_PASCAL_ADA,
            &PROFILE_BASIC,
            &PROFILE_ASSEMBLY,
        ] {
            for list in [
                profile.keywords,
                profile.declarations,
                profile.types,
                profile.constants,
                profile.builtins,
            ] {
                for w in list.windows(2) {
                    assert!(
                        w[0] < w[1],
                        "Unsorted word list entry: {:?} >= {:?}",
                        w[0],
                        w[1]
                    );
                }
            }
        }
    }
}
