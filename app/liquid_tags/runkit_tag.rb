class RunkitTag < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    @markup = markup
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text
    html = <<~HTML
      <div class="runkit-element">
        #{parsed_content}
      </div>
    HTML
    html
  end

  def self.special_script
    <<~JAVASCRIPT
      var targets = document.getElementsByClassName("runkit-element");
      if (targets.length > 0) {
        for (var i = 0; i < targets.length; i++) {
          var content = targets[i].textContent;
          targets[i].innerHTML = "";
          var notebook = RunKit.createNotebook({
            element: targets[i],
            source: content,
          });
        }
      }
    JAVASCRIPT
  end

  def self.script
    <<~JAVASCRIPT
      var checkRunkit = setInterval(function() {
        if(typeof(RunKit) !== 'undefined') {
          var targets = document.getElementsByClassName("runkit-element");
          if (targets.length > 0) {
            for (var i = 0; i < targets.length; i++) {
              var content = targets[i].textContent;
              if(/^(\<iframe src)/.test(content) === false) {
                targets[i].innerHTML = "";
                var notebook = RunKit.createNotebook({
                  element: targets[i],
                  source: content,
                });
              }
            }
          }
          clearInterval(checkRunkit);
        }
      }, 200);
    JAVASCRIPT
  end
end

Liquid::Template.register_tag("runkit", RunkitTag)
