module Search
  module FeedContent
    class RequestedResourceType
      def initialize(feed_params:)
        @feed_params = feed_params
      end

      def sorted_articles_request?
        @sorted_articles_request ||= class_name.Article? && sorted_without_search_fields?
      end

      def class_name
        @class_name ||= feed_params[:class_name].to_s.inquiry
      end

      def empty_or_articles_not_sorted?
        @empty_or_articles_not_sorted ||= class_name.blank? || articles_without_sorting?
      end

      def invalid?
        @invalid ||= class_present_and_unknow?
      end

      private

      attr_reader :feed_params

      def unknow_class?
        SearchResources::FeedContent::Classes.all.exclude?(class_name)
      end

      def articles_without_sorting?
        class_name.Article? && !sorted_articles_request?
      end

      def sorted_without_search_fields?
        feed_params[:search_fields].blank? &&
          feed_params[:sort_by].present?
      end

      def class_present_and_unknow?
        class_name.present? && unknow_class?
      end
    end
  end
end
