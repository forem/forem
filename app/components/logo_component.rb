class LogoComponent < ViewComponent::Base
  delegate :root_path, to: :helpers

  def initialize(community_name:, svg: nil)
    @community_name = community_name
    @svg = svg
  end
end
