module Spam
  class DomainDetector
    # Popular shared email domains that should be skipped from automatic blocking
    # These are legitimate services that many users might use
    POPULAR_SHARED_DOMAINS = %w[
      gmail.com
      yahoo.com
      hotmail.com
      outlook.com
      aol.com
      icloud.com
      protonmail.com
      mail.com
      yandex.com
      zoho.com
      fastmail.com
      tutanota.com
      gmx.com
      live.com
      msn.com
      yahoo.co.uk
      yahoo.ca
      yahoo.fr
      yahoo.de
      yahoo.jp
      googlemail.com
      me.com
      mac.com
      rocketmail.com
      ymail.com
      att.net
      verizon.net
      comcast.net
      sbcglobal.net
      bellsouth.net
      earthlink.net
      cox.net
      charter.net
      optonline.net
      roadrunner.com
      adelphia.net
      juno.com
      netzero.net
      excite.com
      lycos.com
      rediffmail.com
      mail.ru
      rambler.ru
      bk.ru
      inbox.ru
      list.ru
      bigmir.net
      ukr.net
      i.ua
      meta.ua
      email.ua
      ukr.net
      i.ua
      meta.ua
      email.ua
    ].freeze

    def initialize(user)
      @user = user
      @email_domain = extract_domain(user.email)
    end

    # Check if this user's email domain should be automatically blocked
    # based on spam patterns from other users with the same email address
    def check_and_block_domain!
      return false if should_skip_domain?
      return false unless spam_pattern_detected?

      Rails.logger.info("Spam domain detected: #{@email_domain} for user #{@user.id}")
      
      # Move heavy work to background
      Spam::BlockDomainAndSuspendUsersWorker.perform_async(@email_domain)
      true
    end

    private

    def should_skip_domain?
      POPULAR_SHARED_DOMAINS.include?(@email_domain)
    end

    def spam_pattern_detected?
      # Users with this email domain
      same_domain_users = User.where("email LIKE ?", "%@#{@email_domain}")

      # Requirement 1: we've never seen this domain before 2 weeks ago
      any_older_than_two_weeks = same_domain_users.where("registered_at < ?", 2.weeks.ago).exists?
      return false if any_older_than_two_weeks

      # Requirement 2: at least 3 users registered in the last 2 weeks are spam or suspended
      recent_users = same_domain_users.where("registered_at >= ?", 2.weeks.ago)
      recent_spam_or_suspended_count = recent_users
        .joins(:roles)
        .where(roles: { name: %w[spam suspended] })
        .distinct
        .count

      recent_spam_or_suspended_count >= 3
    end

    # NOTE: Heavy work moved to Spam::BlockDomainAndSuspendUsersWorker

    def extract_domain(email)
      return nil if email.blank?
      
      email.split("@").last&.downcase
    end
  end
end
