class EventTag < LiquidTagBase
  attr_reader :event

  PARTIAL = "liquids/event".freeze

  # Matches local event URL path: e.g. /events/event-name-slug/event-variation-slug
  REGISTRY_REGEXP = %r{^(?:https?://(?:[\w.-]+\.)*[\w.-]+(?::\d+)?)?/events/(?<event_name_slug>[a-z0-9-]+)/(?<event_variation_slug>[a-z0-9-]+)(?:[/?#]|\z)}

  SCRIPT = "// Handled by eventSignupButtons.js pack".freeze

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, markup, parse_context)
    super
    cleaned = ActionController::Base.helpers.strip_tags(markup).strip

    if cleaned =~ /\A\d+\z/
      @event = Event.find_by(id: cleaned)
    else
      match = cleaned.match(REGISTRY_REGEXP)
      # Fallback to matching simple relative path e.g. "google-cloud-live/june-30-2026"
      if !match
        match = cleaned.match(%r{\A(?<event_name_slug>[a-z0-9-]+)/(?<event_variation_slug>[a-z0-9-]+)\z})
      end

      if match
        @event = Event.find_by(
          event_name_slug: match[:event_name_slug],
          event_variation_slug: match[:event_variation_slug]
        )
      end
    end

    raise StandardError, I18n.t("liquid_tags.event_tag.not_found", default: "Event not found") unless @event
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        event: @event
      },
    )
  end
end

Liquid::Template.register_tag("event", EventTag)
UnifiedEmbed.register(EventTag, regexp: EventTag::REGISTRY_REGEXP, skip_validation: true)
