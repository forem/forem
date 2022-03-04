module Api
  module V0
    class CommentsController < ApiController
      before_action :set_cache_control_headers, only: %i[index show]

      ATTRIBUTES_FOR_SERIALIZATION = %i[
        id processed_html user_id ancestry deleted hidden_by_commentable_user created_at
      ].freeze
      private_constant :ATTRIBUTES_FOR_SERIALIZATION

      def index
        commentable = params[:a_id] ? Article.find(params[:a_id]) : PodcastEpisode.find(params[:p_id])

        @comments = commentable.comments
          .includes(user: :profile)
          .select(ATTRIBUTES_FOR_SERIALIZATION)
          .arrange

        set_surrogate_key_header commentable.record_key, Comment.table_key, edge_cache_keys(@comments)
      end

      def show
        tree_with_root_comment = Comment.subtree_of(params[:id].to_i(26))
          .includes(user: :profile)
          .select(ATTRIBUTES_FOR_SERIALIZATION)
          .arrange

        # being only one tree we know that the root comment is the first (and only) key
        @comment = tree_with_root_comment.keys.first
        @comments = tree_with_root_comment[@comment]

        set_surrogate_key_header Comment.table_key, edge_cache_keys(tree_with_root_comment)
      end

      private

      # ancestry wraps a single or multiple trees of comments into a single hash,
      # in the case of an article comments, the hash has multiple keys (the root comments),
      # in the case of a comment and its descendants, the hash has only one key.
      # Either way, we need to use recursion to extract all the comment cache keys
      # collecting both the keys of each level of root comments and their descendants
      # NOTE: the objects are already loaded in memory by "ancestry",
      # so no additional SQL query is performed during this extraction, avoiding N+1s
      def edge_cache_keys(comments_trees)
        comments_trees.keys.flat_map do |comment|
          Array.wrap(comment.record_key) + edge_cache_keys(comments_trees[comment])
        end
      end
    end
  end
end
