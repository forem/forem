class CustomMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  default from: -> { email_from(I18n.t("mailers.custom_mailer.from")) }

  has_history extra: lambda {
    {
      email_id: params[:email_id]
    }
  }, only: :custom_email


  def custom_email
    # Broadcasts, newsletters and the onboarding drip are authored in Customer.io
    # after cutover -- this mailer is the one with no transactional template
    # behind it, so a send that slipped past the guards in Email, the batch
    # workers and Admin::EmailsController would go out as an unmanaged body
    # passthrough. Returning before mail() yields a NullMail: nothing delivers
    # and no ahoy_messages row is written.
    return if ForemInstance.customerio_email_cutover?

    @user = params[:user]

    # That guard is global, but :customerio_email_delivery rolls out per actor:
    # while it is partially on, the enabled cohort is already receiving this
    # broadcast/newsletter/drip from the Customer.io side. Sending it from here
    # too would deliver it twice to exactly those people. Emails::BatchCustomSendWorker
    # skips them before we get here; this backstop also covers the drip worker,
    # which builds its sends itself.
    return if customerio_managed_recipient?

    @content = Email.replace_merge_tags(params[:content], @user)
    @subject = Email.replace_merge_tags(params[:subject], @user)
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_newsletter)
    add_unsubscribe_headers(@unsubscribe)
    @from_topic = params[:from_name] || Email.find_by(id: params[:email_id])&.default_from_name_based_on_type

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

  private

  # Test sends are exempt: nothing on the Customer.io side duplicates them, and
  # admins still need the preview while the flag is rolling out.
  def customerio_managed_recipient?
    return false unless ForemInstance.customerio_enabled?
    return false if params[:subject].to_s.start_with?(Email::TEST_SUBJECT_PREFIX)

    FeatureFlag.enabled_for_user?(Deliverable::CUSTOMERIO_FLAG, @user)
  end
end
