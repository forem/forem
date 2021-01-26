module EdgeCache
  class BustCommentable < Bust
    def self.call(commentable)
      return unless commentable

      EdgeCache::BustComment.call(commentable)
      bust("#{commentable.path}/comments")
      commentable.index_to_elasticsearch_inline
    end
  end
end
