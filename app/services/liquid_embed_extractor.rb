class LiquidEmbedExtractor
  # @param record [ApplicationRecord] - Any record having body_markdown (Article, Comment, Page)
  def self.extract(record)
    return [] unless record.respond_to?(:body_markdown) && record.body_markdown.present?

    # Source options mapped precisely identical to Forem's MarkdownProcessor evaluations
    liquid_tag_options = { source: record, user: record.try(:user) }

    begin
      template = Liquid::Template.parse(record.body_markdown, liquid_tag_options)
      template.root.nodelist.filter_map do |node|
        next unless node.is_a?(LiquidTagBase)

        tag_name = node.class.name.underscore.delete_suffix("_tag")

        identifier = node.instance_variable_get(:@id) || 
                     node.instance_variable_get(:@url) || 
                     node.instance_variable_get(:@link) || 
                     node.instance_variable_get(:@input) ||
                     node.instance_variable_get(:@markup)
        
        identifier = identifier.to_s.strip

        ignore_keys = [:@parse_context, :@markup, :@source]
        referenced_record = node.instance_variables.filter_map do |ivar|
          node.instance_variable_get(ivar) unless ignore_keys.include?(ivar)
        end.find { |val| val.is_a?(ApplicationRecord) }

        {
          tag_name: tag_name,
          url: identifier.to_s,
          options: node.instance_variable_get(:@markup).to_s.strip,
          referenced_type: referenced_record&.class&.name,
          referenced_id: referenced_record&.id
        }
      end.uniq { |t| [t[:tag_name], t[:url], t[:options]] }
    rescue Liquid::SyntaxError
      []
    end
  end
end
