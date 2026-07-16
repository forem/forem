class SurveyMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def pulse_survey
    @user = params[:user]
    @survey = params[:survey]
    @community_name = Settings::Community.community_name(subforem_id: subforem_id)

    if @survey.industry?
      subject = "You've been randomly selected for a very quick #{@community_name} Industry Survey"
      survey_type = "industry"
    elsif @survey.fun?
      subject = "A quick, fun survey from #{@community_name}!"
      survey_type = "fun"
    else
      subject = "You've been randomly selected for a #{@community_name} Pulse Survey"
      survey_type = "pulse"
    end

    customerio_delivery_options(
      transactional_message_id: "dev_pulse_survey",
      message_data: {
        "survey_type" => survey_type,
        "survey_url" => survey_url(@survey.slug),
        "community_name" => @community_name,
        "subject" => subject
      },
    )

    mail(
      to: @user.email,
      subject: subject
    )
  end
end
