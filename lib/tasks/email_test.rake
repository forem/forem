# frozen_string_literal: true

namespace :email do
  desc "Test SMTP configuration and connectivity"
  task test_smtp: :environment do
    puts "Testing SMTP Configuration..."
    
    if EmailConfiguration.validate_smtp_config
      puts "✅ SMTP configuration is valid"
    else
      puts "❌ SMTP configuration has errors"
      puts "Please check your environment variables:"
      puts "- SMTP_ADDRESS: #{ENV['SMTP_ADDRESS']&.present? ? '✅' : '❌'}"
      puts "- SMTP_PORT: #{ENV['SMTP_PORT']&.present? ? '✅' : '❌'}"
      puts "- SMTP_USER_NAME: #{ENV['SMTP_USER_NAME']&.present? ? '✅' : '❌'}"
      puts "- SMTP_PASSWORD: #{ENV['SMTP_PASSWORD']&.present? ? '✅' : '❌'}"
      puts "- SMTP_DOMAIN: #{ENV['SMTP_DOMAIN']&.present? ? '✅' : '❌'}"
      puts "- SMTP_AUTHENTICATION: #{ENV['SMTP_AUTHENTICATION']&.present? ? '✅' : '❌'}"
      exit 1
    end
    
    puts "\nTesting SMTP connection..."
    if EmailConfiguration.test_smtp_connection
      puts "✅ SMTP connection successful"
    else
      puts "❌ SMTP connection failed"
      puts "Please check your SMTP settings and network connectivity"
      exit 1
    end
    
    puts "\n📧 Email configuration test completed successfully!"
  end

  desc "Send test email to verify delivery"
  task send_test: :environment do
    email = ENV['TEST_EMAIL_RECIPIENT'] || ENV['DEVELOPMENT_EMAIL_RECIPIENT']
    
    unless email
      puts "Please set TEST_EMAIL_RECIPIENT or DEVELOPMENT_EMAIL_RECIPIENT environment variable"
      exit 1
    end
    
    puts "Sending test email to #{email}..."
    
    begin
      TestMailer.test_email(email).deliver_now
      puts "✅ Test email sent successfully to #{email}"
    rescue => e
      puts "❌ Failed to send test email: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Check email delivery status"
  task status: :environment do
    puts "Email Service Status"
    puts "=" * 50
    
    puts "SMTP Enabled: #{ForemInstance.smtp_enabled?}"
    puts "SMTP Address: #{Settings::SMTP.address}"
    puts "SMTP Port: #{Settings::SMTP.port}"
    puts "SMTP Domain: #{Settings::SMTP.domain}"
    puts "SMTP Authentication: #{Settings::SMTP.authentication}"
    puts "SMTP TLS: #{Settings::SMTP.enable_starttls_auto}"
    
    if defined?(SendGrid)
      puts "SendGrid API Key: #{ENV['SENDGRID_API_KEY']&.present? ? '✅' : '❌'}"
    end
    
    puts "\nActionMailer Settings:"
    puts ActionMailer::Base.smtp_settings.inspect
  end
end

class TestMailer < ApplicationMailer
  def test_email(recipient)
    mail(
      to: recipient,
      subject: "Test Email from Forem",
      body: "This is a test email to verify email delivery configuration."
    )
  end
end