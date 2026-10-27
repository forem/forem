module Comments
  module Tree
    module_function

    def for_commentable(commentable, limit: 0, order: nil, include_negative: false)
      includes = [:user]
      includes << { user: %i[setting profile organization_memberships roles] }

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
      includes << { user: %i[setting profile organization_memberships roles] }

      nodes = root_comment.subtree.to_a
      nodes.map! { |node| node.id == root_comment.id ? root_comment : node }

      # Only include organization for Article commentables. With root_comment in
      # nodes, the preloader reuses its loaded user and commentable across the
      # subtree instead of re-fetching those rows, and preloads nested user
      # associations onto root_comment itself.
      if root_comment.commentable.is_a?(Article)
        includes << { commentable: :organization }
      end

      ActiveRecord::Associations::Preloader.new(records: nodes, associations: includes).call

      sub_comments = Comment.arrange_nodes(nodes)[root_comment]
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
