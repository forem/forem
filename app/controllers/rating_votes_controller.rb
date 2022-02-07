class RatingVotesController < ApplicationController
  after_action :verify_authorized
  after_action only: [:create] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  def create
    authorize RatingVote
    rating_vote = RatingVote.where(user_id: current_user.id,
                                   article_id: rating_vote_params[:article_id]).first || RatingVote.new
    rating_vote.user_id = current_user.id
    rating_vote.article_id = rating_vote_params[:article_id]
    rating_vote.rating = rating_vote_params[:rating].to_f
    rating_vote.group = rating_vote_params[:group]
    if rating_vote.save
      respond_to do |format|
        format.json { render json: { result: "Success" } }
        format.html { redirect_back(fallback_location: "/mod") }
      end
    else
      respond_to do |format|
        format.json do
          render json: { error: rating_vote.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end
        format.html { render json: { result: I18n.t("rating_votes_controller.not_upserted_successfully") } }
      end
    end
  end

  private

  def rating_vote_params
    params.require(:rating_vote).permit(policy(RatingVote).permitted_attributes)
  end
end
