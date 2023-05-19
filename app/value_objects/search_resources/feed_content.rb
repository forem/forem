module SearchResources
  class FeedContent
    def initialize(feed_params:)
      @feed_params = feed_params
    end

    def class_name
      feed_params[:class_name].to_s.inquiry
    end

    def article_search?
      class_name.Article? &&
        feed_params[:search_fields].blank? &&
        feed_params[:sort_by].present?
    end

    private

    attr_reader :feed_params
  end
end
