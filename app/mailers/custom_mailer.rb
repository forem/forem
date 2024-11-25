class CustomMailer < ApplicationMailer
  default from: -> { email_from(I18n.t("mailers.custom_mailer.from")) }

  def custom_email
    @user = params[:user]
    @content = Email.replace_merge_tags(params[:content], @user)
    @subject = Email.replace_merge_tags(params[:subject], @user)
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_newsletter)

    # set sendgrid category in the header using smtp api
    # https://docs.sendgrid.com/for-developers/sending-email/building-an-x-smtpapi-header
    if ForemInstance.sendgrid_enabled?
      smtpapi_header = { category: "#{params[:type_of] || "Custom"} Email" }.to_json
      headers["X-SMTPAPI"] = smtpapi_header
    end

    mail(to: @user.email, subject: @subject)
  end
end
