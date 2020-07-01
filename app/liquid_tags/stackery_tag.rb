class StackeryTag < LiquidTagBase
  PARTIAL = "liquids/stackery".freeze

  def initialize(tag_name, input, tokens)
    super
    @data = get_data(input.strip)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
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
    items = input.split(" ")
    owner = items.first
    repo = items[1]
    ref = items[2] || "master"

    validate_items(owner, repo)
    get_repo_contents(owner, repo, ref)

    {
      owner: owner,
      repo: repo,
      ref: ref
    }
  end

  def validate_items(owner, repo)
    return unless owner.blank? || repo.blank?

    raise StandardError, "Missing owner and/or repository"
  end

  def get_repo_contents(owner, repo, ref)
    url = "https://api.github.com/repos/#{owner}/#{repo}/contents/template.yaml?ref=#{ref}"
    response = HTTParty.get(url)

    return if response.code == 200

    raise StandardError, "Couldn't find remote repository. Ensure it is a public Github repository"
  end
end

Liquid::Template.register_tag("stackery", StackeryTag)
