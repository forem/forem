module Favorites
  # Marks an Article or Comment as a favorite. A record can only be marked a
  # favorite once.
  class Create
    Result = Struct.new(:success?, :favoritable, :error, keyword_init: true)

    ELIGIBLE_ERRORS = %i[not_a_leader already_favorited self_favorite ineligible no_allowance].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(user:, favoritable:)
      @user = user
      @favoritable = favoritable
    end

    def call
      error = precheck_error
      return failure(error) if error

      claimed = favoritable.class
        .where(id: favoritable.id, favorited_by_user_id: nil)
        .update_all(favorited_by_user_id: user.id, favorited_at: Time.current)
      return failure(:already_favorited) if claimed.zero?

      favoritable.reload
      log_audit
      Result.new(success?: true, favoritable: favoritable)
    end

    private

    attr_reader :user, :favoritable

    def precheck_error
      # Only community leader favorites are allowed for now.
      # TODO: Implement user favorites in phase 3
      return :not_a_leader unless user.community_leader?
      return :already_favorited if favoritable.favorited_by_user_id.present?
      return :self_favorite if favoritable.user_id == user.id
      return :ineligible unless eligible?
      return :no_allowance unless user.favorite_allowance.positive?

      nil
    end

    def eligible?
      case favoritable
      when Article then favoritable.published?
      when Comment then !favoritable.deleted?
      else false
      end
    end

    def log_audit
      Audit::Logger.log(:moderator, user,
                        "action" => "favorite",
                        "favoritable_type" => favoritable.class.name,
                        "favoritable_id" => favoritable.id,
                        "target_user_id" => favoritable.user_id)
    end

    def failure(error)
      Result.new(success?: false, favoritable: favoritable, error: error)
    end
  end
end
