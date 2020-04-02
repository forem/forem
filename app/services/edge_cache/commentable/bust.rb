module EdgeCache
  module Commentable
    class Bust
      def initialize(commentable, cache_buster = CacheBuster)
        @commentable = commentable
        @cache_buster = cache_buster
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        cache_buster.bust_comment(commentable)
        cache_buster.bust("#{commentable.path}/comments")
        commentable.index!
        commentable.index_to_elasticsearch_inline
      end

      private

      attr_reader :commentable, :cache_buster
    end
  end
end
