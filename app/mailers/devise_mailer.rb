class DeviseMailer < Devise::Mailer
  include Rails.application.routes.url_helpers
  self.mailer_name = 'devise/mailer'

  default reply_to: proc { ForemInstance.reply_to_email_address }

  include Deliverable

  before_action :use_settings_general_values

  def use_settings_general_values
    Devise.mailer_sender =
      "#{Settings::Community.community_name} <#{ForemInstance.from_email_address}>"
    ActionMailer::Base.default_url_options[:host] = Settings::General.app_domain
  end

  # Handles passwordless magic link email
  def magic_link(record, token, remember_me = false, opts = {})
    @token = token
    @resource = record
    opts[:subject] ||= "Log in to #{Settings::Community.community_name} with a magic link"
    mail(
      to: record.email,
      subject: opts[:subject],
      from: "#{Settings::Community.community_name} <#{ForemInstance.from_email_address}>",
      reply_to: ForemInstance.reply_to_email_address,
      template_name: "magic_link"
    )
  end

  # Existing custom methods
  # rubocop:disable Style/OptionHash
  def invitation_instructions(record, token, opts = {})
    @message = opts[:custom_invite_message]
    @footnote = opts[:custom_invite_footnote]
    headers = { subject: opts[:custom_invite_subject].presence || "Invitation Instructions" }
    super(record, token, opts.merge(headers))
  end
  # rubocop:enable Style/OptionHash

  def confirmation_instructions(record, token, opts = {})
    @name = record.name
    opts[:subject] = "#{@name}, confirm your #{Settings::Community.community_name} account"
    super
  end
end
