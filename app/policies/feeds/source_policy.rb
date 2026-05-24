module Feeds
  class SourcePolicy < ApplicationPolicy
    def create?
      !user.spam_or_suspended?
    end

    def update?
      user_owner?
    end

    def destroy?
      user_owner?
    end

    def permitted_attributes
      %i[feed_url name organization_id author_user_id mark_canonical referential_link]
    end

    private

    def user_owner?
      user.id == record.user_id
    end
  end
end
