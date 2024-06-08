class CommentEmailScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = MarkdownProcessor::AllowedTags::EMAIL_COMMENT
    self.attributes = MarkdownProcessor::AllowedAttributes::EMAIL_COMMENT
  end

  def allowed_node?(node)
    tags.include?(node.name) && node.children.present?
  end

  # The default behavior of PermitScrubber removes the <script> tags
  # but keeps the contents and this is required to fix that
  def skip_node?(node)
    node.name == "script" || super
  end
end
