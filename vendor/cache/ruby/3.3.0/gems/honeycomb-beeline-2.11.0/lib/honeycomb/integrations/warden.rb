# frozen_string_literal: true

module Honeycomb
  # Methods for extracting common warden/devise fields from a rack env hash
  module Warden
    COMMON_USER_FIELDS = %i[
      email
      name
      first_name
      last_name
      created_at
      id
    ].freeze

    SCOPE_PATTERN = /^warden\.user\.([^.]+)\.key$/.freeze

    def extract_user_information(env)
      warden = env["warden"]

      return unless warden

      session = env["rack.session"] || {}
      keys = session.keys.select do |key|
        key.match(SCOPE_PATTERN)
      end
      warden_scopes = keys.map do |key|
        key.gsub(SCOPE_PATTERN, "\\1")
      end
      best_scope = warden_scopes.include?("user") ? "user" : warden_scopes.first

      return unless best_scope

      env["warden"].user(scope: best_scope, run_callbacks: false).tap do |user|
        COMMON_USER_FIELDS.each do |field|
          user.respond_to?(field) && yield("user.#{field}", user.send(field))
        end
      end
    end
  end
end
