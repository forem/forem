module FieldTest
  module Controller
    extend ActiveSupport::Concern
    include Helpers

    included do
      if respond_to?(:helper_method)
        helper_method :field_test
        helper_method :field_test_converted
        helper_method :field_test_experiments
      end
    end

    def field_test_upgrade_memberships(options = {})
      participants = FieldTest::Participant.standardize(options[:participant] || field_test_participant)
      preferred = participants.first
      Array(participants[1..-1]).each do |participant|
        # can do this in single query once legacy_participants is removed
        FieldTest::Membership.where(participant.where_values).each do |membership|
          membership.participant = preferred.participant if membership.respond_to?(:participant=)
          membership.participant_type = preferred.type if membership.respond_to?(:participant_type=)
          membership.participant_id = preferred.id if membership.respond_to?(:participant_id=)
          membership.save!
        end
      end
    end

    private

    def field_test_participant
      participants = []

      if respond_to?(:current_user, true)
        user = send(:current_user)
        participants << user if user
      end

      cookie_key = "field_test"

      # name not entirely accurate
      # can still set cookies in ActionController::API through request.cookie_jar
      # however, best to prompt developer to pass participant manually
      cookies_supported = respond_to?(:cookies, true)

      if request.headers["Field-Test-Visitor"]
        token = request.headers["Field-Test-Visitor"]
      elsif FieldTest.cookies && cookies_supported
        token = cookies[cookie_key]

        if participants.empty? && !token
          token = SecureRandom.uuid
          cookies[cookie_key] = {value: token, expires: 30.days.from_now}
        end
      elsif !FieldTest.cookies
        # anonymity set
        # note: hashing does not conceal input
        token = Digest::UUID.uuid_v5(FieldTest::UUID_NAMESPACE, ["visitor", FieldTest.mask_ip(request.remote_ip), request.user_agent].join("/"))

        # delete cookie if present
        cookies.delete(cookie_key) if cookies_supported && cookies[cookie_key]
      end

      # sanitize tokens
      token = token.gsub(/[^a-z0-9\-]/i, "") if token

      if token.present?
        participants << token

        # backwards compatibility
        participants << "cookie:#{token}" if FieldTest.legacy_participants
      end

      participants
    end
  end
end
