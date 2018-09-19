class RunkitTag < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    @preamble = ActionView::Base.full_sanitizer.sanitize(markup, tags: [])
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text
    html = <<~HTML
      <div class="runkit-element">
        <code style="display: none">#{@preamble}</code>
        <code>#{parsed_content}</code>
      </div>
    HTML
    html
  end

  def self.special_script
    <<~JAVASCRIPT
      var targets = document.getElementsByClassName("runkit-element");
      for (var i = 0; i < targets.length; i++) {
        var preamble = targets[i].children[0].textContent;
        var content = targets[i].children[1].textContent;
        targets[i].innerHTML = "";
        var notebook = RunKit.createNotebook({
          element: targets[i],
          source: content,
          preamble: preamble
        });
      }
    JAVASCRIPT
  end

  def self.script
    <<~JAVASCRIPT
      var checkRunkit = setInterval(function() {
        if(typeof(RunKit) !== 'undefined') {
          var targets = document.getElementsByClassName("runkit-element");
          for (var i = 0; i < targets.length; i++) {
            var preamble = targets[i].children[0].textContent;
            var content = targets[i].children[1].textContent;
            if(/^(\<iframe src)/.test(content) === false) {
              targets[i].innerHTML = "";
              var notebook = RunKit.createNotebook({
                element: targets[i],
                source: content,
                preamble: preamble
              });
            }
          }
          clearInterval(checkRunkit);
        }
      }, 200);
    JAVASCRIPT
  end
end

Liquid::Template.register_tag("runkit", RunkitTag)
