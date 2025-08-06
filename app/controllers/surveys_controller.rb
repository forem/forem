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

    render json: { votes: user_votes }
  end
end