class Webhooks::MailchimpUnsubscribesController < ApplicationController
  def create
    not_authorized unless valid_secret?
    user = User.find_by(email: params.dig(:data, :email))
    user.update(email_type => false)
  end

  private

  def valid_secret?
    params[:secret] == SiteConfig.mailchimp_webhook_secret
  end

  def email_type
    # TODO: map list id to email type
    :email_digest_periodic
  end
end
