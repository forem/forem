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
    });
  JAVASCRIPT

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, markup, _parse_context)
    super
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
    raise StandardError, "This agent session is not published" unless session.published?

    session
  end
end

Liquid::Template.register_tag("agent_session", AgentSessionTag)
