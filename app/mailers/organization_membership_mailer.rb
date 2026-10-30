class OrganizationMembershipMailer < ApplicationMailer
  class << self
    private

    # Action Mailer's log subscriber reads this notification payload. Redact
    # the body and recipient without altering the actual outbound message.
    def set_payload_for_mail(payload, mail)
      super
      payload[:mail] = "[FILTERED]"
      payload[:to] = ["[FILTERED]"]
    end
  end

  def verification_email
    @challenge = OrganizationMembershipChallenge.find(params[:challenge_id])
    return if @challenge.consumed_at || @challenge.expires_at <= Time.current
    return unless @challenge.organization_email_domain.available?

    @organization = @challenge.organization_email_domain.organization
    @otp = params[:otp]
    customerio_delivery_options(tracked: false)
    mail(to: @challenge.email, subject: I18n.t("org_domain_membership.mail_subject", organization: @organization.name))
  end

  def save_ahoy_options; end

  private

  def find_user_for_email
    OrganizationMembershipChallenge.find_by(id: params[:challenge_id])&.user
  end

  # This verifies a separate mailbox. Never resolve it to the account's primary
  # address or delay the code until an MLH identity appears in Customer.io.
  def customerio_recipient
    nil
  end
end
