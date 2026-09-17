class AgentSessionTag < LiquidTagBase
  PARTIAL = "liquids/agent_session".freeze
  ID_OR_SLUG = /[\da-z\-_]+/
  VALID_SYNTAX = /\A\s*(#{ID_OR_SLUG})\s*(?:(\d+)\.\.(\d+))?\s*\z/
  SLICE_SYNTAX = /\A\s*(#{ID_OR_SLUG})\s+([a-zA-Z][a-zA-Z0-9_ -]*)\s*\z/

  SCRIPT = <<~JAVASCRIPT.freeze
    var agentSessionEmbeds = document.querySelectorAll('.ltag-agent-session');
    agentSessionEmbeds.forEach(function(embed) {
      if (embed.dataset.bound) return;
      embed.dataset.bound = '1';

      // Tool call expand/collapse
      embed.querySelectorAll('.agent-session-tool-toggle').forEach(function(toggle) {
        toggle.addEventListener('click', function() {
          var detail = this.nextElementSibling;
          var isExpanded = this.getAttribute('aria-expanded') === 'true';
          detail.style.display = isExpanded ? 'none' : 'block';
          this.setAttribute('aria-expanded', !isExpanded);
          this.querySelector('.agent-session-chevron').textContent = isExpanded ? '\\u25B8' : '\\u25BE';
        });
      });

      // Collapsible long text
      embed.querySelectorAll('[data-collapsible]').forEach(function(wrapper) {
        var textEl = wrapper.querySelector('.agent-session-text-collapse');
        var btn = wrapper.querySelector('.agent-session-expand-btn');
        if (!textEl || !btn) return;
        if (textEl.scrollHeight <= textEl.clientHeight + 2) {
          btn.style.display = 'none';
          textEl.classList.remove('agent-session-text-collapse');
          return;
        }
        btn.addEventListener('click', function() {
          var expanded = textEl.classList.toggle('expanded');
          btn.textContent = expanded ? 'Show less' : 'Show more';
        });
      });

      // Fragment links (e.g. a transcript table of contents): resolve the
      // scoped heading id within this embed, expand collapsed text and scroll
      // the embed's own scroll container instead of jumping the whole page.
      embed.querySelectorAll('.agent-session-text a[href^="#"]').forEach(function(link) {
        if (link.dataset.anchorBound) return;
        link.dataset.anchorBound = '1';
        link.addEventListener('click', function(e) {
          var raw = decodeURIComponent(this.getAttribute('href').slice(1));
          if (!raw) return;
          var prefix = 'agent-session-' + embed.dataset.sessionId + '-';
          var scopedId = raw.lastIndexOf(prefix, 0) === 0 ? raw : prefix + raw;
          var headings = embed.querySelectorAll('h1[id],h2[id],h3[id],h4[id],h5[id],h6[id]');
          var target = null;
          for (var i = 0; i < headings.length; i++) {
            if (headings[i].id === scopedId) { target = headings[i]; break; }
          }
          if (!target) return; // unknown anchor: keep default behaviour
          e.preventDefault();
          var wrap = target.closest('[data-collapsible]');
          if (wrap) {
            var textEl = wrap.querySelector('.agent-session-text-collapse');
            var btn = wrap.querySelector('.agent-session-expand-btn');
            if (textEl && !textEl.classList.contains('expanded')) {
              textEl.classList.add('expanded');
              if (btn) btn.textContent = 'Show less';
            }
          }
          var scroller = embed.querySelector('.agent-session-scroll');
          if (scroller) {
            scroller.scrollTop += target.getBoundingClientRect().top - scroller.getBoundingClientRect().top - 8;
          } else {
            target.scrollIntoView();
          }
          target.setAttribute('tabindex', '-1');
          target.focus({ preventScroll: true });
        });
      });
    });
  JAVASCRIPT

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, markup, parse_context)
    super
    @embedding_user = parse_context.partial_options[:user]
    slice_match = markup.match(SLICE_SYNTAX)
    range_match = markup.match(VALID_SYNTAX)

    if slice_match
      @agent_session = find_session(slice_match[1])
      @slice_name = slice_match[2].strip
      @range = nil
    elsif range_match
      @agent_session = find_session(range_match[1])
      @slice_name = nil
      @range = range_match[2] && range_match[3] ? (range_match[2].to_i..range_match[3].to_i) : nil
    else
      raise StandardError,
            I18n.t("liquid_tags.agent_session_tag.invalid",
                   default: "Invalid agent_session syntax. " \
                            "Use: {% agent_session ID %}, {% agent_session ID start..end %}, " \
                            "or {% agent_session ID slice_name %}")
    end
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { agent_session: @agent_session, message_range: @range, slice_name: @slice_name },
    )
  end

  private

  def find_session(id_or_slug)
    session = if id_or_slug.match?(/\A\d+\z/)
                AgentSession.find_by(id: id_or_slug)
              else
                AgentSession.find_by(slug: id_or_slug)
              end
    unless session
      raise StandardError,
            I18n.t("liquid_tags.agent_session_tag.not_found", default: "Agent session not found")
    end
    unless session.published? || (@embedding_user && @embedding_user.id == session.user_id)
      raise StandardError,
            I18n.t("liquid_tags.agent_session_tag.unpublished",
                   default: "Only the session owner can embed this session")
    end

    session
  end
end

Liquid::Template.register_tag("agent_session", AgentSessionTag)
