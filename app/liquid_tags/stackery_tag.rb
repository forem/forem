class StackeryTag < LiquidTagBase
  PARTIAL = "liquids/stackery".freeze

  def initialize(tag_name, options, tokens)
    super
    @owner = parse_owner(options)
    @repo = parse_repo(options)
    @ref = parse_ref(options)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        owner: @owner,
        repo: @repo,
        ref: @ref
      },
    )
  end

  private

  def parse_owner(input)
    id = input.split(" ").first
    raise StandardError, "Missing owner" if id.blank?

    id
  end

  def parse_repo(input)
    repo = input.split(" ")[1]
    raise StandardError, "Missing repo" if repo.blank?

    repo
  end

  def parse_ref(input)
    ref = input.split(" ")[2] || "master"

    ref
  end
end

Liquid::Template.register_tag("stackery", StackeryTag)
