class RunkitTag < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    @preamble = sanitize(markup, tags: [])
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text
    html = <<~HTML
      <div class="runkit-element" data-preamble="#{@preamble}">
        #{parsed_content}
      </div>
    HTML
    html
  end

  def self.special_script
    <<~JAVASCRIPT
      var targets = document.getElementsByClassName("runkit-element");
      for (var i = 0; i < targets.length; i++) {
        var content = targets[i].textContent;
        var preamble = targets[i].dataset.preamble;
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
            var content = targets[i].textContent;
            var preamble = targets[i].dataset.preamble;
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
