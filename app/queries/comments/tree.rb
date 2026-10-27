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
      includes = [{ user: %i[setting profile organization_memberships roles] }]

      nodes = root_comment.subtree.to_a
      sub_comments = Comment.arrange_nodes(nodes)[root_comment]
      sub_comments.reject! { |comment| comment.score.negative? } unless include_negative
      tree = { root_comment => sub_comments }
      records = Comment.flatten_arranged_nodes(tree)

      # Only include organization for Article commentables. The root comment's
      # commentable is already loaded, so hand it to every node that shares it;
      # the preloader then reuses it instead of re-fetching the full row.
      commentable = root_comment.commentable
      if commentable.is_a?(Article)
        records.each do |node|
          next unless node.commentable_type == root_comment.commentable_type &&
            node.commentable_id == root_comment.commentable_id

          node.association(:commentable).target = commentable
        end
        includes << { commentable: :organization }
      end

      # Preload onto the arranged tree nodes (which starts with root_comment) so
      # root_comment receives the preloaded user associations and, if its user is
      # already loaded, shares that user with nodes without re-querying.
      ActiveRecord::Associations::Preloader.new(records: records, associations: includes).call

      tree
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
