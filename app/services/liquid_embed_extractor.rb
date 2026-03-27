class LiquidEmbedExtractor
  # @param record [ApplicationRecord] - Any record having body_markdown (Article, Comment, Page)
  def self.extract(record)
    html = record.respond_to?(:processed_html) && record.processed_html.present? ? record.processed_html : record.try(:body_html)
    return [] unless html

    html.scan(/<!-- FOREM_LTAG_START:(.*?) -->/).filter_map do |match|
      begin
        data = JSON.parse(CGI.unescapeHTML(match.first))
        {
          tag_name: data["tag"],
          url: data["url"],
          options: data["options"],
          referenced_type: data["ref_type"],
          referenced_id: data["ref_id"]
        }
      rescue JSON::ParserError
        nil
      end
    end.uniq { |t| [t[:tag_name], t[:url], t[:options]] }
  end
end
