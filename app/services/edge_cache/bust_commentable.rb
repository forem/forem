module EdgeCache
  class BustCommentable < Buster
    def self.call(commentable)
      return unless commentable

      EdgeCache::BustComment.call(commentable)

      buster = EdgeCache::Buster.new
      buster.bust("#{commentable.path}/comments")
      commentable.index_to_elasticsearch_inline
    end
  end
end
