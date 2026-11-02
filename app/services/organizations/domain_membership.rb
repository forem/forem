module Organizations
  class DomainMembership
    class Error < StandardError; end

    MAX_ATTEMPTS = 5

    def initialize(user:, organization:)
      @user = user
      @organization = organization
    end

    def request_code(email)
      email = email.to_s.strip.downcase
      unless email.bytesize <= 254 && email.match?(URI::MailTo::EMAIL_REGEXP)
        raise Error, "invalid_email"
      end

      challenge = nil
      otp = SecureRandom.random_number(100_000_000).to_s.rjust(8, "0")
      @user.with_lock do
        eligible!
        domain = @organization.organization_email_domains.available.find_by(domain: email.split("@").last)
        raise Error, "ineligible_domain" unless domain

        domain.with_lock do
          raise Error, "ineligible_domain" unless domain.available?

          # Lock the account and domain to serialize sends across concurrent requests.
          recent = OrganizationMembershipChallenge.where(user: @user)
          domain_recent = domain.organization_membership_challenges
          if recent.exists?(created_at: 1.minute.ago..) ||
              recent.where(created_at: 1.hour.ago..).count >= 10 ||
              domain_recent.where(email: email, created_at: 1.hour.ago..).count >= 5 ||
              domain_recent.where(created_at: 1.hour.ago..).count >= 100
            raise Error, "rate_limited"
          end

          challenges.where(consumed_at: nil).update_all(expires_at: Time.current)
          challenge = domain.organization_membership_challenges.create!(
            user: @user, email: email, otp_digest: "pending", expires_at: 10.minutes.from_now,
          )
          challenge.update!(otp_digest: OrganizationMembershipChallenge.digest("#{challenge.id}:#{otp}"))
        end
      end
      # Deliver after commit. Do not put plaintext OTPs into a background job payload.
      deliver_code(challenge, otp)
      challenge
    end

    def verify(challenge_id, otp)
      error = nil
      membership = nil
      @user.with_lock do
        eligible!
        challenge = challenges.find_by(id: challenge_id)
        raise Error, "invalid_code" unless challenge

        domain = challenge.organization_email_domain
        domain.with_lock do
          challenge.lock!
          unless domain.available? && challenge.consumed_at.nil? && challenge.expires_at > Time.current &&
              challenge.attempts < MAX_ATTEMPTS
            raise Error, "invalid_code"
          end

          challenge.increment!(:attempts)
          if challenge.valid_otp?(otp.to_s)
            # One work mailbox cannot enroll several accounts in the same organization.
            if challenges_for_organization.where(email: challenge.email).where.not(consumed_at: nil).exists?
              error = "email_in_use"
            else
              membership = @organization.organization_memberships.find_or_initialize_by(user: @user)
              membership.type_of_user = "member" if membership.new_record? || membership.pending?
              membership.save!
              challenge.update!(consumed_at: Time.current)
            end
          else
            # Return the failure outside the transaction so the attempt count persists.
            error = "invalid_code"
          end
        end
      end
      raise Error, error if error

      membership
    end

    private

    def deliver_code(challenge, otp)
      message = OrganizationMembershipMailer.with(challenge_id: challenge.id, otp: otp).verification_email.deliver_now
      raise Error, "delivery_failed" unless message.respond_to?(:perform_deliveries) && message.perform_deliveries
    rescue StandardError => e
      challenge.update!(expires_at: Time.current)
      Rails.logger.error("Organization membership email delivery failed: #{e.class}")
      raise Error, "delivery_failed"
    end

    def eligible!
      raise Error, "unavailable" if @user.spam_or_suspended?

      membership = @organization.organization_memberships.find_by(user: @user)
      raise Error, "already_member" if membership && !membership.pending?
      # Preserve a consumed proof even after membership removal. Re-entry needs an admin invitation.
      if @organization.organization_membership_exclusions.exists?(user: @user) ||
          challenges.where.not(consumed_at: nil).exists?
        raise Error, "invite_required"
      end
    end

    def challenges
      challenges_for_organization.where(user: @user)
    end

    def challenges_for_organization
      OrganizationMembershipChallenge.joins(:organization_email_domain)
        .where(organization_email_domains: { organization_id: @organization.id })
    end
  end
end
