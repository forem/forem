module Comments
  module Tree
    module_function

    def for_commentable(commentable, limit: 0, order: nil, include_negative: false)
      includes = [:user]
      includes << { user: %i[setting profile organization_memberships] }

      # Only include organization for Article commentables
      if commentable.is_a?(Article)
        includes << { commentable: :organization }
      end

      collection = commentable.comments
        .includes(*includes)
        .arrange(order: build_sort_query(order))
        .to_a[0..limit - 1]
        .to_h
      collection.reject! { |comment| comment.score.negative? } unless include_negative
      collection
    end

    def for_root_comment(root_comment, include_negative: false)
      includes = [:user]
      includes << { user: %i[setting profile organization_memberships] }

      # Only include organization for Article commentables
      if root_comment.commentable.is_a?(Article)
        includes << { commentable: :organization }
      end

      sub_comments = root_comment.subtree
        .includes(*includes)
        .arrange[root_comment]
      sub_comments.reject! { |comment| comment.score.negative? } unless include_negative
      { root_comment => sub_comments }
    end

    def build_sort_query(order)
      case order
      when "latest"
        "created_at DESC"
      when "oldest"
        "created_at ASC"
      else
        "score DESC"
      end
    end

    private_class_method :build_sort_query
  end
end
