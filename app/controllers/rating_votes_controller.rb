class RatingVotesController < ApplicationController
  after_action :verify_authorized

  def create
    authorize RatingVote
    rating_vote = RatingVote.where(user_id: current_user.id, article_id: rating_vote_params[:article_id]).first || RatingVote.new
    rating_vote.user_id = current_user.id
    rating_vote.article_id = rating_vote_params[:article_id]
    rating_vote.rating = rating_vote_params[:rating].to_f
    rating_vote.group = rating_vote_params[:group]
    if rating_vote.save
      redirect_back(fallback_location: "/mod")
    else
      render json: { result: "Not Upserted Successfully" }
    end
  end

  private

  def rating_vote_params
    params.require(:rating_vote).permit(policy(RatingVote).permitted_attributes)
  end
end
