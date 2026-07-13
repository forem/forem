class CustomMailer < ApplicationMailer
  default from: -> { email_from(I18n.t("mailers.custom_mailer.from")) }

  has_history extra: lambda {
    {
      email_id: params[:email_id]
    }
  }, only: :custom_email


  def custom_email
    @user = params[:user]
    email_record = params[:email_id] && Email.find_by(id: params[:email_id])
    campaign_key = params[:campaign_key].presence || (email_record&.parsed_variables || {})["campaign_key"]
    stay_url =
      if campaign_key.present?
        token = generate_retain_token(@user.id, campaign_key)
        stay_subscribed_email_subscriptions_url(rt: token, host: ActionMailer::Base.default_url_options[:host])
      end
    @content = Email.replace_merge_tags(params[:content], @user, stay_url: stay_url)
    @subject = Email.replace_merge_tags(params[:subject], @user)
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_newsletter)
    @from_topic = params[:from_name] || email_record&.default_from_name_based_on_type

    # set sendgrid category in the header using smtp api
    # https://docs.sendgrid.com/for-developers/sending-email/building-an-x-smtpapi-header
    if ForemInstance.sendgrid_enabled?
      smtpapi_header = {
        category: "#{params[:type_of] || 'Custom'} Email",
        unique_args: {
          mailing_id: "email-instance-#{params[:email_id]}"
        }
      }.to_json
    
      headers["X-SMTPAPI"] = smtpapi_header
    end

    mail(to: @user.email, subject: @subject, from: email_from(@from_topic))
  end
end
