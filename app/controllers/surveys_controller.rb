class SurveysController < ApplicationController
  before_action :set_survey_by_slug, only: [:show]
  before_action :set_survey_by_id, only: [:votes]
  before_action :authenticate_user!, only: [:votes]

  rescue_from ActiveRecord::RecordNotFound do
    render file: Rails.root.join("public/404.html"), layout: false, status: :not_found
  end

  def show
    @polls = @survey.polls.includes(:poll_options).order(:position)
  end

  def votes
    # Get the latest session for this user and survey
    latest_session = @survey.get_latest_session(current_user)

    # Check if user can submit this survey
    can_submit = @survey.can_user_submit?(current_user)
    completed = @survey.completed_by_user?(current_user)

    # Generate new session number if resubmission is allowed and survey is completed
    new_session = nil
    if completed && @survey.allow_resubmission?
      new_session = @survey.generate_new_session(current_user)
    end

    # Determine which session to show votes from
    # If resubmission is allowed and survey is completed, show empty votes (fresh start)
    # Otherwise, show votes from the latest session
    session_to_show = if completed && @survey.allow_resubmission?
                        new_session # Use new session (which will have no votes yet)
                      else
                        latest_session # Use latest session (which has existing votes)
                      end

    # Find all of the current user's votes for the polls in this survey in the session to show
    # and format them into a Hash of { poll_id => poll_option_id }
    user_votes = current_user.poll_votes
      .where(poll_id: @survey.poll_ids, session_start: session_to_show)
      .pluck(:poll_id, :poll_option_id)
      .to_h

    # Find all of the current user's text responses for the polls in this survey in the session to show
    # and format them into a Hash of { poll_id => text_content }
    user_text_responses = current_user.poll_text_responses
      .where(poll_id: @survey.poll_ids, session_start: session_to_show)
      .pluck(:poll_id, :text_content)
      .to_h

    # Merge votes and text responses
    all_responses = user_votes.merge(user_text_responses)

    render json: {
      votes: all_responses,
      can_submit: can_submit,
      completed: completed,
      allow_resubmission: @survey.allow_resubmission,
      current_session: latest_session,
      new_session: new_session
    }
  end

  private

  def set_survey_by_slug
    @survey = Survey.find_by(slug: params[:slug]) ||
              Survey.find_by(old_slug: params[:slug]) ||
              Survey.find_by(old_old_slug: params[:slug])

    raise ActiveRecord::RecordNotFound unless @survey

    if @survey.slug != params[:slug]
      redirect_to survey_path(slug: @survey.slug), status: :moved_permanently and return
    end

    raise ActiveRecord::RecordNotFound unless @survey.active?
  end

  def set_survey_by_id
    @survey = Survey.find(params[:id])
  end
end
