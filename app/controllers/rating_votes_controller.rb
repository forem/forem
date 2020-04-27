class RatingVotesController < ApplicationController
  after_action :verify_authorized
  after_action only: [:create] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  def create
    authorize RatingVote
    rating_vote = RatingVote.where(user_id: current_user.id, article_id: rating_vote_params[:article_id]).first || RatingVote.new
    rating_vote.user_id = current_user.id
    rating_vote.article_id = rating_vote_params[:article_id]
    rating_vote.rating = rating_vote_params[:rating].to_f
    rating_vote.group = rating_vote_params[:group]
    if rating_vote.save
      render json: { result: "Success" }
    else
      render json: { error: rating_vote.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private

  def rating_vote_params
    params.require(:rating_vote).permit(policy(RatingVote).permitted_attributes)
  end
end
