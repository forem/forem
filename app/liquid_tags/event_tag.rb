class EventTag < LiquidTagBase
  attr_reader :event

  PARTIAL = "liquids/event".freeze

  # Matches local event URL path: e.g. /events/event-name-slug/event-variation-slug
  REGISTRY_REGEXP = %r{^(?:https?://(?:[\w.-]+\.)*[\w.-]+(?::\d+)?)?/events/(?<event_name_slug>[a-z0-9-]+)/(?<event_variation_slug>[a-z0-9-]+)(?:[/?#]|\z)}

  SCRIPT = <<~JAVASCRIPT.freeze
    (function() {
      var eventCards = document.querySelectorAll('.ltag__event');
      if (eventCards.length === 0) return;

      var userSignedIn = !!document.head.querySelector('meta[name="user-signed-in"][content="true"]');

      eventCards.forEach(function(card) {
        if (card.dataset.eventBound) return;
        card.dataset.eventBound = 'true';

        var button = card.querySelector('.ltag__event__signup-btn');
        if (!button) return;

        var nameSlug = card.dataset.eventNameSlug;
        var varSlug = card.dataset.eventVariationSlug;
        var signupUrl = button.dataset.signupUrl;

        // If signed in, fetch actual status
        if (userSignedIn) {
          fetch('/events/' + nameSlug + '/' + varSlug + '/signup_status')
            .then(function(res) { return res.json(); })
            .then(function(data) {
              updateButtonState(button, data.signed_up, data.button_text);
            })
            .catch(function(err) { console.error('Error fetching signup status:', err); });
        }

        button.addEventListener('click', function(e) {
          e.preventDefault();
          if (!userSignedIn) {
            window.location.href = '/enter?return_to=' + encodeURIComponent(window.location.pathname + window.location.search);
            return;
          }

          var isSignedUp = button.getAttribute('data-signed-up') === 'true';
          var tokenMeta = document.querySelector("meta[name='csrf-token']");
          var csrfToken = tokenMeta ? tokenMeta.getAttribute('content') : '';

          button.disabled = true;

          fetch(signupUrl + '.json', {
            method: isSignedUp ? 'DELETE' : 'POST',
            headers: {
              'X-CSRF-Token': csrfToken,
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            }
          })
          .then(function(res) { return res.json(); })
          .then(function(data) {
            updateButtonState(button, data.signed_up, data.button_text);
          })
          .catch(function(err) {
            console.error('Error during event signup:', err);
            alert('Something went wrong. Please try again.');
          })
          .finally(function() {
            button.disabled = false;
          });
        });
      });

      function updateButtonState(button, signedUp, text) {
        button.setAttribute('data-signed-up', signedUp ? 'true' : 'false');
        button.textContent = text;
        if (signedUp) {
          button.classList.remove('crayons-btn--primary');
          button.classList.add('crayons-btn--outlined');
        } else {
          button.classList.remove('crayons-btn--outlined');
          button.classList.add('crayons-btn--primary');
        }
      }
    })();
  JAVASCRIPT

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
