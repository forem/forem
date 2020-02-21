# This module is the source of truth for what we consider a potential spam user.
module PotentialSpamUser
  extend ActiveSupport::Concern

  # I think these should exist in constants even though they are evaluated once
  # it makes it easier to tweak these variables consistently.
  # rubocop:disable Rails/RelativeDateConstant
  AUTH_ACCOUNT_AGE = 50.hours.ago
  ACCOUNT_NAME_CHARACTER_LENGTH = 30
  ACCOUNT_AGE = 48.hours.ago
  LIMIT = 150
  # rubocop:enable Rails/RelativeDateConstant

  def potential_spam_users
    User.where("github_created_at > ? OR twitter_created_at > ? OR length(name) > ?", ACCOUNT_AGE, ACCOUNT_AGE, ACCOUNT_NAME_CHARACTER_LENGTH).
      where("created_at > ?", ACCOUNT_AGE).
      order("created_at DESC").
      where.not("username LIKE ?", "%spam_%").
      limit(LIMIT)
  end
end
