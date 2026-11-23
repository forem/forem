module Billboards
  # Wraps first-party HTML-first (`render_mode: "raw"`) billboard markup in an
  # open Declarative Shadow DOM host so CSS rules, DOM IDs, and inline scripts
  # stay isolated from the host Forem page and from other billboards, while
  # preserving inherited design tokens (CSS custom properties), common Forem CTA
  # classes, and composed event bubbling for site-wide tracking/navigation.
  class ShadowDomWrapper
    SCRIPT_MIME_TYPE = "application/x-forem-billboard-script".freeze
    EXECUTABLE_SCRIPT_TYPES = %r{
      \A\s*(?:text/javascript|application/javascript|text/ecmascript|application/ecmascript|module)\s*(?:;.*)?\z
    }ix
    BASE_LAYER_NAME = "forem-billboard-base".freeze
    # Base styles injected as the first stylesheet inside the ShadowRoot.
    #
    # The isolation guarantees on :host sit in an anonymous cascade layer with
    # !important. Because it is the first layer declared in the shadow tree,
    # its important declarations beat every author declaration (unlayered,
    # layered, or !important), and authors cannot append rules to an anonymous
    # layer. Everything else is an overridable default in the named
    # BASE_LAYER_NAME layer, which any unlayered or later-layered author rule
    # beats regardless of selector specificity.
    BASE_STYLES = <<~CSS.squish.freeze
      @layer {
        :host {
          display: block !important;
          min-width: 0 !important;
          max-width: 100% !important;
          contain: layout style !important;
          isolation: isolate !important;
        }
      }
      @layer #{BASE_LAYER_NAME} {
        :host {
          overflow-wrap: break-word;
          box-sizing: border-box;
        }
        :where(.billboard-shadow-body) {
          display: flow-root;
          min-width: 0;
          max-width: 100%;
          overflow-wrap: break-word;
        }
        :where(*, *::before, *::after) {
          box-sizing: border-box;
        }
        :where(img, video, canvas, iframe) {
          max-width: 100%;
        }
        :where(img[width]:not([width='']), video[width]:not([width='']), img:not([height]), video:not([height]), img[height=''], video[height='']) {
          height: auto;
        }
        :host([data-billboard-template='authorship_box']) :where(h1, h2, h3, h4, h5, h6, img, p) {
          margin-top: 0;
        }
        :host([data-billboard-template='authorship_box']) :where(p) {
          margin-bottom: var(--su-4, 1rem);
        }
        :host([data-billboard-template='authorship_box']) :where(.billboard-shadow-body > :last-child) {
          margin-bottom: 0;
        }
        :host([data-billboard-template='authorship_box']) :where(a:not(.crayons-btn):not([class*='ltag']):not(.c-cta):not(.c-btn)) {
          text-decoration: underline;
          color: var(--link-branded-color);
        }
        :host([data-billboard-template='authorship_box']) :where(a:not(.crayons-btn):not([class*='ltag']):not(.c-cta):not(.c-btn)):hover {
          color: var(--link-branded-color-hover);
        }
        :host([data-billboard-template='authorship_box']) :where(img) {
          border-radius: var(--radius);
          display: inline-block;
          vertical-align: middle;
        }
        :where(.ltag_cta, .c-cta) {
          --border-width: 1px;
          --bg: var(--cta-bg);
          --bg-hover: var(--cta-bg-hover);
          --color: var(--cta-color);
          --color-hover: var(--cta-color-hover);
          --border: var(--cta-border);
          --border-hover: var(--cta-border-hover);
          padding: var(--su-2) var(--su-4);
          border: var(--border-width) solid var(--border);
          text-decoration: none;
          border-radius: var(--radius);
          font: inherit;
          background-color: var(--bg);
          color: var(--color);
          outline: 0;
          text-align: center;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          position: relative;
          overflow-wrap: normal;
        }
        :where(.ltag_cta:hover, .c-cta:hover) {
          background-color: var(--bg-hover);
          border-color: var(--border-hover);
          color: var(--color-hover);
          text-decoration: underline;
        }
        :where(.ltag_cta--branded, .c-cta--branded) {
          --bg: var(--cta-branded-bg);
          --bg-hover: var(--cta-branded-bg-hover);
          --color: var(--cta-branded-color);
          --color-hover: var(--cta-branded-color-hover);
          --border: var(--cta-branded-border);
          --border-hover: var(--cta-branded-border-hover);
          font-weight: var(--fw-medium);
        }
        :where(.crayons-btn) {
          position: relative;
          display: inline-block;
          padding: calc(var(--su-2) - 1px) calc(var(--su-4) - 1px);
          border-radius: var(--radius);
          font-family: inherit;
          font-size: var(--fs-base);
          line-height: var(--su-6);
          font-weight: var(--fw-medium);
          text-align: center;
          text-decoration: none;
          cursor: pointer;
          border: 1px solid transparent;
          background-color: var(--button-primary-bg);
          color: var(--button-primary-color);
        }
        :where(.crayons-btn:hover) {
          background-color: var(--button-primary-bg-hover);
          color: var(--button-primary-color-hover);
        }
        :where(.crayons-btn--secondary) {
          background-color: var(--button-secondary-bg);
          color: var(--button-secondary-color);
        }
        :where(.crayons-btn--secondary:hover) {
          background-color: var(--button-secondary-bg-hover);
          color: var(--button-secondary-color-hover);
        }
        :where(.crayons-btn--ghost) {
          background-color: transparent;
          color: var(--button-ghost-color);
        }
        :where(.crayons-btn--ghost:hover) {
          background-color: var(--button-ghost-bg-hover);
          color: var(--button-ghost-color-hover);
        }
      }
    CSS

    # Tiny rolling-deploy-safe bootstrapper:
    # - On clients with the new bundle, delegates to window.Forem.mountBillboardShadowHost.
    # - On stale cached clients or legacy browsers without Declarative Shadow DOM,
    #   upgrades <template shadowrootmode="open"> into a live ShadowRoot immediately so
    #   the billboard never renders blank during a rolling deploy.
    BOOTSTRAP_SCRIPT = <<~JS.squish.freeze
      (function(s){var h=s&&s.previousElementSibling;if(!h||!h.hasAttribute('data-billboard-shadow-host'))return;if(window.Forem&&window.Forem.mountBillboardShadowHost){window.Forem.mountBillboardShadowHost(h);return;}if(!h.shadowRoot){var t=h.querySelector(':scope>template[shadowrootmode="open"]');if(t){h.attachShadow({mode:'open'}).appendChild(t.content);t.remove();}}})(document.currentScript);
    JS

    def self.call(html, billboard_id: nil, template: nil)
      new(html, billboard_id: billboard_id, template: template).call
    end

    def initialize(html, billboard_id: nil, template: nil)
      @html = html.to_s
      @billboard_id = billboard_id
      @template = template.to_s.presence || "authorship_box"
    end

    def call
      prepared_html = prepare_inner_html(@html)
      escaped_id = ERB::Util.html_escape(@billboard_id.to_s)
      escaped_template = ERB::Util.html_escape(@template)

      # rubocop:disable Rails/OutputSafety
      <<~HTML.chomp.html_safe
        <div class="billboard-shadow-host" data-billboard-shadow-host="true" data-billboard-id="#{escaped_id}" data-billboard-template="#{escaped_template}"><template shadowrootmode="open"><style data-billboard-base-styles="true">#{BASE_STYLES}</style><div class="billboard-shadow-body">#{prepared_html}</div></template></div><script data-billboard-shadow-bootstrap="true">#{BOOTSTRAP_SCRIPT}</script>
      HTML
      # rubocop:enable Rails/OutputSafety
    end

    private

    def prepare_inner_html(raw_html)
      return "" if raw_html.blank?

      fragment = Nokogiri::HTML5.fragment(raw_html)

      # Strip document-level footguns that would affect navigation or base URLs
      # if accidentally pasted from a standalone HTML document.
      fragment.css("base").remove
      fragment.css("meta[http-equiv]").each do |meta|
        meta.remove if meta["http-equiv"].to_s.strip.casecmp?("refresh")
      end

      neutralize_executable_scripts!(fragment)
      fragment.to_html
    end

    def neutralize_executable_scripts!(fragment)
      fragment.css("script").each do |script|
        original_type = script["type"].to_s.strip
        next if original_type.present? && !EXECUTABLE_SCRIPT_TYPES.match?(original_type)

        script["data-original-type"] = original_type if original_type.present?
        script["type"] = SCRIPT_MIME_TYPE
        script["data-billboard-script"] = "true"

        next if script["src"].blank?

        script["data-billboard-script-src"] = script["src"]
        script.remove_attribute("src")
      end
    end
  end
end
