class RunkitTag < Liquid::Block
  PARTIAL = "liquids/runkit".freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    var checkRunkit = setInterval(function() {
      try {
        if (typeof(RunKit) !== 'undefined') {
          var targets = document.getElementsByClassName("runkit-element");
          for (var i = 0; i < targets.length; i++) {
            var wrapperContent = targets[i].textContent;
            if (/^(\<iframe src)/.test(wrapperContent) === false) {
              if (targets[i].children.length > 0) {
                var preamble = targets[i].children[0].textContent;
                var content = targets[i].children[1].textContent;
                targets[i].innerHTML = "";
                var notebook = RunKit.createNotebook({
                  element: targets[i],
                  source: content,
                  preamble: preamble
                });
              }
            }
          }
          clearInterval(checkRunkit);
        }
      } catch(e) {
        console.error(e);
        clearInterval(checkRunkit);
      }
    }, 200);
  JAVASCRIPT

  def initialize(tag_name, markup, tokens)
    super
    @preamble = sanitized_preamble(markup)
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        preamble: @preamble,
        parsed_content: parsed_content
      },
    )
  end

  def self.script
    SCRIPT
  end

  def sanitized_preamble(markup)
    raise StandardError, "Runkit tag is invalid" if markup.include? "\">"

    ActionView::Base.full_sanitizer.sanitize(markup, tags: [])
  end
end

Liquid::Template.register_tag("runkit", RunkitTag)
