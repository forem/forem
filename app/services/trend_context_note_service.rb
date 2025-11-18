module TrendContextNoteService
  ##
  # Checks if an article applies to any current trends and creates a context note
  # if a match is found.
  #
  # @param article [Article] The article to check for trend matching
  # @return [ContextNote, nil] The created context note, or nil if no match found
  def self.check_and_create_context_note(article)
    return unless article.subforem_id.present?
    return unless Ai::Base::DEFAULT_KEY.present?

    # Skip early if article already has any context note
    return if article.context_notes.exists?

    # Skip early if there are no current trends for this subforem
    return unless Trend.current.for_subforem(article.subforem_id).exists?

    begin
      matcher = Ai::TrendMatcher.new(article)
      matching_trend = matcher.find_matching_trend

      return unless matching_trend

      # Check if a context note already exists for this article and trend
      existing_note = ContextNote.find_by(article: article, trend: matching_trend)
      return existing_note if existing_note

      # Create context note with the trend's short_title
      ContextNote.create!(
        body_markdown: matching_trend.short_title,
        article: article,
        trend: matching_trend
      )
    rescue StandardError => e
      Rails.logger.error("Failed to check trend matching for article #{article.id}: #{e}")
      nil
    end
  end
end

