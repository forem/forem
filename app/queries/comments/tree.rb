module Comments
  module Tree
    module_function

    # The tree loads every comment on the commentable, so skip the ~3KB TOASTed
    # vector that rendering never reads.
    UNRENDERED_COLUMNS = %w[semantic_embedding].freeze

    def for_commentable(commentable, limit: 0, order: nil, include_negative: false, preload: true)
      arranged = commentable.comments
        .select(Comment.column_names - UNRENDERED_COLUMNS)
        .arrange(order: build_sort_query(order))
      record_any_negative_comments(commentable, arranged)
      collection = arranged
        .to_a[0..limit - 1]
        .to_h
      collection.reject! { |comment| comment.score.negative? } unless include_negative
      preload_for_tree(collection, commentable: commentable) if preload

      collection
    end

    def preload_for_tree(collection, commentable:)
      records = Comment.flatten_arranged_nodes(collection)
      return collection if records.empty?

      includes = [{ user: %i[setting profile organization_memberships roles] }]
      commentable_user = commentable.user if commentable.respond_to?(:user) && commentable.association(:user).loaded?
      records.each do |node|
        node.association(:commentable).target = commentable
        node.association(:user).target = commentable_user if commentable_user && node.user_id == commentable.user_id
      end

      # Only include organization for Article commentables
      if commentable.is_a?(Article)
        includes << { commentable: :organization }
      end

      ActiveRecord::Associations::Preloader.new(records: records, associations: includes).call

      collection
    end

    def for_root_comment(root_comment, include_negative: false)
      includes = [{ user: %i[setting profile organization_memberships roles] }]

      nodes = [root_comment, *root_comment.descendants.select(Comment.column_names - UNRENDERED_COLUMNS).to_a]
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

    def record_any_negative_comments(commentable, arranged)
      target = commentable.respond_to?(:object) ? commentable.object : commentable
      has_negative = tree_has_negative_comment?(arranged)
      target.instance_variable_set(:@any_negative_comments, has_negative) unless target.frozen?
      return if commentable.equal?(target) || commentable.frozen?

      commentable.instance_variable_set(:@any_negative_comments, has_negative)
    end

    def tree_has_negative_comment?(tree)
      tree.any? do |comment, children|
        comment.score.to_i.negative? || (children.present? && tree_has_negative_comment?(children))
      end
    end

    private_class_method :build_sort_query, :record_any_negative_comments, :tree_has_negative_comment?
  end
end
