# Specify which environments to use Hypershield
# Optional to setup, can help shield sensitive data for
# tools like Blazer.
# further setup instructions: https://github.com/ankane/hypershield#database-setup

if Rails.env.production?
  Hypershield.enabled = ENV["ENABLE_HYPERSHIELD"].present?

  # Validate that hypershield schema exists before trying to use it
  begin
    if ActiveRecord::Base.connection.schema_exists?("hypershield")
      # Specify the schema to use and columns to show and hide
      Hypershield.schemas = {
        hypershield: {
          # columns to hide
          # matches table.column
          hide: [
            "ahoy_messages.content",
            "ahoy_messages.to",
            "email",
            "encrypted",
            "encrypted_password",
            "identities.auth_data_dump",
            "messages.message_html",
            "messages.message_markdown",
            "oauth_access_tokens.previous_refresh_token",
            "oauth_access_tokens.refresh_token",
            "password",
            "secret",
            "token",
            "users.current_sign_in_ip",
            "users.last_sign_in_ip",
            "users.remember_token",
            "users.reset_password_token",
            "users.unconfirmed_email",
          ]
        }
      }

      # Log SQL statements
      Hypershield.log_sql = false
    end
  rescue ActiveRecord::NoDatabaseError
    Rails.logger.error("Hypershield initializer failed to check schema due to NoDatabaseError")
  end
end
