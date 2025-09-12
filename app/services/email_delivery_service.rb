# frozen_string_literal: true

class EmailDeliveryService
  class << self
    def deliver_confirmation_email(user)
      return false unless can_send_email?
      
      begin
        user.send_confirmation_instructions
        log_success("Confirmation email sent to #{user.email}")
        true
      rescue => e
        log_error("Failed to send confirmation email to #{user.email}", e)
        false
      end
    end
    
    def resend_confirmation_email(user)
      return false unless can_send_email?
      
      begin
        user.resend_confirmation_instructions
        log_success("Confirmation email resent to #{user.email}")
        true
      rescue => e
        log_error("Failed to resend confirmation email to #{user.email}", e)
        false
      end
    end
    
    def test_email_configuration
      results = {
        smtp_configured: EmailConfiguration.validate_smtp_config,
        smtp_connection: EmailConfiguration.test_smtp_connection,
        queue_processing: check_queue_processing,
        template_rendering: check_template_rendering
      }
      
      if results.values.all?
        { status: :ok, message: "Email configuration is working correctly" }
      else
        errors = results.select { |k, v| !v }.keys
        { status: :error, message: "Email configuration issues: #{errors.join(', ')}" }
      end
    end
    
    def health_check
      {
        smtp_enabled: ForemInstance.smtp_enabled?,
        smtp_configured: EmailConfiguration.validate_smtp_config,
        smtp_connection: EmailConfiguration.test_smtp_connection,
        queue_status: Sidekiq::Queue.new('mailers').size,
        retry_queue: Sidekiq::RetrySet.new.size,
        scheduled_queue: Sidekiq::ScheduledSet.new.size
      }
    end
    
    private
    
    def can_send_email?
      return false unless ForemInstance.smtp_enabled?
      return false unless EmailConfiguration.validate_smtp_config
      
      true
    end
    
    def check_queue_processing
      # Check if Sidekiq is running and mailers queue exists
      mailers_queue = Sidekiq::Queue.new('mailers')
      mailers_queue.size >= 0 # Just check if the queue is accessible
    rescue
      false
    end
    
    def check_template_rendering
      # Test if email templates can be rendered
      begin
        UserMailer.confirmation_instructions(User.new(email: 'test@example.com'), 'token')
        true
      rescue => e
        log_error("Template rendering failed", e)
        false
      end
    end
    
    def log_success(message)
      Rails.logger.info "[EmailDeliveryService] #{message}"
    end
    
    def log_error(message, error)
      Rails.logger.error "[EmailDeliveryService] #{message}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")
    end
  end
end