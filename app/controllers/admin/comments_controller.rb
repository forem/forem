module Admin
  class CommentsController < Admin::ApplicationController
    SUPPORT_ADMIN_ACTIONS = %i[index show].freeze
    COMMENT_INCLUDES = %i[user commentable favorited_by_user].freeze

    layout "admin"

    def index
      @comments = if params[:state]&.start_with?("toplast-")
                    Comment
                      .includes(*COMMENT_INCLUDES)
                      .order(public_reactions_count: :desc)
                      .where("created_at > ?", params[:state].split("-").last.to_i.days.ago)
                      .page(params[:page] || 1).per(50)
                  else
                    Comment
                      .includes(*COMMENT_INCLUDES)
                      .order(created_at: :desc)
                      .page(params[:page] || 1).per(50)
                  end
      @comments = @comments.without_count
      preload_privileged_reaction_counts(@comments.map(&:id))
    end

    def show
      @comment = Comment.includes(*COMMENT_INCLUDES).find(params[:id])
      @privileged_reactions = @comment.reactions.privileged_category.includes(:user).to_a
      @countable_vomits = { @comment.id => 0 }
      @privileged_reaction_counts = { @comment.id => {} }

      @privileged_reactions.each do |reaction|
        @privileged_reaction_counts[@comment.id][reaction.category] =
          @privileged_reaction_counts[@comment.id].fetch(reaction.category, 0) + 1
        @countable_vomits[@comment.id] += 1 if reaction.category == "vomit" && reaction.status != "invalid"
      end
    end

    def unfavorite
      comment = Comment.find(params[:id])

      Favorites::Remove.call(favoritable: comment, admin: current_user)

      flash[:success] = I18n.t("admin.comments_controller.favorite_removed")
      redirect_to admin_comment_path(comment.id)
    end

    private

    # Support admins are allowed to view comments here so they can invalidate
    # flags on downvoted comments. Every other role (and every other action)
    # keeps the existing InternalPolicy check.
    def authorize_admin
      if SUPPORT_ADMIN_ACTIONS.include?(action_name.to_sym) && current_user&.support_admin?
        authorize Comment, :admin_access?, policy_class: CommentPolicy
      else
        authorize Comment, :access?, policy_class: InternalPolicy
      end
    end

    def preload_privileged_reaction_counts(comment_ids)
      @countable_vomits = Hash.new(0)
      @privileged_reaction_counts = Hash.new { |h, k| h[k] = {} }
      return if comment_ids.empty?

      Reaction.privileged_category
        .where(reactable_type: "Comment", reactable_id: comment_ids)
        .group(:reactable_id, :category, :status)
        .count
        .each do |(comment_id, category, status), count|
          @privileged_reaction_counts[comment_id][category] =
            @privileged_reaction_counts[comment_id].fetch(category, 0) + count
          @countable_vomits[comment_id] += count if category == "vomit" && status != "invalid"
        end
    end
  end
end
