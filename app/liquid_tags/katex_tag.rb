# TODO
# - verify how this looks in darkmode
# - Add proper error handling
#
# Known issue
# - Does not currently support chemical type settings
# - Can't support really wide equation

class KatexTag < Liquid::Block
  PARTIAL = "liquids/katex".freeze

  def initialize(tag_name, markup, tokens)
    super
  end

  def render(context)
    block = Nokogiri::HTML(super).at("body").text

    parsed_content = Katex.render(block, display_mode: true)

    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: { parsed_content: parsed_content },
    )
  rescue ExecJS::ProgramError => e
    raise StandardError, e.full_message
  end
end

Liquid::Template.register_tag("katex", KatexTag)
