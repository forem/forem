module EdgeCache
  class BustCommentable
    def self.call(commentable)
      return unless commentable

      EdgeCache::BustComment.call(commentable)

      cache_bust = EdgeCache::Bust.new
      cache_bust.call("#{commentable.path}/comments")
      commentable.index_to_elasticsearch_inline
    end
  end
end
