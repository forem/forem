module Api
  module V0
    class CommentsController < ApiController
      respond_to :json

      before_action :set_cache_control_headers, only: %i[index show]

      caches_action :index,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes

      caches_action :show,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes

      def index
        article = Article.find(params[:a_id])

        @comments_trees = article.comments.includes(:user).select(%i[id processed_html user_id ancestry]).arrange

        set_surrogate_key_header "api_comments_index", edge_cache_keys(@comments_trees)
      end

      def show
        tree_with_root_comment = Comment.subtree_of(params[:id].to_i(26)).
          includes(:user).
          select(%i[id processed_html user_id ancestry]).
          arrange

        # being only one tree we know that the root comment is the first (and only) key
        @comment = tree_with_root_comment.keys.first
        @comment_tree = tree_with_root_comment[@comment]

        set_surrogate_key_header "api_comments_show", edge_cache_keys(tree_with_root_comment)
      end

      private

      # since an article has multiple root comments, we need to use recursion
      # to extract all the comment cache keys collecting both the keys of each
      # level of root comments and their descendants
      # NOTE: the objects are already loaded in memory by "ancestry",
      # so no additional SQL query is performed, avoiding N+1s
      def edge_cache_keys(comments_trees)
        keys = comments_trees.keys.map do |comment|
          Array.wrap(comment.record_key) + edge_cache_keys(comments_trees[comment])
        end
        keys.flatten
      end
    end
  end
end
