class KatexTag < Liquid::Block
  PARTIAL = "liquids/katex".freeze
  KATEX_EXISTED = "katex_existed".freeze

  def render(context)
    block = Nokogiri::HTML(super).at("body").text

    parsed_content =
      begin
        Katex.render(block, display_mode: !inline?)
      rescue ExecJS::ProgramError => e
        e.message
      end

    should_render_css = !context[KATEX_EXISTED]

    unless context[KATEX_EXISTED]
      context[KATEX_EXISTED] = true
    end

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        parsed_content: parsed_content,
        should_render_css: should_render_css,
        inline: inline?
      },
    )
  end

  private

  def inline?
    @inline ||= @markup.split.include?("inline")
  end
end

Liquid::Template.register_tag("katex", KatexTag)
