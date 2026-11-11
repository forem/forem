module Captcha
  class CheckEnabled
    def self.call(user = nil)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return false unless Captcha.provider.enabled?
      return true if @user.nil?

      @user.roles.load
      return false if @user.tag_moderator? || @user.trusted? || @user.any_admin?
      return true if @user.spam_or_suspended?

      @user.vomited_on? || @user.created_at.after?(1.month.ago)
    end
  end
end
