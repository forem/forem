class RunkitTag < Liquid::Block
  PARTIAL = "liquids/runkit".freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    function activateRunkitTags() {
      if (!areAnyRunkitTagsPresent())
        return

      var checkRunkit = setInterval(function() {
        try {
          dynamicallyLoadRunkitLibrary()

          if (typeof(RunKit) === 'undefined') {
            return
          }

          replaceTagContentsWithRunkitWidget()
          clearInterval(checkRunkit);
        } catch(e) {
          console.error(e);
          clearInterval(checkRunkit);
        }
      }, 200);
    }

    function isRunkitTagAlreadyActive(runkitTag) {
      return runkitTag.querySelector("iframe") !== null;
    };

    function areAnyRunkitTagsPresent() {
      var presentRunkitTags = document.getElementsByClassName("runkit-element");

      return presentRunkitTags.length > 0
    }

    function replaceTagContentsWithRunkitWidget() {
      var targets = document.getElementsByClassName("runkit-element");
      for (var i = 0; i < targets.length; i++) {
        if (isRunkitTagAlreadyActive(targets[i])) {
          continue;
        }

        var wrapperContent = targets[i].textContent;
        if (/^(<iframe src)/.test(wrapperContent) === false) {
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
    };

    function dynamicallyLoadRunkitLibrary() {
      if (typeof(dynamicallyLoadScript) === "undefined")
        return

      dynamicallyLoadScript("//embed.runkit.com")
    }

    activateRunkitTags();
  JAVASCRIPT

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, markup, _parse_context)
    super
    @preamble = sanitized_preamble(markup)
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        preamble: @preamble,
        parsed_content: parsed_content
      },
    )
  end

  def sanitized_preamble(markup)
    raise StandardError, I18n.t("liquid_tags.runkit_tag.runkit_tag_is_invalid") if markup.include? "\">"

    ActionView::Base.full_sanitizer.sanitize(markup, tags: [])
  end
end

Liquid::Template.register_tag("runkit", RunkitTag)
