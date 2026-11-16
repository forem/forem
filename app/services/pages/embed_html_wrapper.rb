module Pages
  class EmbedHtmlWrapper
    SANDBOX_DIRECTIVE = "allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox".freeze
    MAX_TREE_DEPTH = 256
    MAX_DOM_NODES = 15_000
    GUARD_SCRIPT_PATH = Rails.root.join("app/javascript/utilities/embedInnerGuard.js")

    DANGEROUS_ELEMENTS = %w[base iframe frame frameset portal object embed applet].freeze
    DANGEROUS_META_HTTP_EQUIV = %w[
      refresh
      set-cookie
      content-security-policy
      x-frame-options
      location
      window-target
    ].freeze
    DISALLOWED_META_NAMES = %w[referrer viewport].freeze
    DISALLOWED_FORM_TARGETS = %w[_top _parent].freeze
    DISALLOWED_LINK_RELS = %w[dns-prefetch preconnect prefetch prerender].freeze
    UNSAFE_URI_SCHEME_REGEXP = /\A[\x00-\x20]*(?:javascript|vbscript|data|file):/i
    ALLOWED_LINK_SCHEMES = %w[http https mailto].freeze

    BASE_WRAPPER_CSS = <<~CSS.strip.freeze
      :where(html) {
        box-sizing: border-box;
        background: #fff;
        color: #171717;
      }
      :where(*, *::before, *::after) {
        box-sizing: inherit;
      }
      :where(body) {
        margin: 0;
        font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        line-height: 1.5;
      }
      html[data-forem-paused="true"] *,
      html[data-forem-paused="true"] *::before,
      html[data-forem-paused="true"] *::after {
        animation-play-state: paused !important;
        transition: none !important;
      }
    CSS

    def self.call(raw_html, blocked_hosts: default_blocked_hosts, local_http: Rails.env.local?)
      new(raw_html, blocked_hosts: blocked_hosts, local_http: local_http).call
    end

    def self.preview_result(raw_html, max_bytes: Page::MAX_EMBED_HTML_BYTES)
      html = raw_html.to_s
      if html.bytesize > max_bytes
        return {
          status: :unprocessable_entity,
          json: { error: I18n.t("models.page.embed_html_too_large", max_kb: max_bytes / 1.kilobyte) }
        }
      end

      { status: :ok, json: { wrapped_html: call(html) } }
    end

    def self.parse_html5(cleaned)
      Nokogiri::HTML5.parse(cleaned, max_tree_depth: MAX_TREE_DEPTH, max_errors: -1)
    rescue ArgumentError
      nil
    end

    def self.validate_complexity(raw_html)
      doc = parse_html5(clean_raw_string(raw_html))
      return :too_deep if doc.nil?
      return :too_many_nodes if doc.xpath("count(//*)").to_i > MAX_DOM_NODES

      :ok
    end

    def self.meta_csp_directives(local_http: Rails.env.local?)
      local_http_sources = local_http ? " http://localhost:* http://127.0.0.1:*" : ""
      local_ws_sources = local_http ? " ws://localhost:* ws://127.0.0.1:*" : ""
      directives = [
        "default-src 'none'",
        "script-src 'unsafe-inline' https:#{local_http_sources}",
        "style-src 'unsafe-inline' https: data: blob:#{local_http_sources}",
        "img-src https: data: blob:#{local_http_sources}",
        "font-src https: data:#{local_http_sources}",
        "media-src https: data: blob:#{local_http_sources}",
        "connect-src https: wss:#{local_http_sources}#{local_ws_sources}",
        "base-uri 'none'",
        "object-src 'none'",
        "frame-src 'none'",
        "child-src 'none'",
        "worker-src 'none'",
        "form-action 'none'",
        "manifest-src 'none'",
      ]
      directives << "upgrade-insecure-requests" unless local_http
      directives
    end

    def self.meta_csp_content(local_http: Rails.env.local?)
      # `upgrade-insecure-requests` is valid in HTTP CSP headers; omit from <meta>
      # so browsers don't warn about directives ignored inside <meta> CSP tags.
      meta_csp_directives(local_http: local_http)
        .reject { |directive| directive == "upgrade-insecure-requests" }
        .join("; ")
    end

    def self.http_csp_header(frame_ancestors:, local_http: Rails.env.local?)
      (
        [
          "sandbox #{SANDBOX_DIRECTIVE}",
          "frame-ancestors #{frame_ancestors}",
        ] + meta_csp_directives(local_http: local_http)
      ).join("; ")
    end

    def self.default_blocked_hosts
      domains = []
      domains.concat(Subforem.cached_all_domains) if defined?(Subforem)
      domains << Settings::General.app_domain if defined?(Settings::General)
      domains
        .compact_blank
        .map { |host| host.to_s.downcase.strip.sub(/:\d+\z/, "") }
        .uniq
    rescue StandardError
      []
    end

    def self.clean_raw_string(raw_html)
      raw_html.to_s.delete("\x00").delete_prefix("\uFEFF")
    end

    def self.inner_guard_source
      if Rails.env.development?
        load_inner_guard_source
      else
        @inner_guard_source ||= load_inner_guard_source
      end
    end

    def self.wrapper_digest
      if Rails.env.development?
        Digest::SHA256.hexdigest("#{BASE_WRAPPER_CSS}\n#{inner_guard_source}").first(12)
      else
        @wrapper_digest ||= Digest::SHA256.hexdigest("#{BASE_WRAPPER_CSS}\n#{inner_guard_source}").first(12)
      end
    end

    def self.load_inner_guard_source
      GUARD_SCRIPT_PATH.read.sub(/^export\s+/, "").gsub("</script", '<\\/script')
    end
    private_class_method :load_inner_guard_source

    def initialize(raw_html, blocked_hosts:, local_http:)
      @raw_html = self.class.clean_raw_string(raw_html)
      @blocked_hosts = Array(blocked_hosts).compact_blank.map(&:downcase).uniq
      @local_http = local_http
    end

    def call
      source_doc = self.class.parse_html5(@raw_html)
      return fallback_complexity_document if source_doc.nil?
      return fallback_complexity_document if source_doc.xpath("count(//*)").to_i > MAX_DOM_NODES

      sanitize_tree!(source_doc)
      assemble_document(source_doc)
    end

    private

    def sanitize_tree!(doc)
      strip_dangerous_elements!(doc)
      strip_dangerous_meta_tags!(doc)
      sanitize_link_elements!(doc)
      sanitize_attributes!(doc)
    end

    def strip_dangerous_elements!(doc)
      doc.css(DANGEROUS_ELEMENTS.join(", ")).each(&:remove)
    end

    def strip_dangerous_meta_tags!(doc)
      doc.css("meta").each do |meta|
        next unless dangerous_meta?(meta)

        meta.remove
      end
    end

    def dangerous_meta?(meta)
      equiv = meta["http-equiv"].to_s.strip.downcase
      name = meta["name"].to_s.strip.downcase
      DANGEROUS_META_HTTP_EQUIV.include?(equiv) ||
        DISALLOWED_META_NAMES.include?(name) ||
        meta.key?("charset")
    end

    def sanitize_link_elements!(doc)
      doc.css("link").each do |link|
        rel_tokens = link["rel"].to_s.downcase.split(/\s+/)
        if (rel_tokens & DISALLOWED_LINK_RELS).any?
          link.remove
          next
        end

        href = link["href"].to_s
        if href.match?(UNSAFE_URI_SCHEME_REGEXP)
          link.remove
        end
      end
    end

    def sanitize_attributes!(doc)
      doc.css("[autofocus]").each { |node| node.remove_attribute("autofocus") }
      doc.css("a[ping], area[ping]").each { |node| node.remove_attribute("ping") }
      doc.css("button[formaction], input[formaction]").each { |node| node.remove_attribute("formaction") }

      doc.css("form").each do |form|
        action = form["action"].to_s
        form.remove_attribute("action") if action.match?(UNSAFE_URI_SCHEME_REGEXP)
        target = form["target"].to_s.strip.downcase
        form.remove_attribute("target") if DISALLOWED_FORM_TARGETS.include?(target)
      end

      doc.css("a[href], area[href]").each do |link|
        sanitize_link_node!(link)
      end

      doc.css("img").each do |img|
        img["loading"] = "lazy" if img["loading"].blank?
        img["decoding"] = "async" if img["decoding"].blank?
      end

      doc.css("audio[autoplay], video[autoplay]").each do |media|
        media.remove_attribute("autoplay")
      end
    end

    def sanitize_link_node!(link)
      href = link["href"].to_s.strip
      return if href.blank? || href.start_with?("#")

      normalized = href.gsub(/[\x00-\x20]+/, "").downcase
      if normalized.match?(UNSAFE_URI_SCHEME_REGEXP) || unsafe_explicit_scheme?(normalized)
        link.remove_attribute("href")
        return
      end

      link["target"] = "_blank"
      existing_rel = link["rel"].to_s.split(/\s+/).compact_blank
      link["rel"] = (existing_rel | %w[noopener noreferrer]).join(" ")
    end

    def unsafe_explicit_scheme?(normalized_href)
      match = /\A([a-z][a-z0-9+.\-]*):/.match(normalized_href)
      return false unless match

      ALLOWED_LINK_SCHEMES.exclude?(match[1])
    end

    def assemble_document(source_doc)
      out_doc = Nokogiri::HTML5::Document.new
      html_node = out_doc.create_element("html")
      copy_safe_element_attributes(source_doc.at_css("html"), html_node)
      html_node["data-forem-embed"] = "1"
      html_node["data-forem-theme"] = "light"
      out_doc.add_child(html_node)

      head_node = out_doc.create_element("head")
      html_node.add_child(head_node)
      prepend_wrapper_head_nodes!(out_doc, head_node)

      source_head = source_doc.at_css("head")
      source_head&.children&.each do |child|
        head_node.add_child(child.dup)
      end

      body_node = out_doc.create_element("body")
      source_body = source_doc.at_css("body")
      copy_safe_element_attributes(source_body, body_node)
      source_body&.children&.each do |child|
        body_node.add_child(child.dup)
      end
      html_node.add_child(body_node)

      html_output = out_doc.to_html
      html_output.start_with?("<!DOCTYPE html>") ? html_output : "<!DOCTYPE html>#{html_output}"
    end

    def copy_safe_element_attributes(source_node, target_node)
      return unless source_node

      source_node.attribute_nodes.each do |attr|
        name = attr.name.downcase
        next if name.start_with?("data-forem-") || name == "autofocus"

        target_node[attr.name] = attr.value
      end
    end

    def prepend_wrapper_head_nodes!(doc, head_node)
      charset = doc.create_element("meta", charset: "utf-8")
      viewport = doc.create_element("meta", name: "viewport", content: "width=device-width, initial-scale=1")
      referrer = doc.create_element(
        "meta",
        "name" => "referrer",
        "content" => "no-referrer",
        "data-forem-wrapper-meta" => "1",
      )
      csp_meta = doc.create_element(
        "meta",
        "http-equiv" => "Content-Security-Policy",
        "content" => self.class.meta_csp_content(local_http: @local_http),
        "data-forem-wrapper-meta" => "1",
      )

      style = doc.create_element("style", "data-forem-wrapper-style" => "1")
      style.content = BASE_WRAPPER_CSS

      script = doc.create_element("script", "data-forem-wrapper-script" => "1")
      script.content = build_guard_bootstrap_js

      [charset, viewport, referrer, csp_meta, style, script].each do |node|
        head_node.add_child(node)
      end
    end

    def build_guard_bootstrap_js
      config_json = JSON.generate(
        blockedHosts: @blocked_hosts,
        allowLocalHttp: @local_http,
      ).gsub("</", '<\/')

      "(() => { #{self.class.inner_guard_source}\ninitEmbedInnerGuard(#{config_json}, window, document); })();"
    end

    def fallback_complexity_document
      notice = CGI.escapeHTML(I18n.t("services.pages.embed_html_wrapper.complexity_fallback"))
      locale = CGI.escapeHTML(I18n.locale.to_s)
      <<~HTML
        <!DOCTYPE html>
        <html lang="#{locale}" data-forem-embed="1" data-forem-theme="light">
          <head>
            <meta charset="utf-8">
            <meta name="referrer" content="no-referrer" data-forem-wrapper-meta="1">
            <meta http-equiv="Content-Security-Policy" content="#{CGI.escapeHTML(self.class.meta_csp_content(local_http: @local_http))}" data-forem-wrapper-meta="1">
            <style data-forem-wrapper-style="1">#{BASE_WRAPPER_CSS}</style>
          </head>
          <body>
            <p role="status">#{notice}</p>
          </body>
        </html>
      HTML
    end
  end
end
