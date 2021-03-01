class StackeryTag < LiquidTagBase
  PARTIAL = "liquids/stackery".freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @data = get_data(input.strip)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        owner: @data[:owner],
        repo: @data[:repo],
        ref: @data[:ref]
      },
    )
  end

  private

  def get_data(input)
    items = input.split
    owner = items.first
    repo = items.second
    ref = items.third || "master"

    validate_items(owner, repo)

    {
      owner: owner,
      repo: repo,
      ref: ref
    }
  end

  def validate_items(owner, repo)
    return unless owner.blank? || repo.blank?

    raise StandardError, "Stackery - Missing owner and/or repository name arguments"
  end
end

Liquid::Template.register_tag("stackery", StackeryTag)
