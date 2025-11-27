# frozen_string_literal: true

# Email Configuration Validator and Setup Helper
module EmailConfiguration
  class << self
    def validate_smtp_config
      return false unless smtp_enabled?
      
      errors = []
      
      if Settings::SMTP.address.blank?
        errors << "SMTP_ADDRESS is not configured"
      end
      
      if Settings::SMTP.user_name.blank?
        errors << "SMTP_USER_NAME is not configured"
      end
      
      if Settings::SMTP.password.blank?
        errors << "SMTP_PASSWORD is not configured"
      end
      
      if Settings::SMTP.port.blank?
        errors << "SMTP_PORT is not configured"
      end
      
      if errors.any?
        Rails.logger.error "SMTP Configuration Errors: #{errors.join(', ')}"
        false
      else
        true
      end
    end
    
    def smtp_enabled?
      ForemInstance.smtp_enabled?
    end
    
    def test_smtp_connection
      return false unless validate_smtp_config
      
      begin
        smtp = Net::SMTP.new(Settings::SMTP.address, Settings::SMTP.port)
        smtp.enable_starttls_auto if Settings::SMTP.enable_starttls_auto
        
        smtp.start(Settings::SMTP.domain, 
                  Settings::SMTP.user_name, 
                  Settings::SMTP.password, 
                  Settings::SMTP.authentication&.to_sym)
        
        smtp.finish
        true
      rescue => e
        Rails.logger.error "SMTP Connection Test Failed: #{e.message}"
        false
      end
    end
    
    def setup_email_defaults
      # Ensure ActionMailer uses the correct settings
      ActionMailer::Base.default_url_options[:host] = Settings::General.app_domain
      
      # Set up SMTP settings
      if smtp_enabled?
        ActionMailer::Base.smtp_settings = {
          address: Settings::SMTP.address,
          port: Settings::SMTP.port,
          domain: Settings::SMTP.domain,
          user_name: Settings::SMTP.user_name,
          password: Settings::SMTP.password,
          authentication: Settings::SMTP.authentication&.to_sym,
          enable_starttls_auto: Settings::SMTP.enable_starttls_auto
        }
      end
    end
  end
end

# Initialize email configuration on boot
EmailConfiguration.setup_email_defaults