class RatingVotesController < ApplicationController
  after_action :verify_authorized
  after_action only: [:create] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  def create
    authorize RatingVote
    rating_vote, saved = upsert_explicit_rating_vote
    if saved
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

  def upsert_explicit_rating_vote
    vote = RatingVote.find_or_initialize_by(
      user_id: current_user.id,
      article_id: rating_vote_params[:article_id],
      context: "explicit",
    )
    assign_rating_vote_attributes(vote)
    [vote, vote.save]
  rescue ActiveRecord::RecordNotUnique
    vote = RatingVote.find_by!(
      user_id: current_user.id,
      article_id: rating_vote_params[:article_id],
      context: "explicit",
    )
    assign_rating_vote_attributes(vote)
    [vote, vote.save]
  end

  def assign_rating_vote_attributes(rating_vote)
    rating_vote.rating = rating_vote_params[:rating].to_f
    rating_vote.group = rating_vote_params[:group]
  end

  def rating_vote_params
    params.require(:rating_vote).permit(policy(RatingVote).permitted_attributes)
  end
end
