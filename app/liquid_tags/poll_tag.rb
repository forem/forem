class PollTag < LiquidTagBase
  include ActionView::Helpers
  PARTIAL = "liquids/poll".freeze

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        prompt_html: "hello"
      },
    )
  end

  def self.script
    <<~JAVASCRIPT
      if (document.head.querySelector(
        'meta[name="user-signed-in"][content="true"]',
      )) {
        console.log('create poll functionality')
      }
    JAVASCRIPT
  end
end

Liquid::Template.register_tag("poll", PollTag)
