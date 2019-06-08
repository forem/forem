class PollTag < LiquidTagBase
  include ActionView::Helpers
  PARTIAL = "liquids/poll".freeze

  def render(_context)
    @poll = Poll.first
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        poll: @poll,
      },
    )
  end

  def self.script
    <<~JAVASCRIPT
      if (document.head.querySelector(
        'meta[name="user-signed-in"][content="true"]',
      )) {
        console.log('create poll functionality')
        // logged in
        window.fetch('/poll_votes/1')
        .then(function(response){
          response.json().then(
            function(json){
              console.log(json)
              if (json.poll_option_id) {
                console.log(json.poll_option_id)
              }
            }
          )
        })
      }
    JAVASCRIPT
  end
end

Liquid::Template.register_tag("poll", PollTag)
