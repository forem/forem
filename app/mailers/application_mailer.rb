class ApplicationMailer < ActionMailer::Base
  layout "mailer"
  # the order of importing the helpers here is important
  # we want the application helpers to override the Rails route helpers should there be a name conflict
  # an example is the user_url
  helper Rails.application.routes.url_helpers
  helper ApplicationHelper
  helper AuthenticationHelper
  include Deliverable

  before_action :setup_subforem_context

  default(
    from: -> { email_from },
    template_path: ->(mailer) { "mailers/#{mailer.class.name.underscore}" },
    reply_to: -> { ForemInstance.reply_to_email_address },
  )

  def email_from(topic = "")
    community_name = if topic.present?
                       "#{Settings::Community.community_name(subforem_id: @subforem_id)} #{topic}"
                     else
                       Settings::Community.community_name(subforem_id: @subforem_id)
                     end

    "#{community_name} <#{ForemInstance.from_email_address}>"
  end

  def generate_unsubscribe_token(id, email_type)
    Rails.application.message_verifier(:unsubscribe).generate({
                                                                user_id: id,
                                                                email_type: email_type.to_sym,
                                                                expires_at: 31.days.from_now
                                                              })
  end

  def setup_subforem_context
    # Determine subforem from user's onboarding_subforem_id or fall back to default
    user = find_user_for_email
    @subforem_id = determine_subforem_id(user)
    @subforem_domain = determine_subforem_domain(@subforem_id)
    
    # Set the host for URL generation
    ActionMailer::Base.default_url_options[:host] = @subforem_domain
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError => e
    # Handle cases where database/tables don't exist yet (e.g., during initial setup)
    Rails.logger.warn("ApplicationMailer: Could not setup subforem context: #{e.message}")
    @subforem_id = nil
    @subforem_domain = Settings::General.app_domain rescue ApplicationConfig["APP_DOMAIN"]
    ActionMailer::Base.default_url_options[:host] = @subforem_domain if @subforem_domain.present?
  end

  # Helper to make subforem_id available in views
  helper_method :subforem_id, :subforem_domain

  def subforem_id
    @subforem_id
  end

  def subforem_domain
    @subforem_domain
  end

  private

  # Find the user associated with this email
  # Override this in subclasses if user is stored differently
  def find_user_for_email
    @user || params[:user] || @resource
  end

  def determine_subforem_id(user)
    return nil unless ActiveRecord::Base.connection.table_exists?('subforems')
    
    if user.respond_to?(:onboarding_subforem_id)
      user.onboarding_subforem_id || Subforem.cached_default_id
    else
      Subforem.cached_default_id
    end
  rescue ActiveRecord::StatementInvalid
    # Table might exist but have schema issues
    nil
  end

  def determine_subforem_domain(subforem_id)
    domain = if subforem_id
               Subforem.cached_id_to_domain_hash[subforem_id] || Subforem.cached_default_domain
             else
               Subforem.cached_default_domain
             end
    
    # Fall back to Settings::General.app_domain if no subforem domain is available
    domain ||= Settings::General.app_domain rescue nil
    
    # Ultimate fallback to ApplicationConfig if Settings table doesn't exist
    domain ||= ApplicationConfig["APP_DOMAIN"]
    
    # Add port for development
    if Rails.env.development? && domain && !domain.include?(":3000")
      domain = "#{domain}:3000"
    end
    
    domain
  rescue ActiveRecord::StatementInvalid
    # If there's a database error, fall back to ApplicationConfig
    ApplicationConfig["APP_DOMAIN"]
  end

  # Deprecated: use setup_subforem_context instead
  def use_custom_host
    setup_subforem_context
  end
end
