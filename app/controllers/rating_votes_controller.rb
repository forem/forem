class RatingVotesController < ApplicationController
  after_action :verify_authorized
  after_action only: [:create] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  # Creates or updates the signed-in moderator's explicit rating vote for an article.
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

  # Finds or initializes the explicit RatingVote for the current user and article,
  # retrying once if a concurrent request wins the insert race (via either
  # ActiveRecord uniqueness validation or the database unique index).
  def upsert_explicit_rating_vote
    attempts = 0
    begin
      vote = RatingVote.find_or_initialize_by(
        user_id: current_user.id,
        article_id: rating_vote_params[:article_id],
        context: "explicit",
      )
      was_new = vote.new_record?
      assign_rating_vote_attributes(vote)
      saved = vote.save
      if !saved && was_new && vote.errors.of_kind?(:user_id, :taken)
        raise ActiveRecord::RecordNotUnique, "uniqueness validation lost race"
      end

      [vote, saved]
    rescue ActiveRecord::RecordNotUnique
      attempts += 1
      retry if attempts < 2
      raise
    end
  end

  # Assigns the permitted rating and group attributes onto the given RatingVote.
  def assign_rating_vote_attributes(rating_vote)
    rating_vote.rating = rating_vote_params[:rating].to_f
    rating_vote.group = rating_vote_params[:group]
  end

  def rating_vote_params
    params.require(:rating_vote).permit(policy(RatingVote).permitted_attributes)
  end
end
