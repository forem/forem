module Search
  class FeedContent
    def initialize(feed_params:)
      @feed_params = feed_params
    end

    def class_name
      feed_params[:class_name].to_s.inquiry
    end

    def article_search?
      article? && blank_search_fields? && sorted?
    end

    private

    attr_reader :feed_params

    def article?
      class_name.Article?
    end

    def sorted?
      feed_params[:sort_by].present?
    end

    def blank_search_fields?
      feed_params[:search_fields].blank?
    end
  end
end
