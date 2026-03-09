class SurveyMailer < ApplicationMailer
  def pulse_survey
    @user = params[:user]
    @survey = params[:survey]
    @community_name = Settings::Community.community_name(subforem_id: subforem_id)

    if @survey.industry?
      subject = "You've been randomly selected for a very quick #{@community_name} Industry Survey"
    elsif @survey.fun?
      subject = "A quick, fun survey from #{@community_name}!"
    else
      subject = "You've been randomly selected for a #{@community_name} Pulse Survey"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end
end
