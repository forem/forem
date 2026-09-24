module Favorites
  # Unmark an Article or Comment as favorite. This can only be done by admins.
  class Remove
    Result = Struct.new(:success?, :favoritable, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(favoritable:, admin:)
      @favoritable = favoritable
      @admin = admin
    end

    def call
      previous_favoriter_id = favoritable.favorited_by_user_id
      favoritable.update!(favorited_by_user_id: nil, favorited_at: nil)
      log_audit(previous_favoriter_id)
      Result.new(success?: true, favoritable: favoritable)
    end

    private

    attr_reader :favoritable, :admin

    def log_audit(previous_favoriter_id)
      Audit::Logger.log(:moderator, admin,
                        "action" => "unfavorite",
                        "favoritable_type" => favoritable.class.name,
                        "favoritable_id" => favoritable.id,
                        "previous_favoriter_id" => previous_favoriter_id,
                        "target_user_id" => favoritable.user_id)
    end
  end
end
