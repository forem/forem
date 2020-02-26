class KatexTag < Liquid::Block
  PARTIAL = "liquids/katex".freeze

  def initialize(tag_name, markup, tokens)
    super
  end

  def render(context)
    block = Nokogiri::HTML(super).at("body").text

    parsed_content = begin
                       Katex.render(block, display_mode: true)
                     rescue ExecJS::ProgramError => e
                       e.message
                     end

    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: { parsed_content: parsed_content },
    )
  end
end

Liquid::Template.register_tag("katex", KatexTag)
