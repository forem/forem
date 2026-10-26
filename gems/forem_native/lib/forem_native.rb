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
