module Comments
  class Tree
    def self.for_commentable(commentable, limit: 0, order: nil, signed_in: false)
      collection = commentable.comments
        .includes(user: %i[setting profile])
        .arrange(order: build_sort_query(order))
        .to_a[0..limit - 1]
        .to_h
      collection.reject! { |comment| comment.score.negative? } unless signed_in
      collection
    end

    def self.for_root_comment(root_comment, signed_in: false)
      sub_comments = root_comment.subtree.includes(user: %i[setting profile]).arrange[root_comment]
      sub_comments.reject! { |comment| comment.score.negative? } unless signed_in
      { root_comment => sub_comments }
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
