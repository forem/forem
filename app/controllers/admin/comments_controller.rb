module Admin
  class CommentsController < Admin::ApplicationController
    around_action :skip_bullet, if: -> { defined?(Bullet) }

    layout "admin"

    def index
      @comments = if params[:state]&.start_with?("toplast-")
                    Comment
                      .includes(:user)
                      .includes(:commentable)
                      .order(public_reactions_count: :desc)
                      .where("created_at > ?", params[:state].split("-").last.to_i.days.ago)
                      .page(params[:page] || 1).per(50)
                  else
                    Comment
                      .includes(:user)
                      .includes(:commentable)
                      .order(created_at: :desc)
                      .page(params[:page] || 1).per(50)
                  end
      @countable_vomits = {}
      @comments.each do |comment|
        @countable_vomits[comment.id] = calculate_flags_for_single_comment(comment)
      end
    end

    def show
      @comment = Comment.includes(:user, :commentable).find(params[:id])
      @countable_vomits = {}
      @countable_vomits[@comment.id] = calculate_flags_for_single_comment(@comment)
    end

    private

    def authorize_admin
      authorize Comment, :access?, policy_class: InternalPolicy
    end

    def calculate_flags_for_single_comment(comment)
      privileged_comment_reactions = comment.reactions.privileged_category.select do |reaction|
        reaction.reactable_type == "Comment"
      end
      vomit_comment_reactions = privileged_comment_reactions.select { |reaction| reaction.category == "vomit" }
      vomit_count = 0

      if vomit_comment_reactions.present?
        vomit_comment_reactions.each do |reaction|
          vomit_count += 1 if reaction.status != "invalid"
        end
      end

      vomit_count
    end

    def skip_bullet
      previous_value = Bullet.enable?
      Bullet.enable = false
      yield
    ensure
      Bullet.enable = previous_value
    end
  end
end
