class SurveysController < ApplicationController
  before_action :authenticate_user!, only: [:votes] # Ensure only signed-in users can get votes

  def votes
    survey = Survey.find(params[:id])

    # Find all of the current user's votes for the polls in this survey
    # and format them into a Hash of { poll_id => poll_option_id }
    user_votes = current_user.poll_votes
      .where(poll_id: survey.poll_ids)
      .pluck(:poll_id, :poll_option_id)
      .to_h

    # Find all of the current user's text responses for the polls in this survey
    user_text_responses = current_user.poll_text_responses
      .where(poll_id: survey.poll_ids)
      .pluck(:poll_id, :text_content)
      .to_h

    # Merge votes and text responses
    all_responses = user_votes.merge(user_text_responses)

    render json: { votes: all_responses }
  end
end
