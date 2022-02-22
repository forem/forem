class FeedMarkdownScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = MarkdownProcessor::AllowedTags::FEED
    self.attributes = MarkdownProcessor::AllowedAttributes::FEED
  end

  def allowed_node?(node)
    return true if tags.include?(node.name) && node.name != "a"

    node.name == "a" && !node["href"]&.start_with?("#")
  end
end
