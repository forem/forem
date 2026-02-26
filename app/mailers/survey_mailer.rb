class SurveyMailer < ApplicationMailer
  def pulse_survey
    @user = params[:user]
    @survey = params[:survey]
    @community_name = Settings::Community.community_name(subforem_id: subforem_id)

    mail(
      to: @user.email,
      subject: "You've been randomly selected for a #{@community_name} Pulse Survey"
    )
  end
end
