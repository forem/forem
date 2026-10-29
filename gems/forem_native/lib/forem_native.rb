require_relative "forem_native/version"
require_relative "forem_native/builder"

# `ForemNative` provides in-process Rust acceleration (via `magnus` + `rb-sys`)
# for CPU-bound and allocation-heavy operations in Forem.
#
# In production, CI, and local development, it loads either the platform-compiled
# shared library (`forem_native/forem_native.{so,bundle}` from `Containerfile` /
# `rake forem_native:compile`) or the committed precompiled platform binary
# (`forem_native/{arm64-darwin,x86_64-darwin,x86_64-linux}/forem_native.{so,bundle}`),
# and automatically compiles via `cargo` on first load if neither is staged yet.
module ForemNative
  @native_loaded = false

  class << self
    def load_native!
      return true if @native_loaded && defined?(Native)

      # 1. If a local `cargo build --release` has already produced an artifact in `target/release`
      #    (and no precompiled or staged binary is present yet), stage it into `lib/forem_native/`.
      if !Builder.precompiled_binary_exists? && File.exist?(Builder.cargo_artifact_path)
        Builder.install_built_artifact!
      end

      # 2. Try loading an already-staged local/Containerfile build or precompiled platform binary.
      if require_candidate_binary
        @native_loaded = true
        return true
      end

      # 3. If no binary is present on disk yet (e.g. an exotic platform),
      #    compile the Rust workspace automatically via `cargo` and load it.
      if Builder.compile! && require_candidate_binary
        @native_loaded = true
        return true
      end

      raise LoadError,
            "Failed to load ForemNative Rust extension for #{RUBY_PLATFORM}. " \
            "Run `bundle exec rake forem_native:compile` or ensure `cargo` is installed."
    end

    # Returns true when the compiled Rust `magnus` extension is loaded and active.
    def available?
      @native_loaded && defined?(Native) ? true : false
    end
    alias native_available? available?
    alias native_loaded? available?

    # Counts word tokens matching `content.to_s.split(/\W+/).count`.
    def split_word_count(content)
      Native.split_word_count(content.to_s)
    end

    # Calculates article reading time in minutes matching
    # `(content.to_s.split(/\W+/).count / 275.0).ceil`.
    def calculate_reading_time(content)
      Native.calculate_reading_time(content.to_s)
    end

    # Scales a strict `#rrggbb` hex color, matching `Color::CompareHex#brightness`.
    # Returns nil for anything outside that domain (malformed hexes, negative or
    # non-finite channels) so `Color::CompareHex#brightness` can handle those
    # edge cases via its private `legacy_brightness` method.
    def color_brightness(hex, amount = 1, only_values: false)
      return unless hex.is_a?(String) && hex.encoding.ascii_compatible?

      native_amount = native_float(amount)
      return unless native_amount

      Native.color_brightness(hex, native_amount, only_values ? true : false)
    end

    # Finds the first seven-character brightness variant for `Color::CompareHex#accent`.
    # Returns nil outside the strict hex and finite numeric domain so the helper can use
    # its private `legacy_accent` implementation for Ruby's edge-case semantics.
    def color_accent(hex, amount = 1)
      return unless hex.is_a?(String) && hex.encoding.ascii_compatible?

      native_amount = native_float(amount)
      return unless native_amount

      Native.color_accent(hex, native_amount)
    end

    # Formats a strict `#rrggbb` hex color as `rgba(r, g, b, a)`, matching
    # `Color::CompareHex#opacity`. Returns nil for malformed hexes and for alphas
    # that would need `%.2f` rounding (anything beyond two decimals, non-finite,
    # Rational, ...) so `Color::CompareHex#opacity` can use its private `legacy_opacity`.
    def color_opacity(hex, alpha = 0.0)
      return unless hex.is_a?(String) && hex.encoding.ascii_compatible?

      native_alpha = native_float(alpha)
      return unless native_alpha

      Native.color_opacity(hex, native_alpha)
    end

    # Rewrites `[text](url)` links as `<a>` tags on 16+ space / 4+ tab indented list lines,
    # matching `MarkdownProcessor::Parser#convert_deeply_nested_links_to_html`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so the
    # parser's private `legacy_convert_deeply_nested_links_to_html` keeps Ruby's semantics.
    def convert_deeply_nested_links_to_html(content)
      return unless content.instance_of?(String) && content.encoding == Encoding::UTF_8

      Native.convert_deeply_nested_links_to_html(content)
    end

    # Wraps fenced code blocks and inline code spans in `{% raw %}` tags (neutralizing any
    # raw tags inside them), matching `MarkdownProcessor::Parser#escape_liquid_tags_in_codeblock`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so the
    # parser's private `legacy_escape_liquid_tags_in_codeblock` keeps Ruby's semantics.
    def escape_liquid_tags_in_codeblock(content)
      return unless content.instance_of?(String) && content.encoding == Encoding::UTF_8

      Native.escape_liquid_tags_in_codeblock(content)
    end

    # Replaces `\|` with `&#124;` outside fenced code blocks and inline code spans, matching
    # `MarkdownProcessor::Parser#convert_escaped_pipes_outside_codeblocks`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so the
    # parser's private `legacy_convert_escaped_pipes_outside_codeblocks` keeps Ruby's semantics.
    def convert_escaped_pipes_outside_codeblocks(content)
      return unless content.instance_of?(String) && content.encoding == Encoding::UTF_8

      Native.convert_escaped_pipes_outside_codeblocks(content)
    end

    # Turns bare `<code>` / `</code>` lines into triple backticks unless the content also has a
    # `<pre>` tag, matching `MarkdownProcessor::Parser#convert_code_tags_to_triple_backticks`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so the
    # parser's private `legacy_convert_code_tags_to_triple_backticks` keeps Ruby's semantics.
    def convert_code_tags_to_triple_backticks(content)
      return unless content.instance_of?(String) && content.encoding == Encoding::UTF_8

      Native.convert_code_tags_to_triple_backticks(content)
    end

    # Whether the markdown has a `src="data` / `src="&` or `data:text/html,` XSS attempt outside
    # code blocks, matching the check in `MarkdownProcessor::Parser#catch_xss_attempts`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so the
    # parser's private `legacy_xss_attempt?` keeps Ruby's semantics.
    def markdown_xss_attempt(markdown)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.markdown_xss_attempt(markdown)
    end

    # Replaces the editor's default `![Image Description]` alt text with `![ ]`, matching the
    # cleanup in `MarkdownProcessor::Parser#initialize`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so the
    # parser's private `legacy_strip_default_image_alt_text` keeps Ruby's semantics.
    def strip_default_image_alt_text(content)
      return unless content.instance_of?(String) && content.encoding == Encoding::UTF_8

      Native.strip_default_image_alt_text(content)
    end

    # Wraps unquoted `<section>: value` front matter lines in double quotes (escaping inner
    # quotes), matching `MarkdownProcessor::Fixer::Base.add_quotes_to_section`.
    # Returns nil for anything but plain UTF-8 Strings (and for invalid UTF-8 or a section
    # that is not a plain word) so `Fixer::Base` can use its private `legacy_add_quotes_to_section`.
    def fixer_add_quotes_to_section(markdown, section)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8
      return unless section.instance_of?(String)

      Native.fixer_add_quotes_to_section(markdown, section)
    end

    # Normalizes CRLF line endings to LF, matching `MarkdownProcessor::Fixer::Base.convert_new_lines`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so Fixer can
    # preserve Ruby's encoding and String-subclass behavior.
    def fixer_convert_new_lines(markdown)
      return unless Native.respond_to?(:fixer_convert_new_lines)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.fixer_convert_new_lines(markdown)
    end

    # Joins `#tag` lists on `tags:` lines into comma-separated values, matching
    # `MarkdownProcessor::Fixer::Base.split_tags`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so
    # `Fixer::Base` can use its private `legacy_split_tags`.
    def fixer_split_tags(markdown)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.fixer_split_tags(markdown)
    end

    # Lowercases `published:` keys at line starts inside front matter blocks, matching
    # `MarkdownProcessor::Fixer::Base.lowercase_published`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so
    # `Fixer::Base` can use its private `legacy_lowercase_published`.
    def fixer_lowercase_published(markdown)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.fixer_lowercase_published(markdown)
    end

    # Escapes `@_username_` underscores outside fenced code blocks, matching
    # `MarkdownProcessor::Fixer::Base.underscores_in_usernames`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so
    # `Fixer::Base` can use its private `legacy_underscores_in_usernames`.
    def fixer_underscores_in_usernames(markdown)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.fixer_underscores_in_usernames(markdown)
    end

    # Runs the complete 6-step `MarkdownProcessor::Fixer::FixAll` pipeline in a single Rust pass.
    def fixer_fix_all(markdown)
      return unless Native.respond_to?(:fixer_fix_all)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.fixer_fix_all(markdown)
    end

    # Runs the 3-step `MarkdownProcessor::Fixer::FixForPreview` pipeline in a single Rust pass.
    def fixer_fix_for_preview(markdown)
      return unless Native.respond_to?(:fixer_fix_for_preview)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.fixer_fix_for_preview(markdown)
    end

    # Runs the `MarkdownProcessor::Fixer::FixForComment` pipeline in a single Rust pass.
    def fixer_fix_for_comment(markdown)
      return unless Native.respond_to?(:fixer_fix_for_comment)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.fixer_fix_for_comment(markdown)
    end

    # Fuses the five pre-Redcarpet steps in `MarkdownProcessor::Parser#finalize` into a single call.
    # Returns `:xss_attempt`, the preprocessed String, or nil for out-of-domain inputs.
    def preprocess_markdown_for_finalize(content)
      return unless Native.respond_to?(:preprocess_markdown_for_finalize)
      return unless content.instance_of?(String) && content.encoding == Encoding::UTF_8

      Native.preprocess_markdown_for_finalize(content)
    end

    # Checks whether `markdown` contains any unlabeled fenced code blocks.
    def contains_unlabeled_code_blocks(markdown)
      return false if markdown.nil?
      return unless Native.respond_to?(:contains_unlabeled_code_blocks)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.contains_unlabeled_code_blocks(markdown)
    end

    # Extracts the inner code strings of all unlabeled fenced code blocks in `markdown`.
    def extract_unlabeled_code_blocks(markdown)
      return unless Native.respond_to?(:extract_unlabeled_code_blocks)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8

      Native.extract_unlabeled_code_blocks(markdown)
    end

    # Applies `languages` in order to each unlabeled fenced code block in `markdown`.
    def apply_code_block_languages(markdown, languages)
      return unless Native.respond_to?(:apply_code_block_languages)
      return unless markdown.instance_of?(String) && markdown.encoding == Encoding::UTF_8
      return unless languages.is_a?(Array)

      Native.apply_code_block_languages(markdown, languages)
    end

    # Builds the `https://{domain}/{directory}/image/{options*}/{src}` Cloudflare Images URL,
    # matching the `Addressable::Template` expansion in `Images::Optimizer.cloudflare`.
    # Returns nil for values other than nil, Integers, and valid UTF-8 Strings (and for text
    # at or above U+0300, which Addressable NFC-normalizes) so `Images::Optimizer` can use its
    # private `legacy_cloudflare`.
    def cloudflare_image_url(domain, directory, width, height, fit, img_src, src)
      Native.cloudflare_image_url(domain, directory, width, height, fit, img_src, src)
    end

    # Normalizes `http`/`https` URLs and `/`-rooted paths, matching
    # `Addressable::URI.parse(url).normalize.to_s`.
    # Returns nil for anything but a plain UTF-8 (or US-ASCII) String, and for URLs whose
    # normalization needs Addressable (other schemes, non-ASCII text, userinfo, dot segments,
    # whitespace, ...) so callers can fall back to Addressable.
    def normalize_url(url)
      return unless url.instance_of?(String)

      Native.normalize_url(url)
    end

    # Resolves `reference` against a bare `http(s)://host[:port]` base and normalizes it,
    # matching `Addressable::URI.parse(base).join(reference).normalize.to_s`.
    # Returns nil for non-String (or String subclass) arguments, bases with a path, references
    # with a scheme, an authority, or dot segments, and everything `normalize_url` declines,
    # so `URL.url` can fall back to Addressable.
    def join_url(base, reference)
      return unless base.instance_of?(String) && reference.instance_of?(String)

      Native.join_url(base, reference)
    end

    # Renders a status post title as HTML (paragraphs, `<br>`s, and shortened underlined URLs),
    # matching `Article#title_finalized`, or `Article#truncate_title_for_feed` (first six lines
    # plus a "read more" marker) when `truncate_for_feed` is true.
    # Returns nil for anything but a plain String (and for invalid UTF-8) so `Article` can use
    # its private `legacy_title_finalized` / `legacy_truncate_title_for_feed`.
    def quickie_title_html(title, truncate_for_feed: false)
      return unless title.instance_of?(String)

      Native.quickie_title_html(title, truncate_for_feed ? true : false)
    end

    # Collapses runs of ASCII whitespace (`\s+`, including newlines) to single spaces and strips
    # leading/trailing ASCII whitespace/NULs, matching `Article#title_for_metadata`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so `Article` can
    # fall back to `legacy_title_for_metadata`.
    def title_for_metadata(title)
      return unless Native.respond_to?(:title_for_metadata)
      return unless title.instance_of?(String) && title.encoding == Encoding::UTF_8

      Native.title_for_metadata(title)
    end

    # Returns the lowercased host of a (possibly scheme-less) URL without a leading `www.`,
    # matching `Addressable::URI.parse(url).host.downcase.delete_prefix("www.")` after
    # `ArticlesHelper#get_host_without_www` strips the URL and adds a missing `http://`.
    # Returns nil for non-Strings, non-ASCII URLs, userinfo, IP literals, non-digit ports, and
    # URLs without a host so the helper can fall back to Addressable.
    def host_without_www(url)
      return unless url.instance_of?(String)

      Native.host_without_www(url)
    end

    # Whether `content` with every `[[:space:]]` character replaced by a space includes `title`
    # without its `…` characters, matching the check in
    # `Feeds::CheckItemMediumReply#content_is_not_the_title?`.
    # Returns nil for anything but plain UTF-8 Strings (and for invalid UTF-8) so the service
    # can use its private `legacy_content_is_not_the_title?`.
    def content_includes_title(content, title)
      return unless content.instance_of?(String) && content.encoding == Encoding::UTF_8
      return unless title.instance_of?(String) && title.encoding == Encoding::UTF_8

      Native.content_includes_title(content, title)
    end

    # Returns the domain `Middlewares::SetSubforem` looks up for a request host (or its
    # `passed_domain` param): the host itself, without an all-digit `:port`.
    # Returns nil for non-Strings and anything but a bare `[A-Za-z0-9.-]` hostname (full URLs,
    # paths, userinfo, non-ASCII) so the middleware can fall back to `URI.parse`.
    def subforem_request_domain(raw)
      return unless raw.instance_of?(String)

      Native.subforem_request_domain(raw)
    end

    # Whether `host` matches `/^([^.]+)\.#{sld}\.#{tld}$/`, the subdomain check
    # `Middlewares::SetSubforem` builds from `PublicSuffix.parse(host)` on every request.
    # Returns nil for non-Strings and for hosts or labels outside `[A-Za-z0-9.-]` so the
    # middleware can build the `Regexp`.
    def subforem_subdomain_host(host, sld, tld)
      return unless host.instance_of?(String) && sld.instance_of?(String) && tld.instance_of?(String)

      Native.subforem_subdomain_host(host, sld, tld)
    end

    # Returns the registrable root domain (`PublicSuffix.parse(host, default_rule: nil).domain`),
    # `false` when `PublicSuffix.parse(host, default_rule: nil)` raises `PublicSuffix::DomainInvalid`
    # (including `nil`), or `nil` for non-Strings, non-ASCII hosts, NUL bytes, embedded newlines,
    # and consecutive dots (`..`) so the caller can fall back to `PublicSuffix.parse`.
    def public_suffix_domain(host)
      return false if host.nil?
      return unless host.instance_of?(String)

      Native.public_suffix_domain(host)
    end

    # Checks whether `host` is a single-label subdomain of its Public Suffix List registrable
    # domain (`PublicSuffix.parse(host, default_rule: nil)` + `/^([^.]+)\.#{sld}\.#{tld}$/`) in
    # `Middlewares::SetSubforem`: returns `true` or `false` for valid domains, `:invalid` when
    # `PublicSuffix.parse(host, default_rule: nil)` raises `PublicSuffix::DomainInvalid`
    # (including `nil`), or `nil` for non-Strings and hosts outside `[A-Za-z0-9.-]` so the
    # middleware can fall back to `PublicSuffix.parse`.
    def public_suffix_subdomain_host(host)
      return :invalid if host.nil?
      return unless host.instance_of?(String)

      Native.public_suffix_subdomain_host(host)
    end

    # Whether the original host `Middlewares::RestoreOriginalHost` reads from the Fastly or
    # X-Forwarded headers on every request is a valid hostname (or `localhost`), ignoring any
    # `:port`. Returns nil for non-Strings, non-ASCII hosts, and hosts starting with `:` so the
    # middleware can use its private `legacy_valid_host?`.
    def original_host_valid(host)
      return unless host.instance_of?(String)

      Native.original_host_valid(host)
    end

    # Renders an icon's HTML-serialized SVG (`svg`) with the `aria: true`, `class:`, `width:`,
    # `height:`, and optional `aria_hidden:` and `title:` transformations of `inline_svg_tag`,
    # matching its Nokogiri pipeline. `title_id` is the `InlineSvg::IdGenerator` id for the title.
    # Returns nil for non-String values, icons that already have a `<title>` or `<desc>`, and
    # values holding `"` or control characters so `CrayonsHelper` can use `inline_svg_tag`.
    def inline_svg_icon(svg, class_name, width, height, aria_hidden: nil, title: nil, title_id: nil)
      strings = [svg, class_name, width, height]
      strings.push(aria_hidden) unless aria_hidden.nil?
      strings.push(title, title_id) unless title.nil? && title_id.nil?
      return unless strings.all?(String)

      Native.inline_svg_icon(svg, class_name, width, height, aria_hidden, title, title_id)
    end

    # Strips HTML tags, comments, and doctypes while decoding character references and re-escaping
    # `&`, `<`, `>`, and U+00A0 (`&nbsp;`), matching `ActionView::Base.full_sanitizer.sanitize`.
    # Returns nil for non-Strings (including nil), invalid or non-UTF-8 strings, and HTML5 parser
    # edge cases (foster-parented table text, uncommon named entities, ...) so callers can fall
    # back to `ActionView::Base.full_sanitizer.sanitize`.
    def full_sanitize(html)
      return unless html.instance_of?(String)

      Native.full_sanitize(html)
    end

    # Strips `<[^>]*>` tags, unescapes basic and numeric HTML entities, strips ASCII whitespace,
    # lowercases, removes `HeadingAnchors::SLUG_DISALLOWED` characters, and turns spaces into
    # hyphens, matching `AgentSessionRenderers::HeadingAnchors.slugify`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8, surrogate numeric
    # entities, or code points outside the verified Unicode domain) so `HeadingAnchors.slugify`
    # can fall back to its private `legacy_slugify`.
    def slugify_heading_anchor(heading_html)
      return unless Native.respond_to?(:slugify_heading_anchor)
      return unless heading_html.instance_of?(String) && heading_html.encoding == Encoding::UTF_8

      Native.slugify_heading_anchor(heading_html)
    end

    # Strips a leading `http://`, `https://`, `ftp://`, or `/` prefix, removes `?` query strings
    # up to the end of the line, and chomps a trailing `/`, matching
    # `ApplicationHelper#beautified_url`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so
    # `ApplicationHelper#beautified_url` can fall back to `legacy_beautified_url`.
    def beautified_url(url)
      return unless Native.respond_to?(:beautified_url)
      return unless url.instance_of?(String) && url.encoding == Encoding::UTF_8

      Native.beautified_url(url)
    end

    # Replaces `:([\w+-]+):` shortcodes with their `Emoji.find_by_alias($1)&.raw` Unicode sequences,
    # matching `Html::Parser#parse_emojis`.
    # Returns nil for anything but a plain UTF-8 String (and for invalid UTF-8) so `Html::Parser`
    # can fall back to `legacy_parse_emojis`.
    def parse_emojis(html)
      return unless Native.respond_to?(:parse_emojis)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.parse_emojis(html)
    end

    # Replaces `:([\w+-]+):` shortcodes outside `<code>...</code>` elements on canonical
    # `Nokogiri::HTML.fragment(html).to_html` fragments, matching
    # `Html::Parser#escape_colon_emojis_in_codeblock`.
    # Returns nil for anything but a plain UTF-8 String, invalid UTF-8, or HTML fragments that
    # need Nokogiri's HTML4 tree builder or serializer normalization so `Html::Parser` can fall
    # back to `legacy_escape_colon_emojis_in_codeblock`.
    def escape_colon_emojis_in_codeblock(html)
      return unless Native.respond_to?(:escape_colon_emojis_in_codeblock)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.escape_colon_emojis_in_codeblock(html)
    end

    # Looks up a single `:alias:` shortcode name (without surrounding colons) in the embedded
    # `gemoji` table, returning the raw UTF-8 emoji string or nil if unknown.
    def emoji_by_alias(alias_name)
      return unless Native.respond_to?(:emoji_by_alias)
      return unless alias_name.is_a?(String) && alias_name.encoding.ascii_compatible?

      str = alias_name.instance_of?(String) ? alias_name : alias_name.to_s
      str = str.encode(Encoding::UTF_8) if str.encoding == Encoding::US_ASCII
      return unless str.encoding == Encoding::UTF_8

      Native.emoji_by_alias(str)
    end

    # Strips all Unicode `RGI_Emoji` sequences from `text`, replacing `text.gsub(EmojiRegex::RGIEmoji, "")`
    # from the removed `emoji_regex` gem.
    def strip_rgi_emoji(text)
      return unless Native.respond_to?(:strip_rgi_emoji)
      return unless text.is_a?(String)

      str = text.instance_of?(String) ? text : text.to_s
      str = str.encode(Encoding::UTF_8) if str.encoding == Encoding::US_ASCII
      return unless str.encoding == Encoding::UTF_8

      Native.strip_rgi_emoji(str)
    end

    # Computes the W3C WCAG 2.0 contrast ratio between two 3- or 6-digit hex color strings
    # (without `#`), replacing `WCAGColorContrast.ratio(rgb1, rgb2)` from the removed
    # `wcag_color_contrast` gem. Returns nil if either color is not a valid 3- or 6-digit hex string.
    def wcag_contrast_ratio(rgb1, rgb2)
      return unless Native.respond_to?(:wcag_contrast_ratio)
      return unless rgb1.is_a?(String) && rgb1.encoding.ascii_compatible?
      return unless rgb2.is_a?(String) && rgb2.encoding.ascii_compatible?

      Native.wcag_contrast_ratio(rgb1.to_s, rgb2.to_s)
    end

    # Counts distinct calendar days among `entries` (`[[article_id, timestamp, ...], ...]`)
    # whose timestamp is `>= cutoff_time`, matching `FeedConfig.active_user?`.
    # `cutoff_time` may be a `Time`/`TimeWithZone` or integer `cutoff_sec` (with `cutoff_nanos`).
    # Returns nil for non-Array inputs or unrecognized timestamp formats so callers can
    # fall back to `legacy_active_user_days`.
    def activity_distinct_days_since(entries, cutoff_time, cutoff_nanos = 0)
      return unless Native.respond_to?(:activity_distinct_days_since)
      return unless entries.is_a?(Array)

      if cutoff_time.is_a?(Integer)
        Native.activity_distinct_days_since(entries, cutoff_time, cutoff_nanos.to_i)
      elsif cutoff_time.respond_to?(:tv_sec)
        nanos = cutoff_time.respond_to?(:tv_nsec) ? cutoff_time.tv_nsec : 0
        Native.activity_distinct_days_since(entries, cutoff_time.tv_sec, nanos)
      end
    end

    # Counts how many `[article_id, timestamp, ...]` entries in `entries` occurred strictly
    # after `cutoff_time` (`> cutoff_time`).
    def activity_pageviews_since(entries, cutoff_time, cutoff_nanos = 0)
      return unless Native.respond_to?(:activity_pageviews_since)
      return unless entries.is_a?(Array)

      if cutoff_time.is_a?(Integer)
        Native.activity_pageviews_since(entries, cutoff_time, cutoff_nanos.to_i)
      elsif cutoff_time.respond_to?(:tv_sec)
        nanos = cutoff_time.respond_to?(:tv_nsec) ? cutoff_time.tv_nsec : 0
        Native.activity_pageviews_since(entries, cutoff_time.tv_sec, nanos)
      end
    end

    # Computes the recency-weighted top-article shuffle count in `[5..20]` from the most
    # recent pageview timestamp, `now_time`, and `shuffle_weight`, matching
    # `Articles::Feeds::Custom#calculate_dynamic_shuffle_count`.
    def dynamic_shuffle_count(most_recent_timestamp, now_time, shuffle_weight)
      return unless Native.respond_to?(:dynamic_shuffle_count)
      return unless now_time.respond_to?(:tv_sec)

      weight = native_float(shuffle_weight)
      return unless weight

      now_nanos = now_time.respond_to?(:tv_nsec) ? now_time.tv_nsec : 0
      Native.dynamic_shuffle_count(most_recent_timestamp, now_time.tv_sec, now_nanos, weight)
    end

    # Reorders `items` using the index-offset weighted shuffle algorithm in
    # `Articles::Feeds::Custom#weighted_shuffle`. Accepts an optional `randoms:` array
    # of floats in `[0.0, 1.0)` for deterministic testing.
    def weighted_shuffle(items, shuffle_weight, randoms: nil)
      return unless Native.respond_to?(:weighted_shuffle)
      return unless items.is_a?(Array)
      return unless randoms.nil? || randoms.is_a?(Array)

      weight = native_float(shuffle_weight)
      return unless weight

      Native.weighted_shuffle(items, weight, randoms)
    end

    # Formats a non-negative duration in seconds as `"MM:SS"` or `"H:MM:SS"`, matching
    # `Article#video_duration_in_minutes`. Returns nil for negative values.
    def format_video_duration(seconds)
      return unless Native.respond_to?(:format_video_duration)

      secs = seconds.to_i
      return if secs.negative? || secs >= 2**62

      Native.format_video_duration(secs)
    end

    # Formats an Array of IDs (filtering out `blank?` entries) as a comma-separated SQL integer
    # list string, or `empty_fallback` (default `"-1"`) when empty.
    def sql_int_list(ids, empty_fallback = "-1")
      return unless Native.respond_to?(:sql_int_list)
      return unless ids.is_a?(Array) && empty_fallback.is_a?(String)

      Native.sql_int_list(ids, empty_fallback)
    end

    # Formats an Array of Strings as a quoted Postgres array literal (`ARRAY['a','b']::text[]`).
    def sql_string_array_literal(items, pg_type = "text")
      return unless Native.respond_to?(:sql_string_array_literal)
      return unless items.is_a?(Array) && pg_type.is_a?(String)

      Native.sql_string_array_literal(items, pg_type)
    end

    # Formats an Array of numeric values as a bracketed `pgvector` literal (`"[0.1,0.2,...]"`).
    def sql_vector_literal(values)
      return unless Native.respond_to?(:sql_vector_literal)
      return unless values.is_a?(Array)

      Native.sql_vector_literal(values)
    end

    # Collapses consecutive whitespace runs into a single space and strips leading/trailing
    # whitespace in a single pass, matching Rails `String#squish`.
    def sql_squish(sql)
      return unless Native.respond_to?(:sql_squish)
      return unless sql.instance_of?(String) && sql.encoding.ascii_compatible?

      Native.sql_squish(sql)
    end

    # Compiles the complete `FeedConfig#score_sql` expression in a single pass from the
    # 28 weight floats and 24-element context array. Returns nil if any input is outside
    # the fast-path domain so `FeedConfig#score_sql` can fall back to `legacy_score_sql`.
    def feed_config_score_sql(weights, context)
      return unless Native.respond_to?(:feed_config_score_sql)
      return unless weights.is_a?(Array) && context.is_a?(Array)

      Native.feed_config_score_sql(weights, context)
    end

    # Scores an article's `cached_tag_list` against followed tag names and point values.
    def score_followed_tags(cached_tag_list, followed_tag_names, followed_tag_points,
                            followed_tag_weight = 1.0, not_followed_tag_score = 0.0)
      return unless Native.respond_to?(:score_followed_tags)
      return unless (cached_tag_list.nil? || cached_tag_list.instance_of?(String)) &&
        followed_tag_names.is_a?(Array) && followed_tag_points.is_a?(Array)

      weight = native_float(followed_tag_weight)
      miss_score = native_float(not_followed_tag_score)
      return unless weight && miss_score

      Native.score_followed_tags(cached_tag_list || "", followed_tag_names, followed_tag_points, weight, miss_score)
    end

    # Computes the experience-level distance penalty (`-((article_rating - user_rating).abs / 2.0) * weight`).
    def score_experience_level(article_rating, user_rating, xp_level_weight = 1.0)
      return unless Native.respond_to?(:score_experience_level)

      weight = native_float(xp_level_weight)
      return unless (article_rating.is_a?(Integer) || article_rating.is_a?(Float)) &&
        (user_rating.is_a?(Integer) || user_rating.is_a?(Float)) && weight

      Native.score_experience_level(article_rating, user_rating, weight)
    end

    # Scores an article's AI disclosure level against a user's `feed_ai_preference`.
    def score_ai_disclosure(ai_preference, ai_disclosure_level,
                            some_ai_penalty = -10.0, fully_autonomous_penalty = -25.0)
      return unless Native.respond_to?(:score_ai_disclosure)
      return unless (ai_preference.nil? || ai_preference.instance_of?(String)) &&
        (ai_disclosure_level.nil? || ai_disclosure_level.instance_of?(String))

      some_pen = native_float(some_ai_penalty)
      auto_pen = native_float(fully_autonomous_penalty)
      Native.score_ai_disclosure(ai_preference, ai_disclosure_level, some_pen, auto_pen) if some_pen && auto_pen
    end

    # Computes the 6-component composite score for `LargeForemExperimental#score_single_article`.
    def score_article_for_user(user_context, *article_args)
      return unless Native.respond_to?(:score_article_for_user) && user_context.is_a?(Array)

      args = article_args.size == 1 && article_args.first.is_a?(Array) ? article_args.first : article_args
      return unless args.size == 7

      Native.score_article_for_user(user_context, args[0], args[1], args[2], args[3], args[4], args[5], args[6])
    end

    # Ranks and sorts `articles` for `Articles::Feeds::Basic#default_home_feed` in a single pass.
    def rank_articles_for_basic_feed(articles, user_context, article_tuples)
      return unless Native.respond_to?(:rank_articles_for_basic_feed)
      return unless articles.is_a?(Array) && user_context.is_a?(Array) && article_tuples.is_a?(Array)

      Native.rank_articles_for_basic_feed(articles, user_context, article_tuples)
    end

    # Filters `(article_id, time_tracked_in_seconds)` pairs where `seconds > min_seconds_exclusive`.
    def filter_tracked_article_ids(entries, min_seconds_exclusive = 29)
      return unless Native.respond_to?(:filter_tracked_article_ids) && entries.is_a?(Array)

      threshold = native_float(min_seconds_exclusive)
      Native.filter_tracked_article_ids(entries, threshold) if threshold
    end

    # Aggregates `recent_tags`, `recent_labels`, `recent_organizations`, `recent_users`, and `recent_subforems`.
    def aggregate_recent_activity_metadata(tag_lists, label_lists, org_ids, user_ids, subforem_ids, max_labels = 5)
      return unless Native.respond_to?(:aggregate_recent_activity_metadata)
      return unless [tag_lists, label_lists, org_ids, user_ids, subforem_ids].all?(Array) &&
        max_labels.is_a?(Integer) && max_labels >= 0

      Native.aggregate_recent_activity_metadata(tag_lists, label_lists, org_ids, user_ids, subforem_ids, max_labels)
    end

    # Scores and orders subforem IDs for `UserDecorator#ordered_subforems`.
    def order_subforem_ids(recent_ids, followed_ids, discoverable_ids)
      return unless Native.respond_to?(:order_subforem_ids)
      return unless recent_ids.is_a?(Array) && followed_ids.is_a?(Array) && discoverable_ids.is_a?(Array)

      Native.order_subforem_ids(recent_ids, followed_ids, discoverable_ids)
    end

    # Builds the 366-day activity heatmap payload Hash in a single pass for `UserActivityHeatmapService#build_payload`.
    def build_activity_heatmap_payload(start_date_iso, end_date_iso, articles_by_day, comments_by_day, reactions_by_day)
      return unless Native.respond_to?(:build_activity_heatmap_payload)
      return unless start_date_iso.instance_of?(String) && end_date_iso.instance_of?(String) &&
        [articles_by_day, comments_by_day, reactions_by_day].all?(Hash)

      Native.build_activity_heatmap_payload(
        start_date_iso, end_date_iso, articles_by_day, comments_by_day, reactions_by_day
      )
    end

    # Rewrites `href="#slug"` intra-document fragment links in `html` using `ids_by_slug`,
    # matching `AgentSessionRenderers::HeadingAnchors#link_fragments`.
    def link_heading_anchor_fragments(html, ids_by_slug)
      return unless Native.respond_to?(:link_heading_anchor_fragments)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8 && ids_by_slug.is_a?(Hash)

      Native.link_heading_anchor_fragments(html, ids_by_slug)
    end

    # Scrubs `text` across all 51 `AgentSessionParsers::SensitiveDataScrubber::PATTERNS`,
    # returning the scrubbed String (or nil for out-of-domain inputs).
    def scrub_sensitive_text(text, tool_output: false)
      return unless Native.respond_to?(:scrub_sensitive_text)
      return unless text.instance_of?(String) && text.encoding == Encoding::UTF_8

      Native.scrub_sensitive_text(text, tool_output ? true : false)
    end

    # Scrubs `text` across all 51 `AgentSessionParsers::SensitiveDataScrubber::PATTERNS`,
    # returning `[scrubbed_text, [[pattern_name, count], ...]]` (or nil for out-of-domain inputs).
    def scrub_sensitive_text_with_counts(text, tool_output: false)
      return unless Native.respond_to?(:scrub_sensitive_text_with_counts)
      return unless text.instance_of?(String) && text.encoding == Encoding::UTF_8

      Native.scrub_sensitive_text_with_counts(text, tool_output ? true : false)
    end

    # Scrubs all message content blocks in `messages` in a single FFI pass for
    # `AgentSessionParsers::SensitiveDataScrubber#scrub`, returning `[[pattern_name, count], ...]`
    # sorted descending by `count` with Ruby `sort_by` tie-breaking.
    def scrub_agent_session_messages(messages)
      return unless Native.respond_to?(:scrub_agent_session_messages) && messages.is_a?(Array)

      Native.scrub_agent_session_messages(messages)&.sort_by { |_, count| -count }
    end

    # Adds `"js-code-highlight"` to every `div.highlight` element on canonical HTML fragments,
    # matching `Html::Parser#add_control_class_to_codeblock`.
    def add_control_class_to_codeblock(html)
      return unless Native.respond_to?(:add_control_class_to_codeblock)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.add_control_class_to_codeblock(html)
    end

    # Appends `<div class="highlight__panel js-actions-panel"></div>` to every `div.highlight`
    # element on canonical HTML fragments, matching `Html::Parser#add_control_panel_to_codeblock`.
    def add_control_panel_to_codeblock(html)
      return unless Native.respond_to?(:add_control_panel_to_codeblock)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.add_control_panel_to_codeblock(html)
    end

    # Wraps every `<table>` in `<div class="table-wrapper-paragraph">...</div>` on canonical
    # HTML fragments, matching `Html::Parser#wrap_all_tables`.
    def wrap_all_tables(html)
      return unless Native.respond_to?(:wrap_all_tables)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.wrap_all_tables(html)
    end

    # Removes `<p>...</p>` elements whose children are all blank on canonical HTML fragments,
    # matching `Html::Parser#remove_empty_paragraphs`.
    def remove_empty_paragraphs(html)
      return unless Native.respond_to?(:remove_empty_paragraphs)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.remove_empty_paragraphs(html)
    end

    # Wraps `p img` elements in `<a href="..." class="article-body-image-wrapper">...</a>` on
    # canonical HTML fragments, matching `Html::Parser#wrap_all_images_in_links`.
    def wrap_all_images_in_links(html)
      return unless Native.respond_to?(:wrap_all_images_in_links)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.wrap_all_images_in_links(html)
    end

    # Unescapes `{----% raw %----}` and `{----% endraw %----}` markers (including markers split
    # across syntax-highlighted `<span>` elements inside `//body/div/pre/code`), matching
    # `Html::Parser#unescape_raw_tag_in_codeblocks`.
    def unescape_raw_tag_in_codeblocks(html)
      return unless Native.respond_to?(:unescape_raw_tag_in_codeblocks)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.unescape_raw_tag_in_codeblocks(html)
    end

    # Extracts unique lowercased candidate `@username` strings outside `<code>` and `<a>`
    # elements for `Html::Parser#wrap_mentions_with_links`.
    def extract_mention_usernames(html)
      return unless Native.respond_to?(:extract_mention_usernames)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.extract_mention_usernames(html)
    end

    # Replaces `@username` mentions matching `existing_usernames` with `.mentioned-user` links
    # outside `<code>` and `<a>` elements, matching `Html::Parser#wrap_mentions_with_links`.
    def wrap_mentions_with_links(html, existing_usernames, base_url)
      return unless Native.respond_to?(:wrap_mentions_with_links)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8
      return unless existing_usernames.is_a?(Array) && base_url.is_a?(String)

      Native.wrap_mentions_with_links(html, existing_usernames, base_url.to_s)
    end

    # Extracts lowercased `@`-stripped usernames from `.mentioned-user` links outside Liquid tags,
    # matching `Mentions::CreateAll#extract_usernames_from_mentions_in_text`.
    def extract_mentioned_usernames(html)
      return [] if html.nil?
      return unless Native.respond_to?(:extract_mentioned_usernames)
      return unless html.instance_of?(String) && html.encoding == Encoding::UTF_8

      Native.extract_mentioned_usernames(html)
    end

    # Renders the day links of the `calendar/_calendar_widget` month grid in one pass, matching
    # `CalendarHelper#legacy_calendar_grid_days_html`. Days are `Date#jd` Integers. Returns `nil`
    # for grids, paths, or `type_of` values outside the plain-ASCII, 1583-9999 fast path.
    def calendar_grid_days_html(grid_start_jd, grid_end_jd, display_month, event_day_jds, selected,
                                range_start_jd, range_end_jd, today_jd, base_path, type_of)
      return unless Native.respond_to?(:calendar_grid_days_html)
      return unless [grid_start_jd, grid_end_jd, display_month, range_start_jd, range_end_jd, today_jd].all?(Integer)
      return unless event_day_jds.instance_of?(Array) && base_path.instance_of?(String)
      return unless type_of.nil? || type_of.instance_of?(String)

      Native.calendar_grid_days_html(grid_start_jd, grid_end_jd, display_month, event_day_jds, selected ? true : false,
                                     range_start_jd, range_end_jd, today_jd, base_path, type_of)
    end

    # Quotes a String as JSON exactly like ActiveSupport's `string.to_json`, including its
    # HTML-safe escapes. Returns `nil` for String subclasses and non-UTF-8 or invalid strings.
    def json_quote(string, escape_html_entities: true)
      return unless Native.respond_to?(:json_quote)
      return unless string.instance_of?(String)

      Native.json_quote(string, escape_html_entities ? true : false)
    end

    # Encodes plain data in one pass, byte-for-byte equal to `value.to_json` with ActiveSupport's
    # default `JSONGemEncoder`. The fast path covers Hash, Array, String, Symbol, Integer (64-bit),
    # true, false, and nil, with String or Symbol keys. Returns `nil` for anything else (Floats,
    # Times, subclasses such as SafeBuffer, other key types, non-UTF-8 strings, or nesting deeper
    # than 100) so callers can fall back to `value.to_json`.
    def encode_json(value, escape_html_entities: true)
      return unless Native.respond_to?(:encode_json)

      Native.encode_json(value, escape_html_entities ? true : false)
    end

    # Truncates an RSS (`<item>...</item>`) or Atom (`<entry>...</entry>`) XML feed string
    # to at most `max_items` items, preserving all non-item XML structure.
    # Returns the input String itself with zero allocations when the feed already contains
    # `<= max_items` items, or `nil` for non-Strings / invalid UTF-8.
    def truncate_feed_xml_items(xml, max_items)
      return unless Native.respond_to?(:truncate_feed_xml_items)
      return unless xml.instance_of?(String) && max_items.is_a?(Integer) && max_items.positive?

      Native.truncate_feed_xml_items(xml, max_items)
    end

    # Checks whether feed item `content` is predominantly HTML rather than Markdown/plain text,
    # matching `Feeds::AssembleArticleMarkdown#html_content?`.
    def feed_html_content(content)
      return unless Native.respond_to?(:feed_html_content)
      return unless content.instance_of?(String)

      Native.feed_html_content(content)
    end

    # Fuses the post-`ReverseMarkdown` normalizations in `Feeds::AssembleArticleMarkdown`:
    # strips `"```\n\n```"`, replaces `"&nbsp;"` and `"\u00A0"` with `" "`, and unescapes
    # `\_` inside `{% youtube ... %}` Liquid tags.
    def postprocess_feed_markdown(content)
      return unless Native.respond_to?(:postprocess_feed_markdown)
      return unless content.instance_of?(String)

      Native.postprocess_feed_markdown(content)
    end

    # Resolves relative URLs in inline `<img ... src="...">` tags and Markdown `![alt](path)`
    # image syntax in a single pass, matching `Feeds::AssembleArticleMarkdown#resolve_relative_image_urls`.
    def resolve_feed_markdown_images(content, base_url, feed_source_url)
      return unless Native.respond_to?(:resolve_feed_markdown_images)
      return unless content.instance_of?(String) && base_url.instance_of?(String) &&
        feed_source_url.instance_of?(String)

      Native.resolve_feed_markdown_images(content, base_url, feed_source_url)
    end

    # Formats up to 4 RSS/Atom category tags by stripping spaces and non-alphanumeric characters
    # and truncating each to 20 characters, matching `Feeds::AssembleArticleMarkdown#get_tags`.
    def format_feed_tags(categories)
      return unless Native.respond_to?(:format_feed_tags)
      return unless categories.is_a?(Array)

      Native.format_feed_tags(categories)
    end

    # Extracts `[email, name]` from an RSS/Atom author string in a single pass, matching
    # `Feeds::ResolveAuthor`.
    def extract_feed_author(author_string)
      return unless Native.respond_to?(:extract_feed_author)
      return unless author_string.instance_of?(String)

      Native.extract_feed_author(author_string)
    end

    # Scrubs Ruby file/line paths (`/path/to/file.rb:123` -> `"[path]"`) and truncates to 500
    # characters, matching `Feeds::Import#sanitize_error`.
    def sanitize_feed_error(message)
      return unless Native.respond_to?(:sanitize_feed_error)
      return unless message.instance_of?(String)

      Native.sanitize_feed_error(message)
    end

    private

    # Integer * Integer stays exact in Ruby; below 2**31 the f64 product is exact too.
    def native_float(amount)
      case amount
      when Float then amount
      when Integer then amount.to_f if amount.abs < 2**31
      end
    end

    def require_candidate_binary
      candidates = ["forem_native/forem_native"] +
        Builder.platform_candidates.map { |dir| "forem_native/#{dir}/forem_native" }

      candidates.each do |candidate|
        require candidate
        return true if defined?(ForemNative::Native)
      rescue LoadError
        next
      end

      false
    end
  end
end

ForemNative.load_native!
