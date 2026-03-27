class LiquidEmbedExtractor
  # @param record [ApplicationRecord] - Any record having body_markdown (Article, Comment, Page)
  def self.extract(record)
    return [] unless record.respond_to?(:body_markdown) && record.body_markdown.present?

    # Options match the signature of Forem's internal processor
    liquid_tag_options = { source: record, user: record.try(:user) }
    parser = MarkdownProcessor::Parser.new(record.body_markdown, liquid_tag_options: liquid_tag_options)

    # Scrape out the inner markdown with escaped logic via the parser instance to ensure safety
    cleaned_parsed = parser.escape_liquid_tags_in_codeblock(record.body_markdown)
    template = begin
                 Liquid::Template.parse(cleaned_parsed, liquid_tag_options)
               rescue Liquid::SyntaxError, LiquidTags::Errors::InvalidParseContext, Pundit::NotAuthorizedError
                 return []
               end

    tags = template.root.nodelist.select { |node| node.class.superclass == LiquidTagBase }

    tags.filter_map do |tag|
      # Resolve the dynamic identifier injected by the diverse Liquid classes
      identifier = tag.instance_variable_get(:@id) ||
                   tag.instance_variable_get(:@url) ||
                   tag.instance_variable_get(:@link) ||
                   tag.instance_variable_get(:@input)

      # Extract an explicit codebase model reference if the tag queries one natively (e.g. User, Tag, PodcastEpisode)
      referenced_record = tag.instance_variables.filter_map do |ivar|
        val = tag.instance_variable_get(ivar)
        val if val.is_a?(ApplicationRecord)
      end.first

      markup_options = tag.instance_variable_get(:@markup).to_s.strip

      # Use pure markup if no semantic identifier was available 
      identifier = markup_options if identifier.blank?
      next if identifier.blank?

      tag_name = tag.class.name.underscore.delete_suffix("_tag")

      {
        tag_name: tag_name,
        url: identifier,
        referenced_type: referenced_record&.class&.name,
        referenced_id: referenced_record&.id,
        options: markup_options 
      }
    end.uniq { |t| [t[:tag_name], t[:url], t[:options]] }
  end
end
