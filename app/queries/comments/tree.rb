module Comments
  class Tree
    def self.for_episode(episode, signed_in = false)
      collection = tree_for(episode, 12)
      collection.reject! { |comment| comment.score.negative? } unless signed_in
      collection
    end

    def self.for_article(article, count = 0, order = nil, signed_in = false)
      collection = tree_for(article, count, order)
      collection.reject! { |comment| comment.score.negative? } unless signed_in
      collection
    end

    def self.for_comments_page(commentable, signed_in)
      collection = tree_for(commentable)
      collection.reject! { |comment| comment.score.negative? } unless signed_in
      collection
    end

    def self.for_root_comment(root_comment, signed_in)
      sub_comments = root_comment.subtree.includes(user: %i[setting profile]).arrange[root_comment]
      sub_comments.reject! { |comment| comment.score.negative? } unless signed_in
      { root_comment => sub_comments }
    end

    def self.tree_for(commentable, limit = 0, order = nil)
      commentable.comments
        .includes(user: %i[setting profile])
        .arrange(order: build_sort_query(order))
        .to_a[0..limit - 1]
        .to_h
    end

    def self.build_sort_query(order)
      case order
      when "latest"
        "created_at DESC"
      when "oldest"
        "created_at ASC"
      else
        "score DESC"
      end
    end
  end
end
