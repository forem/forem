module CommunityBots
  class DeleteBot
    def self.call(bot_user:, deleted_by:)
      new(bot_user: bot_user, deleted_by: deleted_by).call
    end

    def initialize(bot_user:, deleted_by:)
      @bot_user = bot_user
      @deleted_by = deleted_by
      @success = false
      @error_message = nil
    end

    def call
      unless @bot_user.community_bot?
        @error_message = "User is not a community bot"
        return self
      end

      return self unless authorized?

      # Delete the bot user and all associated data
      @bot_user.destroy!

      @success = true
      self
    rescue StandardError => e
      @error_message = "Failed to delete bot: #{e.message}"
      self
    end

    def success?
      @success
    end

    attr_reader :error_message

    private

    def authorized?
      return true if @deleted_by.any_admin?
      return true if @deleted_by.super_moderator?
      return true if @deleted_by.subforem_moderator?(subforem: Subforem.find(@bot_user.onboarding_subforem_id))

      @error_message = "Unauthorized to delete this bot"
      false
    end
  end
end
