class DeviseMailer < Devise::Mailer
  include Rails.application.routes.url_helpers
  self.mailer_name = 'devise/mailer'

  default reply_to: proc { ForemInstance.reply_to_email_address }

  include Deliverable

  before_action :use_settings_general_values
  before_action :setup_subforem_context

  def use_settings_general_values
    Devise.mailer_sender =
      "#{Settings::Community.community_name} <#{ForemInstance.from_email_address}>"
    ActionMailer::Base.default_url_options[:host] = Settings::General.app_domain
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
    @resource = record
    
    # Re-setup subforem context now that we have the user
    setup_subforem_context
    
    # Get the community name for this subforem
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)
    
    # Customize the sender and subject
    Devise.mailer_sender = "#{community_name} <#{ForemInstance.from_email_address}>"
    opts[:subject] = "#{@name}, confirm your #{community_name} account"
    
    super
  end

  private

  # Override find_user_for_email to work with Devise's @resource
  def find_user_for_email
    @resource || @user || (params&.[](:user))
  end

  # Determine subforem ID from user
  def determine_subforem_id(user)
    if user.respond_to?(:onboarding_subforem_id)
      user.onboarding_subforem_id || Subforem.cached_default_id
    else
      Subforem.cached_default_id
    end
  end

  # Determine subforem domain from subforem ID
  def determine_subforem_domain(subforem_id)
    domain = if subforem_id
               Subforem.cached_id_to_domain_hash[subforem_id] || Subforem.cached_default_domain
             else
               Subforem.cached_default_domain
             end
    
    # Fall back to Settings::General.app_domain if no subforem domain is available
    domain ||= Settings::General.app_domain
    
    # Add port for development
    if Rails.env.development? && domain && !domain.include?(":3000")
      domain = "#{domain}:3000"
    end
    
    domain
  end

  # Setup subforem context for the email
  def setup_subforem_context
    user = find_user_for_email
    @subforem_id = determine_subforem_id(user)
    @subforem_domain = determine_subforem_domain(@subforem_id)
    
    # Set the host for URL generation if we have a domain
    ActionMailer::Base.default_url_options[:host] = @subforem_domain if @subforem_domain.present?
  end
end
