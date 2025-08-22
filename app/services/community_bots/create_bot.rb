module CommunityBots
  class CreateBot
    def self.call(subforem_id:, name:, created_by:, username: nil, profile_image: nil)
      new(subforem_id: subforem_id, name: name, created_by: created_by, username: username,
          profile_image: profile_image).call
    end

    def initialize(subforem_id:, name:, created_by:, username: nil, profile_image: nil)
      @subforem_id = subforem_id
      @name = name
      @created_by = created_by
      @username = username
      @profile_image = profile_image
      @success = false
      @error_message = nil
      @bot_user = nil
      @api_secret = nil
    end

    def call
      return self unless subforem_exists?
      return self unless authorized?

      # Generate a unique email for the bot
      bot_email = generate_bot_email

      # Create the bot user directly
      password = SecureRandom.hex(20)
      @bot_user = User.create!(
        email: bot_email,
        username: generate_bot_username,
        name: @name,
        type_of: :community_bot,
        onboarding_subforem_id: @subforem_id,
        registered: true,
        registered_at: Time.current,
        confirmed_at: Time.current,
        password: password,
        password_confirmation: password,
        invited_by: @created_by,
      )

      # Set profile image after user creation (temporarily disabled for testing)
      # set_profile_image

      # Create an API secret for the bot
      @api_secret = @bot_user.api_secrets.create!(
        description: "Community Bot API Key for #{@name}",
      )

      @success = true
      self
    rescue StandardError => e
      @error_message = "Failed to create bot: #{e.message}"
      self
    end

    def success?
      @success
    end

    attr_reader :error_message, :bot_user, :api_secret

    private

    def subforem_exists?
      return true if Subforem.exists?(@subforem_id)

      @error_message = "Subforem not found"
      false
    end

    def authorized?
      return true if @created_by.any_admin?
      return true if @created_by.super_moderator?
      return true if @created_by.subforem_moderator?(subforem: Subforem.find(@subforem_id))

      @error_message = "Unauthorized to create bots for this subforem"
      false
    end

    def generate_bot_email
      subforem = Subforem.find(@subforem_id)
      timestamp = Time.current.to_i
      "bot-#{@name.parameterize}-#{timestamp}@#{subforem.domain}"
    end

    def generate_bot_username
      if @username.present?
        # Use provided username with timestamp to ensure uniqueness
        base_username = @username.parameterize
        timestamp = Time.current.to_i
        if User.exists?(username: base_username)
          "#{base_username}_#{timestamp}"
        else
          base_username
        end
      else
        # Generate username from name
        base_username = @name.parameterize
        timestamp = Time.current.to_i
        "#{base_username}_bot_#{timestamp}"
      end
    end

    def set_profile_image
      if @profile_image.present?
        # Use the uploaded profile image
        @bot_user.profile_image = @profile_image
        @bot_user.save!
      else
        # Fall back to subforem's logo_png
        subforem_logo_url = Settings::General.logo_png(subforem_id: @subforem_id)
        if subforem_logo_url.present?
          # Download and create a file from the logo URL
          logo_file = download_logo_as_file(subforem_logo_url)
          if logo_file
            @bot_user.profile_image = logo_file
            @bot_user.save!
          else
            # Fall back to using a default image file
            set_default_profile_image
          end
        else
          # Use default profile image
          set_default_profile_image
        end
      end
    end

    def set_default_profile_image
      @bot_user.remote_profile_image_url = Settings::General.logo_png(subforem_id: @subforem_id)
      @bot_user.save!

      # If the file doesn't exist, just leave the profile image blank
    end

    def download_logo_as_file(logo_url)
      require "open-uri"
      require "tempfile"

      begin
        # Download the logo
        downloaded_image = URI.open(logo_url)

        # Create a temp file with the correct extension
        tempfile = Tempfile.new(["bot_logo", ".png"])
        tempfile.binmode
        tempfile.write(downloaded_image.read)
        tempfile.rewind

        # Create a file object that can be used by the uploader
        uploaded_file = Rack::Test::UploadedFile.new(tempfile.path, "image/png")

        # Clean up the tempfile after the upload is complete
        tempfile.close
        tempfile.unlink

        uploaded_file
      rescue StandardError => e
        Rails.logger.error("Failed to download subforem logo for bot: #{e.message}")
        # Let the User model handle profile image generation through its normal flow
        nil
      end
    end
  end
end
